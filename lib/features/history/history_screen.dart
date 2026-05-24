import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/history_provider.dart';
import '../../core/models/history_entry.dart';
import '../../core/utils/image_processor.dart';
import '../../core/utils/ad_manager.dart';
import '../premium/paywall_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'all';
  bool _isGridView = false;

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final minutes = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} \u2022 $hour:$minutes $ampm';
  }

  String _formatDimension(HistoryEntry entry) {
    if (entry.width > 0 && entry.height > 0) {
      return '${entry.width}x${entry.height}';
    }
    return '';
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'compress':
        return AppColors.compress;
      case 'resize':
        return AppColors.resize;
      case 'convert':
        return AppColors.convert;
      default:
        return AppColors.primary;
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'compress':
        return 'Compress';
      case 'resize':
        return 'Resize';
      case 'convert':
        return 'Convert';
      default:
        return mode.toUpperCase();
    }
  }

  void _shareIndividual(HistoryEntry entry) async {
    final file = File(entry.outputPath);
    if (file.existsSync()) {
      await Share.shareXFiles([XFile(entry.outputPath)]);
    } else {
      _showErrorSnackBar('Original file not found on disk.');
    }
  }

  void _saveIndividual(HistoryEntry entry) async {
    try {
      final file = File(entry.outputPath);
      if (!file.existsSync()) {
        _showErrorSnackBar('Original file not found on disk.');
        return;
      }
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(entry.outputPath, album: 'ImageResizer');
      _showSuccessSnackBar('Saved to photos gallery!');
    } catch (e) {
      _showErrorSnackBar('Save failed: $e');
    }
  }

  void _shareBatch(HistoryEntry entry) async {
    if (entry.batchItems == null) return;
    final List<XFile> files = [];
    for (var item in entry.batchItems!) {
      final path = item['outputPath'] as String?;
      if (path != null && File(path).existsSync()) {
        files.add(XFile(path));
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    } else {
      _showErrorSnackBar('No files found on disk for this batch.');
    }
  }

  void _saveBatch(HistoryEntry entry) async {
    if (entry.batchItems == null) return;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      int saved = 0;
      for (var item in entry.batchItems!) {
        final path = item['outputPath'] as String?;
        if (path != null && File(path).existsSync()) {
          await Gal.putImage(path, album: 'ImageResizer');
          saved++;
        }
      }
      if (saved > 0) {
        _showSuccessSnackBar('$saved images saved to gallery!');
      } else {
        _showErrorSnackBar('No files found on disk to save.');
      }
    } catch (e) {
      _showErrorSnackBar('Save failed: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all saved history metadata and local image copies. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(historyProvider.notifier).clearAll();
              _showSuccessSnackBar('History cleared successfully.');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildProBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFF5B041)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF6B4C0A),
              size: 24,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Unlimited History',
                  style: TextStyle(
                    color: Color(0xFF6B4C0A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const Gap(2),
                Text(
                  'Free users are limited to 3 items.',
                  style: TextStyle(
                    color: const Color(0xFF6B4C0A).withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final historyNotifier = ref.read(historyProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final filteredEntries = historyState.entries.where((entry) {
      if (_selectedFilter == 'all') return true;
      return entry.mode.toLowerCase() == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Processing History'),
        actions: [
          IconButton(
            icon: Icon(_isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
            tooltip:
                _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          if (historyState.entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear History',
              color: AppColors.error.withOpacity(0.9),
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Analytics Header Dashboard ──────────────────────────────────
            if (historyState.entries.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Space Saved',
                          value: formatBytes(historyNotifier.totalSavedBytes),
                          icon: Icons.donut_large_rounded,
                          iconColor: AppColors.compress,
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 1,
                        color: cs.outlineVariant.withOpacity(0.4),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: 'Storage Used',
                          value: formatBytes(historyNotifier.totalDiskUsage),
                          icon: Icons.storage_rounded,
                          iconColor: AppColors.resize,
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 1,
                        color: cs.outlineVariant.withOpacity(0.4),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Items',
                          value: '${historyState.entries.length}',
                          icon: Icons.photo_library_outlined,
                          iconColor: AppColors.convert,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Filter Chips ────────────────────────────────────────────────
              _FilterChipsRow(
                selectedFilter: _selectedFilter,
                onSelected: (val) {
                  setState(() {
                    _selectedFilter = val;
                  });
                },
              ),
              const Gap(10),
            ],

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: historyState.entries.isEmpty
                  ? _EmptyHistoryState()
                  : filteredEntries.isEmpty
                      ? Center(
                          child: Text(
                            'No items match your filter.',
                            style: tt.bodyMedium,
                          ),
                        )
                      : _isGridView
                          ? _buildGridView(filteredEntries, cs, tt)
                          : _buildListView(filteredEntries, cs, tt),
            ),

            // ── Pro Banner (fixed at the bottom) ───────────────────────────
            if (!AdManager.instance.isPro &&
                historyState.entries.isNotEmpty) ...[
              _buildProBanner(context),
            ],
          ],
        ),
      ),
    );
  }

  // ─── List Layout builder ────────────────────────────────────────────────────
  Widget _buildListView(
      List<HistoryEntry> entries, ColorScheme cs, TextTheme tt) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isBatch) {
          return _buildBatchCard(context, entry, cs, tt);
        }
        return _buildSingleCard(context, entry, cs, tt);
      },
    );
  }

  // ─── Grid Layout builder ────────────────────────────────────────────────────
  Widget _buildGridView(
      List<HistoryEntry> entries, ColorScheme cs, TextTheme tt) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final modeColor = _getModeColor(entry.mode);

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _HistoryEntryViewer(entry: entry),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
              color: cs.surfaceContainerHighest.withOpacity(0.15),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail image / Collage
                _buildGridThumbnail(entry, cs),

                // Mode overlay circle top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: modeColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                          )
                        ]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.isBatch) ...[
                          const Icon(Icons.style_rounded,
                              size: 9, color: Colors.black87),
                          const Gap(3),
                        ],
                        Text(
                          entry.isBatch
                              ? 'BATCH'
                              : _getModeLabel(entry.mode).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom banner overlay with clean gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.isBatch
                                    ? 'Batch (${entry.batchItems?.length} items)'
                                    : entry.outputPath.split('/').last,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(1),
                              Text(
                                entry.isBatch
                                    ? '${formatBytes(entry.newSize)} total'
                                    : '${formatBytes(entry.newSize)} \u2022 ${_formatDimension(entry)}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        if (entry.originalSize > entry.newSize &&
                            entry.savedPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${entry.savedPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridThumbnail(HistoryEntry entry, ColorScheme cs) {
    if (!entry.isBatch ||
        entry.batchItems == null ||
        entry.batchItems!.isEmpty) {
      return Image.file(
        File(entry.outputPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: cs.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined,
              size: 36, color: Colors.white30),
        ),
      );
    }

    final items = entry.batchItems!;
    if (items.length == 1) {
      final path = items[0]['outputPath'] as String;
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: cs.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined,
              size: 36, color: Colors.white30),
        ),
      );
    } else if (items.length == 2) {
      return Row(
        children: [
          Expanded(
            child: Image.file(
              File(items[0]['outputPath'] as String),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: cs.surfaceContainerHighest),
            ),
          ),
          const VerticalDivider(width: 2, thickness: 2, color: Colors.black26),
          Expanded(
            child: Image.file(
              File(items[1]['outputPath'] as String),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: cs.surfaceContainerHighest),
            ),
          ),
        ],
      );
    } else if (items.length == 3) {
      return Row(
        children: [
          Expanded(
            child: Image.file(
              File(items[0]['outputPath'] as String),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: cs.surfaceContainerHighest),
            ),
          ),
          const VerticalDivider(width: 2, thickness: 2, color: Colors.black26),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Image.file(
                    File(items[1]['outputPath'] as String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: cs.surfaceContainerHighest),
                  ),
                ),
                const Divider(height: 2, thickness: 2, color: Colors.black26),
                Expanded(
                  child: Image.file(
                    File(items[2]['outputPath'] as String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: cs.surfaceContainerHighest),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4 or more items
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Image.file(
                    File(items[0]['outputPath'] as String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: cs.surfaceContainerHighest),
                  ),
                ),
                const VerticalDivider(
                    width: 2, thickness: 2, color: Colors.black26),
                Expanded(
                  child: Image.file(
                    File(items[1]['outputPath'] as String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: cs.surfaceContainerHighest),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 2, thickness: 2, color: Colors.black26),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Image.file(
                    File(items[2]['outputPath'] as String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: cs.surfaceContainerHighest),
                  ),
                ),
                const VerticalDivider(
                    width: 2, thickness: 2, color: Colors.black26),
                Expanded(
                  child: Image.file(
                    File(items[3]['outputPath'] as String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: cs.surfaceContainerHighest),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // ─── Single Item Layout ─────────────────────────────────────────────────────
  Widget _buildSingleCard(
      BuildContext context, HistoryEntry entry, ColorScheme cs, TextTheme tt) {
    final modeColor = _getModeColor(entry.mode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (File(entry.outputPath).existsSync()) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _HistoryEntryViewer(entry: entry),
                  ),
                );
              } else {
                _showErrorSnackBar('Original file not found on disk.');
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        File(entry.outputPath),
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 76,
                          height: 76,
                          color: cs.surfaceContainerHighest,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                // Metadata details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: modeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: modeColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              _getModeLabel(entry.mode),
                              style: TextStyle(
                                color: modeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(entry.timestamp),
                            style: tt.bodySmall?.copyWith(fontSize: 10.5),
                          ),
                        ],
                      ),
                      const Gap(10),
                      // Mode-Specific Details Highlight
                      _buildModeHighlight(entry, cs, tt),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ItemActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () => _shareIndividual(entry),
              ),
              _ItemActionButton(
                icon: Icons.download_rounded,
                label: 'Save Gallery',
                onTap: () => _saveIndividual(entry),
              ),
              _ItemActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.error,
                onTap: () {
                  ref.read(historyProvider.notifier).deleteEntry(entry.id);
                  _showSuccessSnackBar('Item removed.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mode Specific Highlights ───────────────────────────────────────────────
  Widget _buildModeHighlight(HistoryEntry entry, ColorScheme cs, TextTheme tt) {
    if (entry.mode == 'compress') {
      final positiveReduction = entry.originalSize > entry.newSize;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatBytes(entry.originalSize),
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withOpacity(0.6),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const Gap(6),
              Icon(Icons.east_rounded,
                  size: 11, color: cs.onSurfaceVariant.withOpacity(0.5)),
              const Gap(6),
              Text(
                formatBytes(entry.newSize),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (positiveReduction && entry.savedPercent > 0) ...[
                const Gap(8),
                Text(
                  '-${entry.savedPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
          const Gap(4),
          Text(
            'Compression Optimization',
            style: tt.bodySmall?.copyWith(fontSize: 10.5),
          ),
        ],
      );
    } else if (entry.mode == 'resize') {
      final hasOrigDims = entry.originalWidth > 0 && entry.originalHeight > 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasOrigDims) ...[
                Text(
                  '${entry.originalWidth}x${entry.originalHeight}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant.withOpacity(0.6),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Gap(6),
                Icon(Icons.east_rounded,
                    size: 11, color: cs.onSurfaceVariant.withOpacity(0.5)),
                const Gap(6),
              ],
              Text(
                '${entry.width} x ${entry.height}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.resize,
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Output File Size: ${formatBytes(entry.newSize)}',
            style: tt.bodySmall
                ?.copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else if (entry.mode == 'convert') {
      final origFmt =
          entry.originalFormat.isNotEmpty ? entry.originalFormat : 'IMG';
      final newFmt = entry.newFormat.isNotEmpty ? entry.newFormat : 'JPG';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  origFmt,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const Gap(6),
              Icon(Icons.east_rounded,
                  size: 11, color: cs.onSurfaceVariant.withOpacity(0.5)),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.convert.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  newFmt,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.convert,
                  ),
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Output File Size: ${formatBytes(entry.newSize)}',
            style: tt.bodySmall
                ?.copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    return Text(
      'File size: ${formatBytes(entry.newSize)}',
      style: tt.bodyMedium,
    );
  }

  // ─── Grouped Batch Layout ──────────────────────────────────────────────────
  Widget _buildBatchCard(
      BuildContext context, HistoryEntry entry, ColorScheme cs, TextTheme tt) {
    if (entry.batchItems == null || entry.batchItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    final modeColor = AppColors.batch;
    final positiveReduction = entry.originalSize > entry.newSize;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: modeColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style_rounded, size: 10, color: modeColor),
                    const Gap(4),
                    Text(
                      'Batch ${_getModeLabel(entry.mode)}',
                      style: TextStyle(
                        color: modeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(entry.timestamp),
                style: tt.bodySmall?.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const Gap(12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.batchItems!.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, i) {
                final path = entry.batchItems![i]['outputPath'] as String;
                return GestureDetector(
                  onTap: () {
                    if (File(path).existsSync()) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _HistoryEntryViewer(
                              entry: entry, initialIndex: i),
                        ),
                      );
                    } else {
                      _showErrorSnackBar('File not found on disk.');
                    }
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(path),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined,
                                size: 18, color: Colors.white30),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Gap(12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _HistoryEntryViewer(entry: entry),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grouped Batch: ${entry.batchItems!.length} images',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(3),
                Row(
                  children: [
                    Text(
                      formatBytes(entry.originalSize),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant.withOpacity(0.6),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const Gap(6),
                    Icon(Icons.east_rounded,
                        size: 11, color: cs.onSurfaceVariant.withOpacity(0.5)),
                    const Gap(6),
                    Text(
                      formatBytes(entry.newSize),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (positiveReduction && entry.savedPercent > 0) ...[
                      const Gap(8),
                      Text(
                        '-${entry.savedPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ItemActionButton(
                icon: Icons.share_rounded,
                label: 'Share All',
                onTap: () => _shareBatch(entry),
              ),
              _ItemActionButton(
                icon: Icons.download_rounded,
                label: 'Save All',
                onTap: () => _saveBatch(entry),
              ),
              _ItemActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Group',
                color: AppColors.error,
                onTap: () {
                  ref.read(historyProvider.notifier).deleteEntry(entry.id);
                  _showSuccessSnackBar('Grouped batch removed.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const Gap(6),
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            letterSpacing: -0.2,
          ),
        ),
        const Gap(2),
        Text(
          title,
          style: tt.bodySmall?.copyWith(
            fontSize: 10,
            color: cs.onSurfaceVariant.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _FilterChipsRow({
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filters = ['all', 'compress', 'resize', 'convert'];
    final labels = {
      'all': 'All Items',
      'compress': 'Compress',
      'resize': 'Resize',
      'convert': 'Convert',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedFilter == f;
          Color activeColor = cs.primary;
          if (f == 'compress') activeColor = AppColors.compress;
          if (f == 'resize') activeColor = AppColors.resize;
          if (f == 'convert') activeColor = AppColors.convert;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[f]!),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              selectedColor: activeColor.withOpacity(0.12),
              checkmarkColor: activeColor,
              labelStyle: TextStyle(
                color: isSelected ? activeColor : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.5,
              ),
              side: BorderSide(
                color: isSelected
                    ? activeColor.withOpacity(0.4)
                    : cs.outlineVariant.withOpacity(0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 64,
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            const Gap(24),
            Text(
              'No History Yet',
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(8),
            Text(
              'Images you compress, resize, or convert will appear here when history saving is enabled.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Start Editing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ItemActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayColor = color ?? cs.onSurfaceVariant.withOpacity(0.85);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: displayColor, size: 18),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                color: displayColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntryViewer extends ConsumerStatefulWidget {
  final HistoryEntry entry;
  final int initialIndex;
  const _HistoryEntryViewer({required this.entry, this.initialIndex = 0});

  @override
  ConsumerState<_HistoryEntryViewer> createState() =>
      _HistoryEntryViewerState();
}

class _HistoryEntryViewerState extends ConsumerState<_HistoryEntryViewer> {
  late int _currentBatchIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentBatchIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'compress':
        return AppColors.compress;
      case 'resize':
        return AppColors.resize;
      case 'convert':
        return AppColors.convert;
      default:
        return AppColors.primary;
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'compress':
        return 'Compress';
      case 'resize':
        return 'Resize';
      case 'convert':
        return 'Convert';
      default:
        return mode.toUpperCase();
    }
  }

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final minutes = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} \u2022 $hour:$minutes $ampm';
  }

  void _shareIndividual(HistoryEntry entry) async {
    final file = File(entry.outputPath);
    if (file.existsSync()) {
      await Share.shareXFiles([XFile(entry.outputPath)]);
    } else {
      _showErrorSnackBar('Original file not found on disk.');
    }
  }

  void _saveIndividual(HistoryEntry entry) async {
    try {
      final file = File(entry.outputPath);
      if (!file.existsSync()) {
        _showErrorSnackBar('Original file not found on disk.');
        return;
      }
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(entry.outputPath, album: 'ImageResizer');
      _showSuccessSnackBar('Saved to photos gallery!');
    } catch (e) {
      _showErrorSnackBar('Save failed: $e');
    }
  }

  void _shareBatch(HistoryEntry entry) async {
    if (entry.batchItems == null) return;
    final List<XFile> files = [];
    for (var item in entry.batchItems!) {
      final path = item['outputPath'] as String?;
      if (path != null && File(path).existsSync()) {
        files.add(XFile(path));
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    } else {
      _showErrorSnackBar('No files found on disk for this batch.');
    }
  }

  void _saveBatch(HistoryEntry entry) async {
    if (entry.batchItems == null) return;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      int saved = 0;
      for (var item in entry.batchItems!) {
        final path = item['outputPath'] as String?;
        if (path != null && File(path).existsSync()) {
          await Gal.putImage(path, album: 'ImageResizer');
          saved++;
        }
      }
      if (saved > 0) {
        _showSuccessSnackBar('$saved images saved to gallery!');
      } else {
        _showErrorSnackBar('No files found on disk to save.');
      }
    } catch (e) {
      _showErrorSnackBar('Save failed: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showBatchActionOptions({
    required BuildContext context,
    required String title,
    required String activeLabel,
    required VoidCallback onActive,
    required String batchLabel,
    required VoidCallback onBatch,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading:
                    const Icon(Icons.photo_outlined, color: Colors.white70),
                title: Text(activeLabel,
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  onActive();
                },
              ),
              ListTile(
                leading: const Icon(Icons.style_rounded, color: Colors.white70),
                title: Text(batchLabel,
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  onBatch();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final historyState = ref.watch(historyProvider);
    final entry = historyState.entries.firstWhere(
      (e) => e.id == widget.entry.id,
      orElse: () => widget.entry,
    );

    final modeColor = _getModeColor(entry.mode);

    final isBatch = entry.isBatch &&
        entry.batchItems != null &&
        entry.batchItems!.isNotEmpty;
    final totalItems = isBatch ? entry.batchItems!.length : 1;

    // Clamp _currentBatchIndex to ensure it's not out of bounds
    final displayIndex = _currentBatchIndex.clamp(0, totalItems - 1);
    final currentItem = isBatch ? entry.batchItems![displayIndex] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBatch
                  ? 'Batch Preview (${displayIndex + 1} of $totalItems)'
                  : 'Image Preview',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _formatDate(entry.timestamp),
              style:
                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: modeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: modeColor.withOpacity(0.4)),
            ),
            child: Text(
              isBatch
                  ? 'BATCH ${_getModeLabel(entry.mode).toUpperCase()}'
                  : _getModeLabel(entry.mode).toUpperCase(),
              style: TextStyle(
                  color: modeColor, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background/Interactive viewer
          Positioned.fill(
            child: isBatch
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: totalItems,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBatchIndex = index;
                      });
                    },
                    itemBuilder: (context, i) {
                      final path = entry.batchItems![i]['outputPath'] as String;
                      return _buildInteractiveImage(path);
                    },
                  )
                : _buildInteractiveImage(entry.outputPath),
          ),

          // Bottom Details & Actions Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 40, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata stats overlay
                  _buildStatsOverlay(entry, currentItem, cs, tt),
                  const Gap(16),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  const Gap(16),

                  // Three action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ViewerActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: () {
                          if (isBatch) {
                            _showBatchActionOptions(
                              context: context,
                              title: 'Share Options',
                              activeLabel: 'Share current image only',
                              onActive: () {
                                final path =
                                    currentItem!['outputPath'] as String;
                                if (File(path).existsSync()) {
                                  Share.shareXFiles([XFile(path)]);
                                } else {
                                  _showErrorSnackBar('File not found on disk.');
                                }
                              },
                              batchLabel: 'Share entire batch ($totalItems)',
                              onBatch: () => _shareBatch(entry),
                            );
                          } else {
                            _shareIndividual(entry);
                          }
                        },
                      ),
                      _ViewerActionButton(
                        icon: Icons.download_rounded,
                        label: 'Save Gallery',
                        onTap: () {
                          if (isBatch) {
                            _showBatchActionOptions(
                              context: context,
                              title: 'Save Options',
                              activeLabel: 'Save current image to gallery',
                              onActive: () async {
                                try {
                                  final path =
                                      currentItem!['outputPath'] as String;
                                  if (!File(path).existsSync()) {
                                    _showErrorSnackBar(
                                        'File not found on disk.');
                                    return;
                                  }
                                  final hasAccess = await Gal.hasAccess();
                                  if (!hasAccess) {
                                    await Gal.requestAccess();
                                  }
                                  await Gal.putImage(path,
                                      album: 'ImageResizer');
                                  _showSuccessSnackBar(
                                      'Saved to photos gallery!');
                                } catch (e) {
                                  _showErrorSnackBar('Save failed: $e');
                                }
                              },
                              batchLabel: 'Save entire batch ($totalItems)',
                              onBatch: () => _saveBatch(entry),
                            );
                          } else {
                            _saveIndividual(entry);
                          }
                        },
                      ),
                      _ViewerActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        color: AppColors.error,
                        onTap: () {
                          if (isBatch) {
                            _showBatchActionOptions(
                              context: context,
                              title: 'Delete Options',
                              activeLabel: 'Remove current image from batch',
                              onActive: () {
                                final messenger = ScaffoldMessenger.of(context);
                                final itemPath =
                                    currentItem!['outputPath'] as String;
                                final isLast = entry.batchItems!.length <= 1;
                                if (isLast) {
                                  Navigator.pop(context);
                                  ref
                                      .read(historyProvider.notifier)
                                      .deleteEntry(entry.id);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text('Item removed.'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  );
                                } else {
                                  ref
                                      .read(historyProvider.notifier)
                                      .deleteBatchItem(entry.id, itemPath);
                                  setState(() {
                                    if (_currentBatchIndex >=
                                        entry.batchItems!.length - 1) {
                                      _currentBatchIndex =
                                          entry.batchItems!.length - 2;
                                    }
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Image removed from batch.'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              },
                              batchLabel: 'Delete entire batch group',
                              onBatch: () {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(context);
                                ref
                                    .read(historyProvider.notifier)
                                    .deleteEntry(entry.id);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('Grouped batch removed.'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            );
                          } else {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            ref
                                .read(historyProvider.notifier)
                                .deleteEntry(entry.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Item removed.'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveImage(String path) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 6.0,
      child: Center(
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverlay(HistoryEntry entry,
      Map<String, dynamic>? currentItem, ColorScheme cs, TextTheme tt) {
    // For single item
    if (currentItem == null) {
      if (entry.mode == 'compress') {
        final percent = entry.savedPercent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  formatBytes(entry.originalSize),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Gap(8),
                const Icon(Icons.east_rounded, size: 12, color: Colors.white54),
                const Gap(8),
                Text(
                  formatBytes(entry.newSize),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (entry.originalSize > entry.newSize && percent > 0) ...[
                  const Gap(10),
                  Text(
                    '-${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
            const Gap(4),
            const Text(
              'Compression Optimization',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        );
      } else if (entry.mode == 'resize') {
        final hasOrigDims = entry.originalWidth > 0 && entry.originalHeight > 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasOrigDims) ...[
                  Text(
                    '${entry.originalWidth}x${entry.originalHeight}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Gap(8),
                  const Icon(Icons.east_rounded,
                      size: 12, color: Colors.white54),
                  const Gap(8),
                ],
                Text(
                  '${entry.width} x ${entry.height}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.resize,
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              'Output File Size: ${formatBytes(entry.newSize)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        );
      } else if (entry.mode == 'convert') {
        final origFmt =
            entry.originalFormat.isNotEmpty ? entry.originalFormat : 'IMG';
        final newFmt = entry.newFormat.isNotEmpty ? entry.newFormat : 'JPG';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    origFmt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const Gap(8),
                const Icon(Icons.east_rounded, size: 12, color: Colors.white54),
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.convert.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    newFmt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.convert,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              'Output File Size: ${formatBytes(entry.newSize)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        );
      }
      return Text(
        'File size: ${formatBytes(entry.newSize)}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    } else {
      // For batch items
      final itemSize = currentItem['newSize'] as int? ?? 0;
      final itemWidth = currentItem['width'] as int? ?? 0;
      final itemHeight = currentItem['height'] as int? ?? 0;

      final totalReduction = entry.originalSize > entry.newSize;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Image Info',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Size: ${formatBytes(itemSize)}' +
                        (itemWidth > 0
                            ? ' \u2022 ${itemWidth}x$itemHeight px'
                            : ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Batch Total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formatBytes(entry.newSize) +
                        (totalReduction
                            ? ' (-${entry.savedPercent.toStringAsFixed(0)}%)'
                            : ''),
                    style: const TextStyle(
                      color: AppColors.batch,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
  }
}

class _ViewerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ViewerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Colors.white.withOpacity(0.9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color != null
              ? color!.withOpacity(0.1)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color != null
                ? color!.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: displayColor, size: 22),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                color: displayColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

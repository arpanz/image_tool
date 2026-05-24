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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
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
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredEntries.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            if (entry.isBatch) {
                              return _buildBatchCard(context, entry, cs, tt);
                            }
                            return _buildSingleCard(context, entry, cs, tt);
                          },
                        ),
            ),
            
            // ── Pro Banner (fixed at the bottom) ───────────────────────────
            if (!AdManager.instance.isPro && historyState.entries.isNotEmpty) ...[
              _buildProBanner(context),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Single Item Layout ─────────────────────────────────────────────────────
  Widget _buildSingleCard(
      BuildContext context, HistoryEntry entry, ColorScheme cs, TextTheme tt) {
    final modeColor = _getModeColor(entry.mode);
    final savedPercent = entry.savedPercent;

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
                    builder: (_) => _FullscreenViewer(path: entry.outputPath),
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
                              border: Border.all(
                                  color: modeColor.withOpacity(0.3)),
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
            style: tt.bodySmall?.copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else if (entry.mode == 'convert') {
      final origFmt = entry.originalFormat.isNotEmpty ? entry.originalFormat : 'IMG';
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
            style: tt.bodySmall?.copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
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
                          builder: (_) => _FullscreenViewer(path: path),
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
          Column(
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

class _FullscreenViewer extends StatelessWidget {
  final String path;
  const _FullscreenViewer({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Preview', style: TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
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
      ),
    );
  }
}

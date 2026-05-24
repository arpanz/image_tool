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
                          title: 'Total Files',
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
                            final modeColor = _getModeColor(entry.mode);
                            final savedPercent = entry.savedPercent;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: cs.outlineVariant.withOpacity(0.25)),
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (File(entry.outputPath).existsSync()) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => _FullscreenViewer(
                                              path: entry.outputPath,
                                            ),
                                          ),
                                        );
                                      } else {
                                        _showErrorSnackBar(
                                            'Original file not found on disk.');
                                      }
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image thumbnail
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Stack(
                                            children: [
                                              Image.file(
                                                File(entry.outputPath),
                                                width: 76,
                                                height: 76,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => Container(
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
                                        // Metadata
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: modeColor
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color: modeColor
                                                              .withOpacity(0.3)),
                                                    ),
                                                    child: Text(
                                                      _getModeLabel(entry.mode),
                                                      style: TextStyle(
                                                        color: modeColor,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    _formatDate(
                                                        entry.timestamp),
                                                    style: tt.bodySmall
                                                        ?.copyWith(
                                                            fontSize: 10.5),
                                                  ),
                                                ],
                                              ),
                                              const Gap(8),
                                              Row(
                                                children: [
                                                  Text(
                                                    formatBytes(
                                                        entry.originalSize),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: cs.onSurfaceVariant
                                                          .withOpacity(0.6),
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                  const Gap(6),
                                                  Icon(
                                                    Icons.east_rounded,
                                                    size: 12,
                                                    color: cs.onSurfaceVariant
                                                        .withOpacity(0.5),
                                                  ),
                                                  const Gap(6),
                                                  Text(
                                                    formatBytes(entry.newSize),
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: cs.onSurface,
                                                    ),
                                                  ),
                                                  if (savedPercent > 0 &&
                                                      entry.mode ==
                                                          'compress') ...[
                                                    const Gap(8),
                                                    Text(
                                                      '-${savedPercent.toStringAsFixed(1)}%',
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.success,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (entry.width > 0 &&
                                                  entry.height > 0) ...[
                                                const Gap(6),
                                                Text(
                                                  '${entry.width} x ${entry.height} pixels',
                                                  style: tt.bodySmall?.copyWith(
                                                    fontSize: 11,
                                                    color: cs.onSurfaceVariant
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 20),
                                  // Action Buttons
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
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
                                          ref
                                              .read(historyProvider.notifier)
                                              .deleteEntry(entry.id);
                                          _showSuccessSnackBar(
                                              'Item removed.');
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
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

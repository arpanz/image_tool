import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/app_review_service.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../../core/providers/history_provider.dart';
import '../home/home_screen.dart';
import 'batch_controller.dart';
import '../../core/widgets/premium_page_route.dart';
import '../../core/widgets/fade_in_slide.dart';

class BatchResultScreen extends ConsumerStatefulWidget {
  final ImageMode mode;
  const BatchResultScreen({super.key, required this.mode});

  @override
  ConsumerState<BatchResultScreen> createState() => _BatchResultScreenState();
}

class _BatchResultScreenState extends ConsumerState<BatchResultScreen> {
  ImageMode get mode => widget.mode;
  bool _isListView = true;

  bool _isSavedToHistory = false;

  void _saveBatchToHistory(List<BatchItem> doneItems) {
    if (_isSavedToHistory) return;

    final historyNotifier = ref.read(historyProvider.notifier);
    if (!historyNotifier.state.isEnabled) return;

    final List<Map<String, dynamic>> rawItems = [];
    for (final item in doneItems) {
      if (item.result != null) {
        rawItems.add({
          'outputPath': item.result!.outputPath,
          'originalSize': item.image.originalSize,
          'newSize': item.result!.newSize,
          'width': item.result!.outWidth,
          'height': item.result!.outHeight,
          'originalWidth': item.image.width,
          'originalHeight': item.image.height,
        });
      }
    }

    historyNotifier.addBatchEntry(
      rawItems: rawItems,
      mode: mode.name,
    );

    setState(() {
      _isSavedToHistory = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Batch saved to history!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(batchProvider);
      final hasSuccess =
          state.items.any((i) => i.status == BatchItemStatus.done);
      if (hasSuccess) {
        AppReviewService.registerSuccessfulAction();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchProvider);
    final done =
        state.items.where((i) => i.status == BatchItemStatus.done).toList();
    final failed =
        state.items.where((i) => i.status == BatchItemStatus.failed).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isCompress = mode == ImageMode.compress;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isCompress ? 'Batch Compressed!' : 'Batch Resized!'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(batchProvider.notifier).clearAll();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text('New Batch',
                style:
                    TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Hero ────────────────────────────────────────────────────
              FadeInSlide(
                delay: Duration.zero,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompress
                          ? [const Color(0xFF6C63FF), const Color(0xFF9D97FF)]
                          : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isCompress
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF11998E))
                            .withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCompress
                        ? Icons.compress_rounded
                        : Icons.photo_size_select_large_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
              const Gap(14),
              FadeInSlide(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  isCompress ? 'Batch compression done!' : 'Batch resize done!',
                  style: tt.headlineMedium,
                ),
              ),
              const Gap(4),
              FadeInSlide(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  '${done.length} of ${state.totalCount} images processed successfully.',
                  style: tt.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const Gap(20),

              // ── Per-image results grid/list ───────────────────────────────
              if (done.isNotEmpty) ...[
                FadeInSlide(
                  delay: const Duration(milliseconds: 180),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Processed Images', style: tt.labelLarge),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.list_rounded,
                                color: _isListView
                                    ? cs.primary
                                    : cs.onSurfaceVariant),
                            onPressed: () => setState(() => _isListView = true),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Gap(12),
                          IconButton(
                            icon: Icon(Icons.grid_view_rounded,
                                color: !_isListView
                                    ? cs.primary
                                    : cs.onSurfaceVariant),
                            onPressed: () => setState(() => _isListView = false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 240),
                  child: _isListView
                      ? _ResultList(items: done)
                      : _ResultGrid(items: done),
                ),
                const Gap(20),
              ],

              // ── History Group Card ─────────────────────────────────────────
              if (done.isNotEmpty && ref.watch(historyProvider).isEnabled) ...[
                FadeInSlide(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.history_rounded, color: cs.primary, size: 20),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Save Batch to History',
                                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Gap(2),
                              Text(
                                'Group these ${done.length} images in your history log',
                                style: tt.bodySmall?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _isSavedToHistory ? null : () => _saveBatchToHistory(done),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isSavedToHistory ? cs.surfaceContainerHighest : cs.primary,
                            foregroundColor: _isSavedToHistory ? cs.onSurfaceVariant : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_isSavedToHistory ? 'Saved' : 'Save'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
              ],

              // ── Ad ────────────────────────────────────────────────────────
              FadeInSlide(
                delay: const Duration(milliseconds: 360),
                child: Center(child: AdManager.instance.getBannerAdWidget()),
              ),
              const Gap(16),

              // ── Actions ──────────────────────────────────────────────────
              if (done.isNotEmpty) ...[
                FadeInSlide(
                  delay: const Duration(milliseconds: 420),
                  child: PfButton(
                    label: 'Share All (${done.length})',
                    icon: Icons.share_outlined,
                    onPressed: () => _shareAll(done),
                  ),
                ),
                const Gap(12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 480),
                  child: PfButton(
                    label: 'Save All to Device',
                    icon: Icons.download_outlined,
                    backgroundColor: isDark
                        ? AppColors.surface
                        : AppColors.lightSurfaceElevated,
                    onPressed: () => _saveAll(context, done),
                  ),
                ),
              ],
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAll(List<BatchItem> items) async {
    final files = items
        .where((i) => i.result != null)
        .map((i) => XFile(i.result!.outputPath))
        .toList();
    if (files.isNotEmpty) await Share.shareXFiles(files);
  }

  Future<void> _saveAll(BuildContext ctx, List<BatchItem> items) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      int saved = 0;
      for (final item in items) {
        if (item.result == null) continue;
        await Gal.putImage(item.result!.outputPath, album: 'ImageResizer');
        saved++;
      }
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('$saved images saved to gallery!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } on Exception catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatRow(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ResultGrid extends StatelessWidget {
  final List<BatchItem> items;
  const _ResultGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final saved = item.image.originalSize - (item.result?.newSize ?? 0);
        final pct = item.image.originalSize > 0
            ? (saved / item.image.originalSize * 100)
            : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PremiumPageRoute(
                    child: _FullscreenViewer(path: item.result!.outputPath),
                  ),
                ),
                child: Image.file(
                  File(item.result!.outputPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.white38),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatBytes(item.result!.newSize),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                      if (pct > 0)
                        Text(
                          '-${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<BatchItem> items;
  const _ResultList({required this.items});

  Future<void> _shareIndividual(BatchItem item) async {
    if (item.result != null) {
      await Share.shareXFiles([XFile(item.result!.outputPath)]);
    }
  }

  Future<void> _saveIndividual(BuildContext context, BatchItem item) async {
    if (item.result == null) return;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(item.result!.outputPath, album: 'ImageResizer');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved to gallery!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (context, i) {
        final item = items[i];
        final saved = item.image.originalSize - (item.result?.newSize ?? 0);
        final pct = item.image.originalSize > 0
            ? (saved / item.image.originalSize * 100)
            : 0.0;
        final cs = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            PremiumPageRoute(
              child: _FullscreenViewer(path: item.result!.outputPath),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail + Info ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(item.result!.outputPath),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.broken_image_outlined,
                              color: Colors.white38, size: 28),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.image.path.split(RegExp(r'[/\\]')).last,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(5),
                          Row(
                            children: [
                              Text(
                                formatBytes(item.image.originalSize),
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Icon(Icons.east_rounded,
                                    size: 11, color: cs.onSurfaceVariant),
                              ),
                              Text(
                                formatBytes(item.result!.newSize),
                                style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if (pct > 0) ...[
                            const Gap(4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4ADE80).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(1)}% smaller',
                                style: const TextStyle(
                                    color: Color(0xFF4ADE80),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                // ── Action buttons ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () => _shareIndividual(item),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download_outlined,
                        label: 'Save to Gallery',
                        onTap: () => _saveIndividual(context, item),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: filled
                ? cs.primary
                : (isDark
                    ? cs.surfaceContainerHighest.withOpacity(0.6)
                    : cs.surfaceContainerHighest.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled ? Colors.white : cs.onSurface,
              ),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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

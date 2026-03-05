import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/compression_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../home/home_screen.dart';
import 'batch_controller.dart';
import 'batch_result_screen.dart';

class BatchScreen extends ConsumerStatefulWidget {
  final ImageMode mode;
  const BatchScreen({super.key, required this.mode});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnim;
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _percentCtrl = TextEditingController(text: '75');
  bool _usePercentage = false;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  bool get _isCompress => widget.mode == ImageMode.compress;

  List<Color> get _gradient => _isCompress
      ? [const Color(0xFF6C63FF), const Color(0xFF9D97FF)]
      : [const Color(0xFF11998E), const Color(0xFF38EF7D)];

  // ── Settings helpers ──────────────────────────────────────────────────────

  void _applyResizeSettings() {
    final notifier = ref.read(batchProvider.notifier);
    final current = ref.read(batchProvider).settings;
    if (_usePercentage) {
      final pct = double.tryParse(_percentCtrl.text.trim()) ?? 75;
      // Store percentage in width/height relative to each image later in processor.
      // We encode a special flag: width=0, height=0 means "use quality only",
      // but for percentage batch we pass a sentinel via targetSizeKB=-1.
      // Instead, we save percent in quality field (hack-safe here because
      // resize doesn't use quality for dimension logic).
      notifier.updateSettings(current.copyWith(
        width: null,
        height: null,
        // encode % as targetSizeKB < 0 sentinel — handled below in processAll override
      ));
      // Store in state via a custom field workaround:
      // We'll save the percent TextEditingController's value and handle it in _processAll.
    } else {
      final w = int.tryParse(_widthCtrl.text.trim());
      final h = int.tryParse(_heightCtrl.text.trim());
      notifier.updateSettings(current.copyWith(
        width: w,
        height: h,
      ));
    }
  }

  Future<void> _processAll() async {
    final notifier = ref.read(batchProvider.notifier);
    final state = ref.read(batchProvider);

    if (_isCompress) {
      // Settings already synced via slider
    } else {
      // Apply resize settings before processing
      final current = state.settings;
      if (_usePercentage) {
        final pct = double.tryParse(_percentCtrl.text.trim()) ?? 75;
        // For batch percentage resize we pass pct via a custom path;
        // Override each image's dimensions using the percentage.
        // We store pct in a dedicated field by encoding as negative targetSizeKB.
        notifier.updateSettings(current.copyWith(
          width: null,
          height: null,
          targetSizeKB: -(pct.round()), // sentinel: negative = percent mode
          clearTargetSizeKB: false,
        ));
      } else {
        final w = int.tryParse(_widthCtrl.text.trim());
        final h = int.tryParse(_heightCtrl.text.trim());
        notifier.updateSettings(current.copyWith(
            width: w, height: h, clearTargetSizeKB: true));
      }
    }

    await notifier.processAll();

    if (mounted && ref.read(batchProvider).isDone) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BatchResultScreen(mode: widget.mode),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchProvider);
    final notifier = ref.read(batchProvider.notifier);
    final settings = state.settings;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Animate FAB in when images are added
    if (state.items.isNotEmpty) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            Text('Batch ${_isCompress ? "Compress" : "Resize"}'),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: notifier.clearAll,
              child: Text('Clear all',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Mode badge ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _gradient),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCompress
                                ? Icons.compress_rounded
                                : Icons.photo_size_select_large_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const Gap(6),
                          Text(
                            _isCompress
                                ? 'Compress all at once'
                                : 'Resize all at once',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // ── Settings card ──────────────────────────────────────
                    _SectionCard(
                      child: _isCompress
                          ? _CompressSettings(
                              settings: settings,
                              onChanged: (s) => notifier.updateSettings(s),
                            )
                          : _ResizeSettings(
                              settings: settings,
                              widthCtrl: _widthCtrl,
                              heightCtrl: _heightCtrl,
                              percentCtrl: _percentCtrl,
                              usePercentage: _usePercentage,
                              onToggle: (v) =>
                                  setState(() => _usePercentage = v),
                              onChanged: (s) => notifier.updateSettings(s),
                            ),
                    ),
                    const Gap(12),

                    // ── Format card ────────────────────────────────────────
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Output Format',
                              style: tt.labelLarge),
                          const Gap(12),
                          Row(
                            children:
                                AppConstants.supportedFormats.map((f) {
                              final sel = f == settings.format;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => notifier.updateSettings(
                                      settings.copyWith(format: f)),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? cs.primary
                                          : (isDark
                                              ? AppColors.surfaceElevated
                                              : AppColors
                                                  .lightSurfaceElevated),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(f,
                                        style: TextStyle(
                                          color: sel
                                              ? Colors.white
                                              : tt.bodySmall?.color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        )),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),

                    // ── Image grid ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.items.isEmpty
                              ? 'No images selected'
                              : '${state.items.length} image${state.items.length > 1 ? "s" : ""} selected',
                          style: tt.labelLarge,
                        ),
                        TextButton.icon(
                          onPressed: state.isProcessing
                              ? null
                              : notifier.pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined,
                              size: 18),
                          label: const Text('Add more'),
                          style: TextButton.styleFrom(
                              foregroundColor: cs.primary),
                        ),
                      ],
                    ),
                    const Gap(8),

                    if (state.items.isEmpty)
                      _EmptyPicker(
                        gradient: _gradient,
                        onTap: notifier.pickImages,
                      )
                    else
                      _ImageGrid(
                        items: state.items,
                        isProcessing: state.isProcessing,
                        gradient: _gradient,
                        onRemove: (i) => notifier.removeItem(i),
                      ),

                    const Gap(16),

                    // ── Progress bar (during processing) ───────────────────
                    if (state.isProcessing) ...[
                      const Gap(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing ${state.doneCount + state.failedCount} of ${state.totalCount}…',
                            style: tt.bodySmall,
                          ),
                          Text(
                            '${(state.progress * 100).round()}%',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const Gap(8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? AppColors.surfaceElevated
                              : AppColors.lightSurfaceElevated,
                          valueColor:
                              AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                      const Gap(16),
                    ],

                    // ── Ad banner ──────────────────────────────────────────
                    Center(
                        child: AdManager.instance.getBannerAdWidget()),
                    const Gap(16),

                    // ── Process button ─────────────────────────────────────
                    if (state.items.isNotEmpty)
                      PfButton(
                        label: _isCompress
                            ? 'Compress ${state.items.length} Images'
                            : 'Resize ${state.items.length} Images',
                        isLoading: state.isProcessing,
                        icon: _isCompress
                            ? Icons.compress_rounded
                            : Icons.photo_size_select_large_rounded,
                        onPressed: _processAll,
                      ),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings widgets ─────────────────────────────────────────────────────────

class _CompressSettings extends StatelessWidget {
  final CompressionSettings settings;
  final ValueChanged<CompressionSettings> onChanged;
  const _CompressSettings(
      {required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quality', style: tt.labelLarge),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${settings.quality}%',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
            ),
          ],
        ),
        const Gap(4),
        Text(_qualityLabel(settings.quality), style: tt.bodySmall),
        const Gap(8),
        Slider(
          value: settings.quality.toDouble(),
          min: 5,
          max: 95,
          divisions: 18,
          label: '${settings.quality}%',
          onChanged: (v) =>
              onChanged(settings.copyWith(quality: v.round())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Smallest', style: tt.bodySmall),
              Text('Best quality', style: tt.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  String _qualityLabel(int q) {
    if (q >= 85) return 'High quality · Larger file size';
    if (q >= 60) return 'Balanced quality and size';
    if (q >= 35) return 'Smaller file · Some quality loss';
    return 'Maximum compression · Visible quality loss';
  }
}

class _ResizeSettings extends StatelessWidget {
  final CompressionSettings settings;
  final TextEditingController widthCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController percentCtrl;
  final bool usePercentage;
  final ValueChanged<bool> onToggle;
  final ValueChanged<CompressionSettings> onChanged;

  const _ResizeSettings({
    required this.settings,
    required this.widthCtrl,
    required this.heightCtrl,
    required this.percentCtrl,
    required this.usePercentage,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dimensions', style: tt.labelLarge),
            _SegmentPill(
                selected: usePercentage, onChanged: onToggle),
          ],
        ),
        const Gap(12),
        if (usePercentage) ...[
          Text('Scale each image to a % of its original size',
              style: tt.bodySmall),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: percentCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]'))
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Percentage',
                    suffixText: '%',
                  ),
                ),
              ),
              const Gap(10),
              _Preset(
                  label: '75%',
                  onTap: () => percentCtrl.text = '75'),
              const Gap(6),
              _Preset(
                  label: '50%',
                  onTap: () => percentCtrl.text = '50'),
              const Gap(6),
              _Preset(
                  label: '25%',
                  onTap: () => percentCtrl.text = '25'),
            ],
          ),
        ] else ...[
          Text('Set a fixed width, height, or both',
              style: tt.bodySmall),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widthCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    suffixText: 'px',
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextField(
                  controller: heightCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'px',
                  ),
                ),
              ),
            ],
          ),
        ],
        const Gap(12),
        Row(
          children: [
            Switch(
              value: settings.keepAspectRatio,
              onChanged: (_) => onChanged(
                  settings.copyWith(
                      keepAspectRatio: !settings.keepAspectRatio)),
            ),
            const Gap(8),
            Text('Keep aspect ratio',
                style: tt.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onChanged;
  const _SegmentPill(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated
            : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillTab(
              label: 'px', active: !selected, onTap: () => onChanged(false)),
          _PillTab(
              label: '%', active: selected, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PillTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Preset({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevated
              : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Empty picker ─────────────────────────────────────────────────────────────

class _EmptyPicker extends StatefulWidget {
  final List<Color> gradient;
  final VoidCallback onTap;
  const _EmptyPicker({required this.gradient, required this.onTap});

  @override
  State<_EmptyPicker> createState() => _EmptyPickerState();
}

class _EmptyPickerState extends State<_EmptyPicker> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor =
        widget.gradient[0].withOpacity(_pressed ? 0.7 : 0.3);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 180,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.gradient[0].withOpacity(0.06)
              : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    size: 32, color: Colors.white),
              ),
              const Gap(16),
              const Text('Tap to select images',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const Gap(6),
              Text(
                'You can pick multiple images at once',
                style:
                    Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Image grid ───────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<BatchItem> items;
  final bool isProcessing;
  final List<Color> gradient;
  final ValueChanged<int> onRemove;

  const _ImageGrid({
    required this.items,
    required this.isProcessing,
    required this.gradient,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GridTile(
          item: item,
          gradient: gradient,
          canRemove: !isProcessing,
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  final BatchItem item;
  final List<Color> gradient;
  final bool canRemove;
  final VoidCallback onRemove;

  const _GridTile({
    required this.item,
    required this.gradient,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(item.image.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceElevated,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.white38),
            ),
          ),
        ),

        // Status overlay
        if (status != BatchItemStatus.pending)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: _overlayColor(status),
              child: Center(child: _statusIcon(status, gradient)),
            ),
          ),

        // Size badge (bottom left)
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              formatBytes(item.image.originalSize),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Remove button
        if (canRemove && status == BatchItemStatus.pending)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),

        // Saved badge after done
        if (status == BatchItemStatus.done && item.result != null)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                formatBytes(item.result!.newSize),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Color _overlayColor(BatchItemStatus s) {
    switch (s) {
      case BatchItemStatus.processing:
        return Colors.black.withOpacity(0.5);
      case BatchItemStatus.done:
        return Colors.green.withOpacity(0.35);
      case BatchItemStatus.failed:
        return Colors.red.withOpacity(0.45);
      default:
        return Colors.transparent;
    }
  }

  Widget _statusIcon(BatchItemStatus s, List<Color> gradient) {
    switch (s) {
      case BatchItemStatus.processing:
        return SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: gradient[1],
            strokeWidth: 2.5,
          ),
        );
      case BatchItemStatus.done:
        return const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 32);
      case BatchItemStatus.failed:
        return const Icon(Icons.error_rounded,
            color: Colors.white, size: 32);
      default:
        return const SizedBox();
    }
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

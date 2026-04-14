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

class _BatchScreenState extends ConsumerState<BatchScreen> {
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _percentCtrl = TextEditingController(text: '75');
  bool _usePercentage = false;

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  bool get _isCompress => widget.mode == ImageMode.compress;

  // Mode accent — compress=teal, resize=blue (consistent with editor/result)
  Color get _accent =>
      _isCompress ? AppColors.compress : AppColors.resize;

  Future<void> _processAll() async {
    final notifier = ref.read(batchProvider.notifier);
    final state = ref.read(batchProvider);

    if (!_isCompress) {
      final current = state.settings;
      if (_usePercentage) {
        final pct = double.tryParse(_percentCtrl.text.trim()) ?? 75;
        notifier.updateSettings(current.copyWith(
          width: null,
          height: null,
          targetSizeKB: -(pct.round()),
          clearTargetSizeKB: false,
        ));
      } else {
        final w = int.tryParse(_widthCtrl.text.trim());
        final h = int.tryParse(_heightCtrl.text.trim());
        notifier.updateSettings(
            current.copyWith(width: w, height: h, clearTargetSizeKB: true));
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchProvider);
    final notifier = ref.read(batchProvider.notifier);
    final settings = state.settings;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isCompress ? 'Batch Compress' : 'Batch Resize'),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: state.isProcessing ? null : notifier.clearAll,
              child: Text('Clear all',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Settings card ──────────────────────────────────────────
              _SectionCard(
                child: _isCompress
                    ? _CompressSettings(
                        settings: settings,
                        accent: _accent,
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

              // ── Format card ─────────────────────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Output Format', style: tt.labelLarge),
                    const Gap(12),
                    // Wrap prevents overflow on narrow screens
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: AppConstants.supportedFormats.map((f) {
                        final sel = f == settings.format;
                        return GestureDetector(
                          onTap: () => notifier.updateSettings(
                              settings.copyWith(format: f)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? cs.primary
                                  : cs.surfaceContainerHighest
                                      .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? cs.primary
                                    : cs.outlineVariant.withOpacity(0.3),
                              ),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // ── Image grid header ──────────────────────────────────────
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
                    onPressed:
                        state.isProcessing ? null : notifier.pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: const Text('Add images'),
                    style: TextButton.styleFrom(
                        foregroundColor: cs.primary),
                  ),
                ],
              ),
              const Gap(8),

              // ── Image grid / empty state ──────────────────────────────
              if (state.items.isEmpty)
                _EmptyPicker(
                  accent: _accent,
                  onTap: notifier.pickImages,
                )
              else
                _ImageGrid(
                  items: state.items,
                  isProcessing: state.isProcessing,
                  accent: _accent,
                  onRemove: (i) => notifier.removeItem(i),
                ),

              // ── Progress bar ───────────────────────────────────────────
              if (state.isProcessing) ...[
                const Gap(16),
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
                          color: _accent,
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
                    backgroundColor:
                        cs.surfaceContainerHighest.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation(_accent),
                  ),
                ),
              ],

              const Gap(20),

              // ── Ad ──────────────────────────────────────────────────────
              Center(child: AdManager.instance.getBannerAdWidget()),
              const Gap(20),

              // ── Process button ─────────────────────────────────────────
              if (state.items.isNotEmpty)
                PfButton(
                  label: _isCompress
                      ? 'Compress ${state.items.length} Image${state.items.length > 1 ? "s" : ""}'
                      : 'Resize ${state.items.length} Image${state.items.length > 1 ? "s" : ""}',
                  isLoading: state.isProcessing,
                  icon: _isCompress
                      ? Icons.compress_rounded
                      : Icons.photo_size_select_large_rounded,
                  backgroundColor: _accent,
                  onPressed: _processAll,
                ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compress settings ──────────────────────────────────────────────────

class _CompressSettings extends StatelessWidget {
  final CompressionSettings settings;
  final Color accent;
  final ValueChanged<CompressionSettings> onChanged;
  const _CompressSettings({
    required this.settings,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${settings.quality}%',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ],
        ),
        const Gap(4),
        Text(_qualityLabel(settings.quality), style: tt.bodySmall),
        const Gap(8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withOpacity(0.15),
          ),
          child: Slider(
            value: settings.quality.toDouble(),
            min: 5,
            max: 95,
            divisions: 18,
            label: '${settings.quality}%',
            onChanged: (v) =>
                onChanged(settings.copyWith(quality: v.round())),
          ),
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

// ── Resize settings ───────────────────────────────────────────────────

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
                      labelText: 'Percentage', suffixText: '%'),
                ),
              ),
              const Gap(10),
              _Preset(label: '75%', onTap: () => percentCtrl.text = '75'),
              const Gap(6),
              _Preset(label: '50%', onTap: () => percentCtrl.text = '50'),
              const Gap(6),
              _Preset(label: '25%', onTap: () => percentCtrl.text = '25'),
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
                      labelText: 'Width', suffixText: 'px'),
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
                      labelText: 'Height', suffixText: 'px'),
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
              onChanged: (_) => onChanged(settings.copyWith(
                  keepAspectRatio: !settings.keepAspectRatio)),
            ),
            const Gap(8),
            Text('Keep aspect ratio', style: tt.bodyMedium),
          ],
        ),
      ],
    );
  }
}

// ── Segment pill (px / %) ─────────────────────────────────────────────

class _SegmentPill extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onChanged;
  const _SegmentPill({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
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

// ── Preset chip ─────────────────────────────────────────────────────────

class _Preset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Preset({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Empty picker ─────────────────────────────────────────────────────────

class _EmptyPicker extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;
  const _EmptyPicker({required this.accent, required this.onTap});

  @override
  State<_EmptyPicker> createState() => _EmptyPickerState();
}

class _EmptyPickerState extends State<_EmptyPicker> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.accent.withOpacity(0.06)
              : cs.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.accent
                .withOpacity(_pressed ? 0.6 : 0.25),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.accent.withOpacity(0.25),
                  ),
                ),
                child: Icon(Icons.photo_library_outlined,
                    size: 26, color: widget.accent),
              ),
              const Gap(12),
              const Text('Tap to select images',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Gap(4),
              Text('Pick multiple images at once',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image grid ────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<BatchItem> items;
  final bool isProcessing;
  final Color accent;
  final ValueChanged<int> onRemove;

  const _ImageGrid({
    required this.items,
    required this.isProcessing,
    required this.accent,
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
      itemBuilder: (context, index) => _GridTile(
        item: items[index],
        accent: accent,
        canRemove: !isProcessing,
        onRemove: () => onRemove(index),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final BatchItem item;
  final Color accent;
  final bool canRemove;
  final VoidCallback onRemove;

  const _GridTile({
    required this.item,
    required this.accent,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(item.image.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.white38),
            ),
          ),
        ),
        if (status != BatchItemStatus.pending)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: _overlayColor(status),
              child: Center(child: _statusIcon(status, accent)),
            ),
          ),
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

  Widget _statusIcon(BatchItemStatus s, Color accent) {
    switch (s) {
      case BatchItemStatus.processing:
        return SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              color: accent, strokeWidth: 2.5),
        );
      case BatchItemStatus.done:
        return const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 30);
      case BatchItemStatus.failed:
        return const Icon(Icons.error_rounded,
            color: Colors.white, size: 30);
      default:
        return const SizedBox();
    }
  }
}

// ── Section card ───────────────────────────────────────────────────────────
// Border-only — consistent with editor_screen and settings_screen

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

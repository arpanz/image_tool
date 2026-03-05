import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/selected_image.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../home/home_screen.dart';
import '../result/result_screen.dart';
import 'editor_controller.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final SelectedImage image;
  final ImageMode mode;
  const EditorScreen({super.key, required this.image, required this.mode});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _percentCtrl;
  bool _usePercentage = false;

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _percentCtrl = TextEditingController(text: '75');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  Future<void> _onProcess() async {
    final notifier = ref.read(editorProvider.notifier);

    if (widget.mode == ImageMode.resize) {
      if (_usePercentage) {
        final pct = double.tryParse(_percentCtrl.text.trim());
        if (pct != null && pct > 0) {
          final newW = (widget.image.width * pct / 100).round();
          final newH = (widget.image.height * pct / 100).round();
          notifier.setWidth(newW);
          notifier.setHeight(newH);
        }
      } else {
        final w = int.tryParse(_widthCtrl.text.trim());
        final h = int.tryParse(_heightCtrl.text.trim());
        if (w != null) notifier.setWidth(w);
        if (h != null) notifier.setHeight(h);
      }
    }

    final result = await notifier.compress(widget.image);
    if (result != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final settings = state.settings;
    final isProcessing = state.compressionState is AsyncLoading;
    final isCompress = widget.mode == ImageMode.compress;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen<EditorState>(editorProvider, (_, next) {
      if (next.compressionState is AsyncError) {
        final err = (next.compressionState as AsyncError).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $err'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isCompress ? 'Compress' : 'Resize'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Image Preview ----
              _ImagePreview(
                path: widget.image.path,
                originalSize: widget.image.originalSize,
                width: widget.image.width,
                height: widget.image.height,
              ),
              const Gap(28),

              if (isCompress) ...[
                // ---- Quality Section ----
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel('Quality'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${settings.quality}%',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        _qualityLabel(settings.quality),
                        style: tt.bodySmall,
                      ),
                      const Gap(8),
                      Slider(
                        value: settings.quality.toDouble(),
                        min: AppConstants.minQuality.toDouble(),
                        max: AppConstants.maxQuality.toDouble(),
                        divisions: 18,
                        label: '${settings.quality}%',
                        onChanged: (v) =>
                            ref.read(editorProvider.notifier).setQuality(v.round()),
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
                  ),
                ),
                const Gap(16),
              ] else ...[
                // ---- Resize Section ----
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel('Resize Mode'),
                          _SegmentedToggle(
                            selected: _usePercentage,
                            onChanged: (v) => setState(() => _usePercentage = v),
                          ),
                        ],
                      ),
                      const Gap(16),
                      if (_usePercentage) ...[
                        Text(
                          'Scale to ${_percentCtrl.text.isNotEmpty ? _percentCtrl.text : "?"}% of original',
                          style: tt.bodySmall,
                        ),
                        const Gap(10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _percentCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Percentage',
                                  suffixText: '%',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const Gap(12),
                            _PercentPreset(
                              percent: 75,
                              onTap: () {
                                _percentCtrl.text = '75';
                                setState(() {});
                              },
                            ),
                            const Gap(6),
                            _PercentPreset(
                              percent: 50,
                              onTap: () {
                                _percentCtrl.text = '50';
                                setState(() {});
                              },
                            ),
                            const Gap(6),
                            _PercentPreset(
                              percent: 25,
                              onTap: () {
                                _percentCtrl.text = '25';
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        if (_percentCtrl.text.isNotEmpty) ...[
                          const Gap(12),
                          _DimensionPreview(
                            originalW: widget.image.width,
                            originalH: widget.image.height,
                            pct: double.tryParse(_percentCtrl.text) ?? 100,
                          ),
                        ],
                      ] else ...[
                        Text(
                          'Enter width, height, or both',
                          style: tt.bodySmall,
                        ),
                        const Gap(10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _widthCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Width',
                                  suffixText: 'px',
                                  hintText: '${widget.image.width}',
                                ),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: TextField(
                                controller: _heightCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Height',
                                  suffixText: 'px',
                                  hintText: '${widget.image.height}',
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
                            onChanged: (_) =>
                                ref.read(editorProvider.notifier).toggleAspectRatio(),
                          ),
                          const Gap(8),
                          Text('Keep aspect ratio', style: tt.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(16),
              ],

              // ---- Format Section ----
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Output Format'),
                    const Gap(12),
                    _FormatSelector(
                      current: settings.format,
                      onChanged: (f) =>
                          ref.read(editorProvider.notifier).setFormat(f),
                    ),
                  ],
                ),
              ),
              const Gap(28),

              // ---- Process Button ----
              PfButton(
                label: isCompress ? 'Compress Image' : 'Resize Image',
                isLoading: isProcessing,
                icon: isCompress ? Icons.compress_rounded : Icons.photo_size_select_large_rounded,
                onPressed: _onProcess,
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }

  String _qualityLabel(int q) {
    if (q >= 85) return 'High quality · Larger file size';
    if (q >= 60) return 'Balanced quality and size';
    if (q >= 35) return 'Smaller file · Some quality loss';
    return 'Maximum compression · Visible quality loss';
  }
}

class _ImagePreview extends StatelessWidget {
  final String path;
  final int originalSize;
  final int width;
  final int height;

  const _ImagePreview({
    required this.path,
    required this.originalSize,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(path),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${width}×${height}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formatBytes(originalSize),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final bool selected; // true = percentage
  final ValueChanged<bool> onChanged;
  const _SegmentedToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTab(
            label: 'px',
            active: !selected,
            onTap: () => onChanged(false),
          ),
          _ToggleTab(
            label: '%',
            active: selected,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PercentPreset extends StatelessWidget {
  final int percent;
  final VoidCallback onTap;
  const _PercentPreset({required this.percent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$percent%',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DimensionPreview extends StatelessWidget {
  final int originalW;
  final int originalH;
  final double pct;
  const _DimensionPreview({
    required this.originalW,
    required this.originalH,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final newW = (originalW * pct / 100).round();
    final newH = (originalH * pct / 100).round();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: cs.primary),
          const Gap(6),
          Text(
            '${originalW}×${originalH}  →  ${newW}×${newH}',
            style: TextStyle(
              color: cs.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _FormatSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: AppConstants.supportedFormats.map((f) {
        final isSelected = f == current;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

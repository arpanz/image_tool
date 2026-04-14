import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/compression_settings.dart';
import '../../core/models/selected_image.dart';
import '../../core/utils/image_processor.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/widgets/pf_button.dart';
import '../home/home_screen.dart';
import '../result/result_screen.dart';
import 'editor_controller.dart';

enum _DimUnit { px, percent, cm, mm }

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
  late final TextEditingController _targetSizeCtrl;
  late final TextEditingController _dpiCtrl;
  _DimUnit _dimUnit = _DimUnit.px;
  bool _useTargetSize = false;

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _percentCtrl = TextEditingController(text: '75');
    _targetSizeCtrl = TextEditingController();
    _dpiCtrl = TextEditingController(text: '72');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _percentCtrl.dispose();
    _targetSizeCtrl.dispose();
    _dpiCtrl.dispose();
    super.dispose();
  }

  // Mode accent colour — compress=teal, resize=blue
  Color get _accent =>
      widget.mode == ImageMode.compress ? AppColors.compress : AppColors.resize;

  Future<void> _onProcess() async {
    final notifier = ref.read(editorProvider.notifier);

    if (widget.mode == ImageMode.compress && _useTargetSize) {
      final kb = int.tryParse(_targetSizeCtrl.text.trim());
      notifier.setTargetSizeKB(kb != null && kb > 0 ? kb : null);
    } else {
      notifier.setTargetSizeKB(null);
    }

    if (widget.mode == ImageMode.resize) {
      switch (_dimUnit) {
        case _DimUnit.percent:
          final pct = double.tryParse(_percentCtrl.text.trim());
          if (pct != null && pct > 0) {
            notifier.setWidth((widget.image.width * pct / 100).round());
            notifier.setHeight((widget.image.height * pct / 100).round());
          }
        case _DimUnit.px:
          final w = int.tryParse(_widthCtrl.text.trim());
          final h = int.tryParse(_heightCtrl.text.trim());
          if (w != null) notifier.setWidth(w);
          if (h != null) notifier.setHeight(h);
        case _DimUnit.cm:
          final dpi = double.tryParse(_dpiCtrl.text.trim()) ?? 72;
          final wCm = double.tryParse(_widthCtrl.text.trim());
          final hCm = double.tryParse(_heightCtrl.text.trim());
          if (wCm != null) notifier.setWidth((wCm / 2.54 * dpi).round());
          if (hCm != null) notifier.setHeight((hCm / 2.54 * dpi).round());
        case _DimUnit.mm:
          final dpi = double.tryParse(_dpiCtrl.text.trim()) ?? 72;
          final wMm = double.tryParse(_widthCtrl.text.trim());
          final hMm = double.tryParse(_heightCtrl.text.trim());
          if (wMm != null) notifier.setWidth((wMm / 25.4 * dpi).round());
          if (hMm != null) notifier.setHeight((hMm / 25.4 * dpi).round());
      }
    }

    final result = await notifier.compress(widget.image);
    if (result != null && mounted) {
      AdManager.instance.showInterstitial(
        context,
        onAdDismissed: () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ResultScreen(result: result, mode: widget.mode),
              ),
            );
          }
        },
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    final showFitMode = !isCompress && !settings.keepAspectRatio;

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image preview ───────────────────────────────────────
              _ImagePreview(
                path: widget.image.path,
                originalSize: widget.image.originalSize,
                width: widget.image.width,
                height: widget.image.height,
              ),
              const Gap(24),

              if (isCompress) ...[
                // ── Output format (before quality — format affects target-size compat) ──
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Output Format'),
                      const Gap(12),
                      _FormatSelector(
                        current: settings.format,
                        onChanged: (f) =>
                            ref.read(editorProvider.notifier).setFormat(f),
                      ),
                    ],
                  ),
                ),
                const Gap(14),

                // ── Quality slider ──────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionLabel('Quality'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${settings.quality}%',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(_qualityLabel(settings.quality),
                          style: tt.bodySmall),
                      const Gap(8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _accent,
                          thumbColor: _accent,
                          overlayColor: _accent.withOpacity(0.15),
                        ),
                        child: Slider(
                          value: settings.quality.toDouble(),
                          min: AppConstants.minQuality.toDouble(),
                          max: AppConstants.maxQuality.toDouble(),
                          // step of 5 from minQuality to maxQuality
                          divisions: ((AppConstants.maxQuality -
                                      AppConstants.minQuality) ~/
                                  5),
                          label: '${settings.quality}%',
                          onChanged: (v) => ref
                              .read(editorProvider.notifier)
                              .setQuality(v.round()),
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
                  ),
                ),
                const Gap(14),

                // ── Target file size ─────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionLabel('Target Size'),
                          Switch(
                            value: _useTargetSize,
                            onChanged: (v) =>
                                setState(() => _useTargetSize = v),
                          ),
                        ],
                      ),
                      Text(
                        'Compress to a specific file size (quality is set automatically)',
                        style: tt.bodySmall,
                      ),
                      if (_useTargetSize) ...[
                        const Gap(12),
                        TextField(
                          controller: _targetSizeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Max file size',
                            suffixText: 'KB',
                            hintText: 'e.g. 500',
                            helperText: _targetSizeCtrl.text.isNotEmpty
                                ? '≈ ${(int.tryParse(_targetSizeCtrl.text) ?? 0) / 1024 > 1 ? '${((int.tryParse(_targetSizeCtrl.text) ?? 0) / 1024).toStringAsFixed(1)} MB' : '${_targetSizeCtrl.text} KB'}'
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SizePresetChip(
                                label: '100 KB',
                                onTap: () => setState(
                                    () => _targetSizeCtrl.text = '100')),
                            _SizePresetChip(
                                label: '250 KB',
                                onTap: () => setState(
                                    () => _targetSizeCtrl.text = '250')),
                            _SizePresetChip(
                                label: '500 KB',
                                onTap: () => setState(
                                    () => _targetSizeCtrl.text = '500')),
                            _SizePresetChip(
                                label: '1 MB',
                                onTap: () => setState(
                                    () => _targetSizeCtrl.text = '1024')),
                            _SizePresetChip(
                                label: '2 MB',
                                onTap: () => setState(
                                    () => _targetSizeCtrl.text = '2048')),
                          ],
                        ),
                        if (settings.format.toUpperCase() == 'PNG')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Target size is not supported for PNG. Switch to JPG or WEBP.',
                              style: tt.bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const Gap(14),
              ] else ...[
                // ── Dimensions ─────────────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionLabel('Dimensions'),
                          _UnitSelector(
                            current: _dimUnit,
                            onChanged: (u) {
                              setState(() {
                                _dimUnit = u;
                                _widthCtrl.clear();
                                _heightCtrl.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const Gap(16),
                      if (_dimUnit == _DimUnit.percent) ...[
                        Text(
                          'Scale to ${_percentCtrl.text.isNotEmpty ? _percentCtrl.text : '?'}% of original',
                          style: tt.bodySmall,
                        ),
                        const Gap(10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _percentCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]')),
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
                                onTap: () =>
                                    setState(() => _percentCtrl.text = '75')),
                            const Gap(6),
                            _PercentPreset(
                                percent: 50,
                                onTap: () =>
                                    setState(() => _percentCtrl.text = '50')),
                            const Gap(6),
                            _PercentPreset(
                                percent: 25,
                                onTap: () =>
                                    setState(() => _percentCtrl.text = '25')),
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
                        if (_dimUnit == _DimUnit.cm ||
                            _dimUnit == _DimUnit.mm) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dpiCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'DPI / PPI',
                                    hintText: '72',
                                    helperText: 'Print: 300  Screen: 72',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const Gap(8),
                              _DpiPreset(
                                  label: '72',
                                  onTap: () =>
                                      setState(() => _dpiCtrl.text = '72')),
                              const Gap(4),
                              _DpiPreset(
                                  label: '150',
                                  onTap: () =>
                                      setState(() => _dpiCtrl.text = '150')),
                              const Gap(4),
                              _DpiPreset(
                                  label: '300',
                                  onTap: () =>
                                      setState(() => _dpiCtrl.text = '300')),
                            ],
                          ),
                          const Gap(12),
                        ],
                        Text(
                          _dimUnit == _DimUnit.px
                              ? 'Enter width, height, or both'
                              : 'Enter dimensions in ${_dimUnit == _DimUnit.cm ? 'centimeters' : 'millimeters'}',
                          style: tt.bodySmall,
                        ),
                        const Gap(10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _widthCtrl,
                                keyboardType: _dimUnit == _DimUnit.px
                                    ? TextInputType.number
                                    : const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: _dimUnit == _DimUnit.px
                                    ? [
                                        FilteringTextInputFormatter.digitsOnly
                                      ]
                                    : [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9.]'))
                                      ],
                                decoration: InputDecoration(
                                  labelText: 'Width',
                                  suffixText: _dimUnitLabel(_dimUnit),
                                  hintText: _dimUnit == _DimUnit.px
                                      ? '${widget.image.width}'
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: TextField(
                                controller: _heightCtrl,
                                keyboardType: _dimUnit == _DimUnit.px
                                    ? TextInputType.number
                                    : const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: _dimUnit == _DimUnit.px
                                    ? [
                                        FilteringTextInputFormatter.digitsOnly
                                      ]
                                    : [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9.]'))
                                      ],
                                decoration: InputDecoration(
                                  labelText: 'Height',
                                  suffixText: _dimUnitLabel(_dimUnit),
                                  hintText: _dimUnit == _DimUnit.px
                                      ? '${widget.image.height}'
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        if (_widthCtrl.text.isNotEmpty ||
                            _heightCtrl.text.isNotEmpty) ...[
                          const Gap(12),
                          _PhysicalDimensionPreview(
                            originalW: widget.image.width,
                            originalH: widget.image.height,
                            widthText: _widthCtrl.text,
                            heightText: _heightCtrl.text,
                            unit: _dimUnit,
                            dpi: double.tryParse(_dpiCtrl.text) ?? 72,
                            keepAspect: settings.keepAspectRatio,
                          ),
                        ],
                      ],
                      const Gap(12),
                      Row(
                        children: [
                          Switch(
                            value: settings.keepAspectRatio,
                            onChanged: (_) => ref
                                .read(editorProvider.notifier)
                                .toggleAspectRatio(),
                          ),
                          const Gap(8),
                          Text('Keep aspect ratio', style: tt.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(14),

                if (showFitMode) ...[
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Fit Mode'),
                        const Gap(4),
                        Text(
                          'How to handle image when it doesn\'t fill the frame',
                          style: tt.bodySmall,
                        ),
                        const Gap(14),
                        _FitModeSelector(
                          current: settings.fitMode,
                          onChanged: (m) => ref
                              .read(editorProvider.notifier)
                              .setFitMode(m),
                        ),
                      ],
                    ),
                  ),
                  const Gap(14),
                ],

                // Output format at bottom for resize mode
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Output Format'),
                      const Gap(12),
                      _FormatSelector(
                        current: settings.format,
                        onChanged: (f) =>
                            ref.read(editorProvider.notifier).setFormat(f),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
              ],

              // ── Ad ─────────────────────────────────────────────────────
              AdManager.instance.getBannerAdWidget(),
              const Gap(16),

              // ── Process button ─────────────────────────────────────
              PfButton(
                label:
                    isCompress ? 'Compress Image' : 'Resize Image',
                isLoading: isProcessing,
                icon: isCompress
                    ? Icons.compress_rounded
                    : Icons.photo_size_select_large_rounded,
                backgroundColor: _accent,
                onPressed: _onProcess,
              ),
              const Gap(20),
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

  String _dimUnitLabel(_DimUnit u) {
    switch (u) {
      case _DimUnit.px:
        return 'px';
      case _DimUnit.percent:
        return '%';
      case _DimUnit.cm:
        return 'cm';
      case _DimUnit.mm:
        return 'mm';
    }
  }
}

// ── Image preview ─────────────────────────────────────────────────────────

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
    // Derive a sensible preview height: clamp to 36% of screen height
    final screenH = MediaQuery.of(context).size.height;
    final previewH = (screenH * 0.36).clamp(180.0, 280.0);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(path),
            width: double.infinity,
            height: previewH,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
            bottom: 10,
            left: 10,
            child: _Badge('${width}×${height}')),
        Positioned(
            bottom: 10,
            right: 10,
            child: _Badge(formatBytes(originalSize))),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────
// Consistent with settings_screen — border only, no shadow

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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}

// ── Unit selector ──────────────────────────────────────────────────────────

class _UnitSelector extends StatelessWidget {
  final _DimUnit current;
  final ValueChanged<_DimUnit> onChanged;
  const _UnitSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _DimUnit.values.map((u) {
          final label = switch (u) {
            _DimUnit.px => 'px',
            _DimUnit.percent => '%',
            _DimUnit.cm => 'cm',
            _DimUnit.mm => 'mm',
          };
          return _ToggleTab(
            label: label,
            active: current == u,
            onTap: () => onChanged(u),
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleTab(
      {required this.label, required this.active, required this.onTap});

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
            color: active
                ? Colors.white
                : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Presets ────────────────────────────────────────────────────────────────

class _PercentPreset extends StatelessWidget {
  final int percent;
  final VoidCallback onTap;
  const _PercentPreset({required this.percent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$percent%',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DpiPreset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DpiPreset({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SizePresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SizePresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── Dimension previews ────────────────────────────────────────────────────

class _DimensionPreview extends StatelessWidget {
  final int originalW;
  final int originalH;
  final double pct;
  const _DimensionPreview(
      {required this.originalW,
      required this.originalH,
      required this.pct});

  @override
  Widget build(BuildContext context) {
    final newW = (originalW * pct / 100).round();
    final newH = (originalH * pct / 100).round();
    final cs = Theme.of(context).colorScheme;
    return _PreviewChip(
        text: '${originalW}×${originalH}  →  ${newW}×${newH}',
        color: cs.primary);
  }
}

class _PhysicalDimensionPreview extends StatelessWidget {
  final int originalW;
  final int originalH;
  final String widthText;
  final String heightText;
  final _DimUnit unit;
  final double dpi;
  final bool keepAspect;

  const _PhysicalDimensionPreview({
    required this.originalW,
    required this.originalH,
    required this.widthText,
    required this.heightText,
    required this.unit,
    required this.dpi,
    required this.keepAspect,
  });

  int? _toPx(String text) {
    final v = double.tryParse(text);
    if (v == null || v <= 0) return null;
    switch (unit) {
      case _DimUnit.px:
        return v.round();
      case _DimUnit.cm:
        return (v / 2.54 * dpi).round();
      case _DimUnit.mm:
        return (v / 25.4 * dpi).round();
      case _DimUnit.percent:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    int? targetW = widthText.isNotEmpty ? _toPx(widthText) : null;
    int? targetH = heightText.isNotEmpty ? _toPx(heightText) : null;

    int resolvedW = targetW ?? originalW;
    int resolvedH = targetH ?? originalH;

    if (keepAspect) {
      if (targetW != null && targetH == null) {
        resolvedH = (originalH * resolvedW / originalW).round();
      } else if (targetH != null && targetW == null) {
        resolvedW = (originalW * resolvedH / originalH).round();
      } else if (targetW != null && targetH != null) {
        final scale = (resolvedW / originalW) < (resolvedH / originalH)
            ? resolvedW / originalW
            : resolvedH / originalH;
        resolvedW = (originalW * scale).round();
        resolvedH = (originalH * scale).round();
      }
    }

    final cs = Theme.of(context).colorScheme;
    final unitLabel =
        unit == _DimUnit.px ? '' : ' (${resolvedW}×${resolvedH} px)';
    return _PreviewChip(
        text:
            '${originalW}×${originalH}  →  ${resolvedW}×${resolvedH}$unitLabel',
        color: cs.primary);
  }
}

class _PreviewChip extends StatelessWidget {
  final String text;
  final Color color;
  const _PreviewChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const Gap(6),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Fit mode selector ─────────────────────────────────────────────────────

class _FitModeOption {
  final ResizeFitMode mode;
  final String label;
  final IconData icon;
  final String desc;
  const _FitModeOption(
      {required this.mode,
      required this.label,
      required this.icon,
      required this.desc});
}

class _FitModeSelector extends StatelessWidget {
  final ResizeFitMode current;
  final ValueChanged<ResizeFitMode> onChanged;
  const _FitModeSelector({required this.current, required this.onChanged});

  static const _modes = [
    _FitModeOption(
        mode: ResizeFitMode.stretch,
        label: 'Stretch',
        icon: Icons.open_with_rounded,
        desc: 'Fill frame exactly, may distort'),
    _FitModeOption(
        mode: ResizeFitMode.crop,
        label: 'Crop',
        icon: Icons.crop_rounded,
        desc: 'Fill frame, center-crop excess'),
    _FitModeOption(
        mode: ResizeFitMode.fit,
        label: 'Fit',
        icon: Icons.fit_screen_rounded,
        desc: 'Fit inside, transparent fill'),
    _FitModeOption(
        mode: ResizeFitMode.background,
        label: 'Background',
        icon: Icons.rectangle_outlined,
        desc: 'Fit inside, white fill'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      children: _modes.map((m) {
        final isSelected = m.mode == current;
        return GestureDetector(
          onTap: () => onChanged(m.mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withOpacity(0.12)
                  : cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(m.icon,
                    size: 18,
                    color: isSelected
                        ? cs.primary
                        : Theme.of(context).textTheme.bodySmall?.color),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? cs.primary
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                          )),
                      Text(m.desc,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Format selector ────────────────────────────────────────────────────────
// Wrap instead of Row — no overflow on small screens

class _FormatSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _FormatSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.supportedFormats.map((f) {
        final isSelected = f == current;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Text(f,
                style: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ),
        );
      }).toList(),
    );
  }
}

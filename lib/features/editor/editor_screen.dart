import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/selected_image.dart';
import '../../core/theme/app_theme.dart';
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
    // Reset editor state when entering from a fresh pick
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

    final widthText = _widthCtrl.text.trim();
    final heightText = _heightCtrl.text.trim();
    if (widthText.isNotEmpty) notifier.setWidth(int.tryParse(widthText));
    if (heightText.isNotEmpty) notifier.setHeight(int.tryParse(heightText));

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
        title: const Text('Editor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Image Preview ----
              _ImagePreview(path: widget.image.path, originalSize: widget.image.originalSize),
              const Gap(24),

              // ---- Quality Slider ----
              _SectionLabel('Quality: ${settings.quality}%'),
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
              const Gap(20),

              // ---- Dimensions ----
              _SectionLabel('Resize (optional)'),
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Width (px)'),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Height (px)'),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // ---- Aspect Ratio Toggle ----
              Row(
                children: [
                  Switch(
                    value: settings.keepAspectRatio,
                    onChanged: (_) =>
                        ref.read(editorProvider.notifier).toggleAspectRatio(),
                    activeColor: AppColors.primary,
                  ),
                  const Gap(8),
                  Text(
                    'Keep aspect ratio',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Gap(20),

              // ---- Format Dropdown ----
              _SectionLabel('Output Format'),
              const Gap(10),
              _FormatDropdown(
                current: settings.format,
                onChanged: (f) =>
                    ref.read(editorProvider.notifier).setFormat(f),
              ),
              const Gap(32),

              // ---- Compress Button ----
              PfButton(
                label: 'Compress Image',
                isLoading: isCompressing,
                icon: Icons.compress,
                onPressed: _onCompress,
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

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
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
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(6),
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
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          iconEnabledColor: AppColors.primary,
          items: AppConstants.supportedFormats
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
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

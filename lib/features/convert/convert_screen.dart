import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/compression_settings.dart';
import '../../core/models/selected_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../home/home_screen.dart';
import '../picker/picker_controller.dart';
import '../result/result_screen.dart';

class ConvertScreen extends ConsumerStatefulWidget {
  const ConvertScreen({super.key});

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  static const _defaultQuality = 88;

  SelectedImage? _selectedImage;
  String _format = 'WEBP';
  int _quality = _defaultQuality;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pickerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pickerState = ref.watch(pickerProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen<PickerState>(pickerProvider, (prev, next) {
      if (next is PickerLoaded) {
        final sourceFormat = _formatFromPath(next.image.path);
        setState(() {
          _selectedImage = next.image;
          if (_format == sourceFormat) {
            _format = sourceFormat == 'JPG' ? 'WEBP' : 'JPG';
          }
        });
      } else if (next is PickerError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    final sourceFormat =
        _selectedImage == null ? null : _formatFromPath(_selectedImage!.path);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Convert'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.convert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.convert.withOpacity(0.28)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: AppColors.convert),
                    Gap(10),
                    Expanded(
                      child: Text(
                        'Convert format without leaving the app',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(14),
              _PickImageCard(
                selectedImage: _selectedImage,
                isLoading: pickerState is PickerLoading,
                onPick: _pickImage,
              ),
              const Gap(14),
              _OptionCard(
                title: 'Output Format',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.supportedFormats.map((f) {
                    final selected = _format == f;
                    final sameAsSource =
                        sourceFormat != null && sourceFormat == f;
                    return GestureDetector(
                      onTap: () => setState(() => _format = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.convert
                              : cs.surfaceContainerHighest.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.convert
                                : cs.outlineVariant.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f,
                              style: TextStyle(
                                color: selected ? Colors.white : cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (sameAsSource) ...[
                              const Gap(6),
                              Text(
                                '(same)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white70
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Gap(12),
              _OptionCard(
                title: 'Quality',
                trailing: Text(
                  _format == 'PNG' ? 'Lossless' : '$_quality%',
                  style: TextStyle(
                    color: AppColors.convert,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.convert,
                        thumbColor: AppColors.convert,
                        overlayColor: AppColors.convert.withOpacity(0.12),
                      ),
                      child: Slider(
                        value: _quality.toDouble(),
                        min: 20,
                        max: 100,
                        divisions: 16,
                        onChanged: _format == 'PNG'
                            ? null
                            : (v) => setState(() => _quality = v.round()),
                      ),
                    ),
                    Text(
                      _format == 'PNG'
                          ? 'PNG keeps transparency and uses lossless output.'
                          : 'Higher quality gives better visuals but larger file size.',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
              const Gap(12),
              AdManager.instance.getSmallNativeAdWidget(),
              const Gap(16),
              PfButton(
                label: _selectedImage == null
                    ? 'Select an image first'
                    : 'Convert Image',
                icon: Icons.swap_horiz_rounded,
                backgroundColor: AppColors.convert,
                isLoading: _isProcessing,
                onPressed:
                    _selectedImage == null || _isProcessing ? null : _convert,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    await ref.read(pickerProvider.notifier).pickImage();
  }

  Future<void> _convert() async {
    final image = _selectedImage;
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ImageProcessor.process(
        inputPath: image.path,
        settings: CompressionSettings(
          quality: _quality,
          format: _format,
        ),
        originalWidth: image.width,
        originalHeight: image.height,
      );

      if (!mounted) return;

      AdManager.instance.showInterstitial(
        context,
        onAdDismissed: () {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ResultScreen(result: result, mode: ImageMode.convert),
            ),
          );
        },
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversion failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'PNG';
    if (lower.endsWith('.webp')) return 'WEBP';
    return 'JPG';
  }
}

class _PickImageCard extends StatelessWidget {
  final SelectedImage? selectedImage;
  final bool isLoading;
  final VoidCallback onPick;

  const _PickImageCard({
    required this.selectedImage,
    required this.isLoading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isLoading ? null : onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: selectedImage == null
            ? SizedBox(
                height: 140,
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2.8)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                size: 36),
                            const Gap(10),
                            Text('Tap to select image', style: tt.titleMedium),
                          ],
                        ),
                ),
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 74,
                      height: 74,
                      child: Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.surface,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image selected',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Gap(4),
                        Text(
                          '${selectedImage!.width} x ${selectedImage!.height}',
                          style: tt.bodySmall,
                        ),
                        Text(
                          formatBytes(selectedImage!.originalSize),
                          style: tt.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: isLoading ? null : onPick,
                      child: const Text('Change')),
                ],
              ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _OptionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const Gap(12),
          child,
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/compression_result.dart';
import '../../core/utils/image_processor.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/app_review_service.dart';
import '../../core/widgets/pf_button.dart';
import '../home/home_screen.dart';
import '../picker/picker_controller.dart';
import '../editor/editor_controller.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final CompressionResult result;
  final ImageMode mode;

  const ResultScreen({
    super.key,
    required this.result,
    required this.mode,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  CompressionResult get result => widget.result;
  ImageMode get mode => widget.mode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppReviewService.registerSuccessfulAction();
    });
  }

  Future<void> _saveToDevice(BuildContext context) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final dot = result.outputPath.lastIndexOf('.');
      final ext =
          dot >= 0 ? result.outputPath.substring(dot).toLowerCase() : '.jpg';
      await File(result.outputPath).copy(
          '${dir.path}/PixelForge_${DateTime.now().millisecondsSinceEpoch}$ext');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved to device!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles([XFile(result.outputPath)]);
  }

  @override
  Widget build(BuildContext context) {
    final isResize = mode == ImageMode.resize;
    final savedPositive = result.savedPercent >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cardColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final dividerColor =
        isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isResize ? 'Resized!' : 'Compressed!'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(pickerProvider.notifier).reset();
              ref.read(editorProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'New Image',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isResize
                        ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
                        : [const Color(0xFF6C63FF), const Color(0xFF9D97FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isResize
                              ? const Color(0xFF11998E)
                              : const Color(0xFF6C63FF))
                          .withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isResize
                      ? Icons.photo_size_select_large_rounded
                      : Icons.compress_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const Gap(14),
              Text(
                isResize ? 'Resize complete!' : 'Compression done!',
                style: tt.headlineMedium,
              ),
              const Gap(4),
              Text(
                isResize
                    ? 'Your image has been resized successfully.'
                    : 'Your image is ready to save or share.',
                style: tt.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(24),

              // Image preview
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FullscreenViewer(path: result.outputPath),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(result.outputPath),
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 48, color: tt.bodySmall?.color),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fullscreen_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                    if (isResize && result.outWidth > 0)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${result.outWidth}\u00d7${result.outHeight}',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatBytes(result.newSize),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // Stats card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Original size',
                      value: formatBytes(result.originalSize),
                      valueColor: tt.bodyMedium?.color ?? Colors.grey,
                    ),
                    Divider(color: dividerColor, height: 24),
                    _StatRow(
                      label: 'New size',
                      value: formatBytes(result.newSize),
                      valueColor: cs.primary,
                    ),
                    if (!isResize) ...[
                      Divider(color: dividerColor, height: 24),
                      _StatRow(
                        label: 'Saved',
                        value: savedPositive
                            ? '-${result.savedPercent.toStringAsFixed(1)}%'
                            : '+${(-result.savedPercent).toStringAsFixed(1)}%',
                        valueColor:
                            savedPositive ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(20),

              // Ad between stats and actions (free users only)
              Center(child: AdManager.instance.getBannerAdWidget()),
              const Gap(16),

              // Actions
              PfButton(
                label: 'Share Image',
                icon: Icons.share_outlined,
                onPressed: _share,
              ),
              const Gap(12),
              PfButton(
                label: 'Save to Device',
                icon: Icons.download_outlined,
                backgroundColor:
                    isDark ? AppColors.surface : AppColors.lightSurfaceElevated,
                onPressed: () => _saveToDevice(context),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
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
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/compression_result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../editor/editor_controller.dart';
import '../picker/picker_controller.dart';

class ResultScreen extends ConsumerWidget {
  final CompressionResult result;
  const ResultScreen({super.key, required this.result});

  Future<void> _saveToDevice(BuildContext context) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final dot = result.outputPath.lastIndexOf('.');
      final extension =
          dot >= 0 ? result.outputPath.substring(dot).toLowerCase() : '.jpg';
      final savePath =
<<<<<<< HEAD
          '${dir.path}/PixelForge_${DateTime.now().millisecondsSinceEpoch}$extension';
      final srcFile = File(result.outputPath);
      await srcFile.copy(savePath);
=======
          '${dir.path}/PixelForge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(result.outputPath).copy(savePath);
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to device!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles([XFile(result.outputPath)]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
<<<<<<< HEAD
=======
    final saved = result.savedPercent;
    final savedPositive = saved >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
<<<<<<< HEAD
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResultHeader(savedPercent: result.savedPercent),
                        const Gap(14),
                        _PreviewCard(outputPath: result.outputPath),
                        const Gap(14),
                        _StatsCard(result: result),
                      ],
                    ),
                  ),
                ),
                PfButton(
                  label: 'View Processed Image',
                  icon: Icons.fullscreen_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            _ProcessedImageViewer(path: result.outputPath),
                      ),
                    );
                  },
                ),
                const Gap(10),
                PfButton(
                  label: 'Share Image',
                  icon: Icons.share_outlined,
                  onPressed: _share,
                ),
                const Gap(10),
                PfButton(
                  label: 'Save to Device',
                  icon: Icons.download_outlined,
                  backgroundColor: AppColors.surface,
                  onPressed: () => _saveToDevice(context),
                ),
                const Gap(8),
                TextButton(
                  onPressed: () {
                    ref.read(pickerProvider.notifier).reset();
                    ref.read(editorProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Process Another Image',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
=======
        title: const Text('Done!'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(pickerProvider.notifier).reset();
              ref.read(editorProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'New Image',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // ---- Success Icon ----
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const Gap(20),
              Text(
                'All done!',
                style: tt.headlineMedium,
              ),
              const Gap(6),
              Text(
                'Your image has been processed.',
                style: tt.bodyMedium,
              ),

              const Spacer(),

              // ---- Stats Card ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : AppColors.lightSurface,
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
                      label: 'Original',
                      value: formatBytes(result.originalSize),
                      valueColor: tt.bodyMedium?.color ?? Colors.grey,
                    ),
                    Divider(
                      color: isDark
                          ? AppColors.surfaceElevated
                          : AppColors.lightSurfaceElevated,
                      height: 24,
                    ),
                    _StatRow(
                      label: 'New size',
                      value: formatBytes(result.newSize),
                      valueColor: cs.primary,
                    ),
                    Divider(
                      color: isDark
                          ? AppColors.surfaceElevated
                          : AppColors.lightSurfaceElevated,
                      height: 24,
                    ),
                    _StatRow(
                      label: 'Saved',
                      value: savedPositive
                          ? '-${result.savedPercent.toStringAsFixed(1)}%'
                          : '+${(-result.savedPercent).toStringAsFixed(1)}%',
                      valueColor: savedPositive ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ---- Actions ----
              PfButton(
                label: 'Share',
                icon: Icons.share_outlined,
                onPressed: _share,
              ),
              const Gap(12),
              PfButton(
                label: 'Save to Device',
                icon: Icons.download_outlined,
                backgroundColor: isDark ? AppColors.surface : AppColors.lightSurfaceElevated,
                onPressed: () => _saveToDevice(context),
              ),
              const Gap(8),
            ],
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final double savedPercent;

  const _ResultHeader({required this.savedPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.background,
              size: 28,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compression Complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Gap(2),
                Text(
                  '${savedPercent.toStringAsFixed(1)}% size reduced',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String outputPath;

  const _PreviewCard({required this.outputPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Hero(
              tag: outputPath,
              child: Image.file(
                File(outputPath),
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 210,
                  color: AppColors.surfaceAlt,
                  alignment: Alignment.center,
                  child: const Text(
                    'Preview unavailable',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Processed image preview',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final CompressionResult result;

  const _StatsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Original Size',
            value: formatBytes(result.originalSize),
            valueColor: AppColors.textSecondary,
          ),
          const Divider(color: AppColors.border, height: 20),
          _StatRow(
            label: 'New Size',
            value: formatBytes(result.newSize),
            valueColor: AppColors.secondary,
          ),
          const Divider(color: AppColors.border, height: 20),
          _StatRow(
            label: 'Space Saved',
            value: '${result.savedPercent.toStringAsFixed(1)}%',
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProcessedImageViewer extends StatelessWidget {
  final String path;

  const _ProcessedImageViewer({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processed Image'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(
            child: Hero(
              tag: path,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Unable to load image',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

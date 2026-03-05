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
          '${dir.path}/PixelForge_${DateTime.now().millisecondsSinceEpoch}$extension';
      final srcFile = File(result.outputPath);
      await srcFile.copy(savePath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $savePath'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        automaticallyImplyLeading: false,
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

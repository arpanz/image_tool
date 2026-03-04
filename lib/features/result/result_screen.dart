import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/compression_result.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../picker/picker_controller.dart';
import '../editor/editor_controller.dart';

class ResultScreen extends ConsumerWidget {
  final CompressionResult result;
  const ResultScreen({super.key, required this.result});

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath =
          '${dir.path}/PixelForge_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    final saved = result.savedPercent;
    final savedColor = saved >= 0 ? AppColors.success : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
              const Gap(16),
              Text(
                'Compression Complete!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                    ),
              ),
              const Gap(8),
              Text(
                'Your image has been optimised.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),

              // ---- Stats Card ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Original Size',
                      value: formatBytes(result.originalSize),
                      valueColor: AppColors.textSecondary,
                    ),
                    const Divider(color: AppColors.background, height: 24),
                    _StatRow(
                      label: 'New Size',
                      value: formatBytes(result.newSize),
                      valueColor: AppColors.primary,
                    ),
                    const Divider(color: AppColors.background, height: 24),
                    _StatRow(
                      label: 'Space Saved',
                      value: '${result.savedPercent.toStringAsFixed(1)}%',
                      valueColor: savedColor,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // ---- Actions ----
              PfButton(
                label: 'Share Image',
                icon: Icons.share_outlined,
                onPressed: _share,
              ),
              const Gap(12),
              PfButton(
                label: 'Save to Device',
                icon: Icons.download_outlined,
                backgroundColor: AppColors.surface,
                onPressed: () => _saveToGallery(context),
              ),
              const Gap(12),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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

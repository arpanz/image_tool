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

  Future<void> _saveToDevice(BuildContext context) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final dot = result.outputPath.lastIndexOf('.');
      final ext = dot >= 0 ? result.outputPath.substring(dot).toLowerCase() : '.jpg';
      final savePath =
          '${dir.path}/PixelForge_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(result.outputPath).copy(savePath);
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
    final savedPositive = result.savedPercent >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
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
                child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
              ),
              const Gap(20),
              Text('All done!', style: tt.headlineMedium),
              const Gap(6),
              Text('Your image has been processed.', style: tt.bodyMedium),

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
                      color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
                      height: 24,
                    ),
                    _StatRow(
                      label: 'New size',
                      value: formatBytes(result.newSize),
                      valueColor: cs.primary,
                    ),
                    Divider(
                      color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
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

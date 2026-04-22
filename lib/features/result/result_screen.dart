import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/compression_result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/app_review_service.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../editor/editor_controller.dart';
import '../home/home_screen.dart';
import '../picker/picker_controller.dart';

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

  Color get _accent {
    switch (mode) {
      case ImageMode.compress:
        return AppColors.compress;
      case ImageMode.resize:
        return AppColors.resize;
      case ImageMode.convert:
        return AppColors.convert;
    }
  }

  IconData get _modeIcon {
    switch (mode) {
      case ImageMode.compress:
        return Icons.compress_rounded;
      case ImageMode.resize:
        return Icons.photo_size_select_large_rounded;
      case ImageMode.convert:
        return Icons.swap_horiz_rounded;
    }
  }

  String get _title {
    switch (mode) {
      case ImageMode.compress:
        return 'Compression Complete';
      case ImageMode.resize:
        return 'Resize Complete';
      case ImageMode.convert:
        return 'Conversion Complete';
    }
  }

  String get _subtitle {
    switch (mode) {
      case ImageMode.compress:
        return 'Your image is compressed and ready.';
      case ImageMode.resize:
        return 'Your image dimensions were updated successfully.';
      case ImageMode.convert:
        return 'Your image format has been converted.';
    }
  }

  String get _outputFormat {
    final parts = result.outputPath.split('.');
    if (parts.length < 2) return 'JPG';
    final ext = parts.last.toUpperCase();
    if (ext == 'JPEG') return 'JPG';
    return ext;
  }

  String get _shareLabel {
    switch (mode) {
      case ImageMode.compress:
        return 'Share Compressed Image';
      case ImageMode.resize:
        return 'Share Resized Image';
      case ImageMode.convert:
        return 'Share Converted Image';
    }
  }

  String get _saveLabel {
    switch (mode) {
      case ImageMode.compress:
        return 'Save Compressed Image';
      case ImageMode.resize:
        return 'Save Resized Image';
      case ImageMode.convert:
        return 'Save Converted Image';
    }
  }

  String get _heroMetricLabel {
    switch (mode) {
      case ImageMode.compress:
        return result.savedPercent >= 0 ? 'Space Reduced' : 'File Increased';
      case ImageMode.resize:
        return 'New Dimensions';
      case ImageMode.convert:
        return 'Output Format';
    }
  }

  String get _heroMetricValue {
    switch (mode) {
      case ImageMode.compress:
        final v = result.savedPercent.abs().toStringAsFixed(1);
        return '$v%';
      case ImageMode.resize:
        return '${result.outWidth} x ${result.outHeight}';
      case ImageMode.convert:
        return _outputFormat;
    }
  }

  Future<void> _saveToDevice(BuildContext context) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final dot = result.outputPath.lastIndexOf('.');
      final ext =
          dot >= 0 ? result.outputPath.substring(dot).toLowerCase() : '.jpg';

      await File(result.outputPath).copy(
          '${dir.path}/ImageResizer_${DateTime.now().millisecondsSinceEpoch}$ext');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image saved to device!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
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

  Future<void> _share() async {
    await Share.shareXFiles([XFile(result.outputPath)]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_title),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _accent.withOpacity(0.35), width: 1.5),
                ),
                child: Icon(_modeIcon, size: 30, color: _accent),
              ),
              const Gap(12),
              Text(_title, style: tt.headlineMedium),
              const Gap(4),
              Text(_subtitle,
                  style: tt.bodyMedium, textAlign: TextAlign.center),
              const Gap(18),
              _ResultHeroMetric(
                label: _heroMetricLabel,
                value: _heroMetricValue,
                color: _accent,
              ),
              const Gap(16),
              _OutputPreview(path: result.outputPath, result: result),
              const Gap(16),
              _StatsCard(
                  result: result,
                  mode: mode,
                  accent: _accent,
                  outputFormat: _outputFormat),
              const Gap(16),
              AdManager.instance.getBannerAdWidget(),
              const Gap(14),
              PfButton(
                label: _shareLabel,
                icon: Icons.share_outlined,
                backgroundColor: _accent,
                onPressed: _share,
              ),
              const Gap(10),
              PfButton(
                label: _saveLabel,
                icon: Icons.download_outlined,
                backgroundColor: isDark
                    ? AppColors.surfaceElevated
                    : AppColors.lightSurfaceElevated,
                onPressed: () => _saveToDevice(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultHeroMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _OutputPreview extends StatelessWidget {
  final String path;
  final CompressionResult result;

  const _OutputPreview({required this.path, required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _FullscreenViewer(path: path)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 48, color: cs.onSurfaceVariant),
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
          Positioned(
            bottom: 10,
            right: 10,
            child: _OverlayBadge(formatBytes(result.newSize)),
          ),
          if (result.outWidth > 0)
            Positioned(
              bottom: 10,
              left: 10,
              child: _OverlayBadge('${result.outWidth} x ${result.outHeight}'),
            ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final CompressionResult result;
  final ImageMode mode;
  final Color accent;
  final String outputFormat;

  const _StatsCard({
    required this.result,
    required this.mode,
    required this.accent,
    required this.outputFormat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final savedPositive = result.savedPercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Original size',
            value: formatBytes(result.originalSize),
            valueColor: cs.onSurfaceVariant,
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
          _StatRow(
            label: 'Output size',
            value: formatBytes(result.newSize),
            valueColor: accent,
          ),
          if (mode == ImageMode.compress) ...[
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
            _StatRow(
              label: 'Size change',
              value: savedPositive
                  ? '-${result.savedPercent.toStringAsFixed(1)}%'
                  : '+${(-result.savedPercent).toStringAsFixed(1)}%',
              valueColor: savedPositive ? AppColors.success : AppColors.error,
            ),
          ],
          if (mode == ImageMode.resize) ...[
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
            _StatRow(
              label: 'New dimensions',
              value: '${result.outWidth} x ${result.outHeight}',
              valueColor: accent,
            ),
          ],
          if (mode == ImageMode.convert) ...[
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
            _StatRow(
              label: 'Output format',
              value: outputFormat,
              valueColor: accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  final String text;
  const _OverlayBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
              color: valueColor, fontSize: 15, fontWeight: FontWeight.w700),
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


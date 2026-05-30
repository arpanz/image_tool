import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:gap/gap.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/compression_result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/app_review_service.dart';
import '../../core/utils/image_processor.dart';
import '../../core/widgets/pf_button.dart';
import '../../core/widgets/tool_ui.dart';
import '../../core/providers/history_provider.dart';
import '../editor/editor_controller.dart';
import '../home/home_screen.dart';
import '../picker/picker_controller.dart';
import '../../core/widgets/premium_page_route.dart';
import '../../core/widgets/fade_in_slide.dart';

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

  bool _isSavedToHistory = false;

  void _saveHistoryIfNeeded() {
    if (_isSavedToHistory) return;

    final historyNotifier = ref.read(historyProvider.notifier);
    if (!historyNotifier.state.isEnabled) return;

    final pickerState = ref.read(pickerProvider);
    int origWidth = 0;
    int origH = 0;
    if (pickerState is PickerLoaded) {
      origWidth = pickerState.image.width;
      origH = pickerState.image.height;
    }

    historyNotifier.addEntry(
      originalSize: result.originalSize,
      newSize: result.newSize,
      savedPercent: result.savedPercent,
      tempOutputPath: result.outputPath,
      width: result.outWidth,
      height: result.outHeight,
      originalWidth: origWidth,
      originalHeight: origH,
      originalFormat: _inputFormat,
      newFormat: _outputFormat,
      mode: mode.name,
    );
    _isSavedToHistory = true;
  }

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

  String get _inputFormat {
    final pickerState = ref.read(pickerProvider);
    if (pickerState is PickerLoaded) {
      final parts = pickerState.image.path.split('.');
      if (parts.length < 2) return 'JPG';
      final ext = parts.last.toUpperCase();
      if (ext == 'JPEG') return 'JPG';
      return ext;
    }
    return 'JPG';
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
      // Request gallery access if needed
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // Save to device gallery (visible in Photos / Gallery app)
      await Gal.putImage(result.outputPath, album: 'ImageResizer');

      // Save explicitly to history on successful gallery save
      _saveHistoryIfNeeded();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image saved to gallery!'),
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

  Future<void> _saveAs(BuildContext context) async {
    try {
      final originalFile = File(result.outputPath);
      if (!await originalFile.exists()) {
        throw Exception("Processed file not found");
      }
      final bytes = await originalFile.readAsBytes();

      String defaultFileName = 'output.${_outputFormat.toLowerCase()}';
      final pickerState = ref.read(pickerProvider);
      if (pickerState is PickerLoaded) {
        final originalName = pickerState.image.path.split(RegExp(r'[/\\]')).last;
        final ext = _outputFormat.toLowerCase();
        final dotIndex = originalName.lastIndexOf('.');
        final baseName = dotIndex != -1 ? originalName.substring(0, dotIndex) : originalName;
        defaultFileName = '${baseName}_processed.$ext';
      }

      final String? path = await FilePicker.saveFile(
        dialogTitle: 'Select location to save image:',
        fileName: defaultFileName,
        bytes: bytes,
      );

      if (path != null) {
        // Save explicitly to history on successful save
        _saveHistoryIfNeeded();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
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

  void _showSaveOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(20),
                Text(
                  'Choose Save Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _accent.withOpacity(0.12),
                    child: Icon(Icons.photo_library_outlined, color: _accent),
                  ),
                  title: const Text(
                    'Save to Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Save to default "ImageResizer" album'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _saveToDevice(context);
                  },
                ),
                const Gap(8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _accent.withOpacity(0.12),
                    child: Icon(Icons.folder_open_outlined, color: _accent),
                  ),
                  title: const Text(
                    'Save As...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Choose a custom folder and filename'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _saveAs(context);
                  },
                ),
                const Gap(12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _share() async {
    // Save explicitly to history on share triggers
    _saveHistoryIfNeeded();
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
              FadeInSlide(
                delay: Duration.zero,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.86, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _accent.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(_modeIcon, size: 31, color: _accent),
                  ),
                ),
              ),
              const Gap(12),
              FadeInSlide(
                delay: const Duration(milliseconds: 60),
                child: Text(_title, style: tt.headlineMedium),
              ),
              const Gap(4),
              FadeInSlide(
                delay: const Duration(milliseconds: 120),
                child: Text(_subtitle,
                    style: tt.bodyMedium, textAlign: TextAlign.center),
              ),
              const Gap(18),
              FadeInSlide(
                delay: const Duration(milliseconds: 180),
                child: _ResultHeroMetric(
                  label: _heroMetricLabel,
                  value: _heroMetricValue,
                  color: _accent,
                ),
              ),
              const Gap(16),
              FadeInSlide(
                delay: const Duration(milliseconds: 240),
                child: _OutputPreview(
                    path: result.outputPath, result: result, mode: mode),
              ),
              const Gap(16),
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: _StatsCard(
                    result: result,
                    mode: mode,
                    accent: _accent,
                    outputFormat: _outputFormat,
                    inputFormat: _inputFormat),
              ),
              const Gap(16),
              FadeInSlide(
                delay: const Duration(milliseconds: 360),
                child: AdManager.instance.getBannerAdWidget(),
              ),
              const Gap(14),
              FadeInSlide(
                delay: const Duration(milliseconds: 420),
                child: PfButton(
                  label: _shareLabel,
                  icon: Icons.share_outlined,
                  backgroundColor: _accent,
                  onPressed: _share,
                ),
              ),
              const Gap(10),
              FadeInSlide(
                delay: const Duration(milliseconds: 480),
                child: PfButton(
                  label: _saveLabel,
                  icon: Icons.download_outlined,
                  backgroundColor: isDark
                      ? AppColors.surfaceElevated
                      : AppColors.lightSurfaceElevated,
                  onPressed: () => _showSaveOptions(context),
                ),
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
    return ToolSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      accent: color,
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
  final ImageMode mode;

  const _OutputPreview(
      {required this.path, required this.result, required this.mode});

  String get _outputFormat {
    final parts = path.split('.');
    if (parts.length < 2) return 'JPG';
    final ext = parts.last.toUpperCase();
    if (ext == 'JPEG') return 'JPG';
    return ext;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PremiumPageRoute(child: _FullscreenViewer(path: path)),
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
          // Bottom-right: show file size for compress, format for convert
          Positioned(
            bottom: 10,
            right: 10,
            child: _OverlayBadge(
              mode == ImageMode.compress
                  ? formatBytes(result.newSize)
                  : mode == ImageMode.convert
                      ? _outputFormat
                      : formatBytes(result.newSize),
            ),
          ),
          // Bottom-left: show dimensions for compress/resize only
          if (result.outWidth > 0 && mode != ImageMode.convert)
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
  final String inputFormat;

  const _StatsCard({
    required this.result,
    required this.mode,
    required this.accent,
    required this.outputFormat,
    required this.inputFormat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final savedPositive = result.savedPercent >= 0;

    return ToolSurface(
      padding: const EdgeInsets.all(16),
      radius: 16,
      accent: accent,
      child: Column(
        children: [
          if (mode == ImageMode.compress) ...[
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
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
            _StatRow(
              label: 'Size change',
              value: savedPositive
                  ? '-${result.savedPercent.toStringAsFixed(1)}%'
                  : '+${(-result.savedPercent).toStringAsFixed(1)}%',
              valueColor: savedPositive ? AppColors.success : AppColors.error,
            ),
          ] else if (mode == ImageMode.resize) ...[
            _StatRow(
              label: 'Original size',
              value: formatBytes(result.originalSize),
              valueColor: cs.onSurfaceVariant,
            ),
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
            _StatRow(
              label: 'Output size',
              value: formatBytes(result.newSize),
              valueColor: cs.onSurfaceVariant,
            ),
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 20),
            _StatRow(
              label: 'New dimensions',
              value: '${result.outWidth} x ${result.outHeight}',
              valueColor: accent,
            ),
          ] else if (mode == ImageMode.convert) ...[
            _StatRow(
              label: 'Original format',
              value: inputFormat,
              valueColor: cs.onSurfaceVariant,
            ),
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

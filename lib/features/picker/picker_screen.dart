import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../editor/editor_screen.dart';
import '../home/home_screen.dart';
import 'picker_controller.dart';

class PickerScreen extends ConsumerWidget {
  final ImageMode mode;
  const PickerScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pickerProvider);
    final notifier = ref.read(pickerProvider.notifier);
    final tt = Theme.of(context).textTheme;

    ref.listen<PickerState>(pickerProvider, (prev, next) {
      if (next is PickerLoaded) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditorScreen(image: next.image, mode: mode),
          ),
        );
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

    final isCompress = mode == ImageMode.compress;
    final modeGradient = isCompress
        ? [const Color(0xFF6C63FF), const Color(0xFF9D97FF)]
        : [const Color(0xFF11998E), const Color(0xFF38EF7D)];
    final modeIcon = isCompress
        ? Icons.compress_rounded
        : Icons.photo_size_select_large_rounded;
    final modeTitle = isCompress ? 'Compress' : 'Resize';
    final modeSubtitle =
        isCompress ? 'Reduce file size' : 'Change dimensions';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(modeTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: modeGradient),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, color: Colors.white, size: 16),
                    const Gap(6),
                    Text(
                      modeSubtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Text('Pick an image', style: tt.headlineMedium),
              const Gap(6),
              Text('JPG \u00b7 PNG \u00b7 WebP supported',
                  style: tt.bodyMedium),
              const Gap(32),

              Expanded(
                child: _UploadZone(
                  isLoading: state is PickerLoading,
                  gradient: modeGradient,
                  onTap: () => notifier.pickImage(),
                ),
              ),

              const Gap(16),

              // Banner ad
              Center(child: AdManager.instance.getBannerAdWidget()),

              const Gap(12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: tt.bodySmall?.color),
                  const Gap(6),
                  Text(
                    'Fully offline \u00b7 No data leaves your device',
                    style: tt.bodySmall,
                  ),
                ],
              ),
              const Gap(4),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadZone extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _UploadZone({
    required this.isLoading,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<_UploadZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor =
        widget.gradient[0].withOpacity(_hovered ? 0.7 : 0.3);

    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.gradient[0].withOpacity(0.06)
              : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        color: widget.gradient[0],
                        strokeWidth: 3,
                      ),
                    ),
                    const Gap(16),
                    Text('Reading image\u2026',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(20),
                    Text(
                      'Tap to select an image',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface,
                          ),
                    ),
                    const Gap(8),
                    Text(
                      'From gallery or camera',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

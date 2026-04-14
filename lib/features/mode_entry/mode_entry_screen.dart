import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:pixel_forge/features/editor/editor_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../home/home_screen.dart';
import '../picker/picker_screen.dart';
import '../picker/picker_controller.dart';

class ModeEntryScreen extends ConsumerStatefulWidget {
  final ImageMode mode;
  const ModeEntryScreen({super.key, required this.mode});

  @override
  ConsumerState<ModeEntryScreen> createState() => _ModeEntryScreenState();
}

class _ModeEntryScreenState extends ConsumerState<ModeEntryScreen> {
  bool get _isCompress => widget.mode == ImageMode.compress;
  Color get _accent => _isCompress ? AppColors.compress : AppColors.resize;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final title = _isCompress ? 'Compress' : 'Resize';
    final subtitle = _isCompress
        ? 'Reduce file size, keep quality'
        : 'Change dimensions by pixels or %';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mode header ───────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _isCompress
                          ? Icons.compress_rounded
                          : Icons.photo_size_select_large_rounded,
                      color: _accent,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.headlineMedium),
                        const Gap(2),
                        Text(
                          subtitle,
                          style: tt.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(28),

              // ── Pick zone ────────────────────────────────────────
              Expanded(
                child: _PickZone(
                  accent: _accent,
                  isCompress: _isCompress,
                  ref: ref,
                ),
              ),

              const Gap(12),
              AdManager.instance.getSmallNativeAdWidget(),
              const Gap(8),
              const _PrivacyNote(),
              const Gap(12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pick zone ────────────────────────────────────────────────────────────────

class _PickZone extends ConsumerStatefulWidget {
  final Color accent;
  final bool isCompress;
  final WidgetRef ref;

  const _PickZone({
    required this.accent,
    required this.isCompress,
    required this.ref,
  });

  @override
  ConsumerState<_PickZone> createState() => _PickZoneState();
}

class _PickZoneState extends ConsumerState<_PickZone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pickerProvider);
    final notifier = ref.read(pickerProvider.notifier);
    final mode = widget.isCompress ? ImageMode.compress : ImageMode.resize;

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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final tt = Theme.of(context).textTheme;
    final isLoading = state is PickerLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!isLoading) notifier.pickImage();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.accent.withOpacity(0.05)
              : surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed
                ? widget.accent.withOpacity(0.5)
                : widget.accent.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: widget.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const Gap(14),
                    Text('Reading image…', style: tt.bodyMedium),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 34,
                        color: widget.accent,
                      ),
                    ),
                    const Gap(18),
                    Text(
                      'Select an image',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      'Tap to pick from gallery or camera',
                      style: tt.bodyMedium,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Privacy note ───────────────────────────────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const Gap(5),
        Text(
          'Fully offline \u00b7 No data leaves your device',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

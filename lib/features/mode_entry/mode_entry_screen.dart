import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:pixel_forge/features/editor/editor_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../batch/batch_screen.dart';
import '../home/home_screen.dart';
import '../picker/picker_screen.dart';
import '../picker/picker_controller.dart';

enum _EntryTab { single, batch }

class ModeEntryScreen extends ConsumerStatefulWidget {
  final ImageMode mode;
  const ModeEntryScreen({super.key, required this.mode});

  @override
  ConsumerState<ModeEntryScreen> createState() => _ModeEntryScreenState();
}

class _ModeEntryScreenState extends ConsumerState<ModeEntryScreen>
    with SingleTickerProviderStateMixin {
  _EntryTab _tab = _EntryTab.single;

  bool get _isCompress => widget.mode == ImageMode.compress;

  Color get _accent =>
      _isCompress ? AppColors.compress : AppColors.resize;

  void _switchTab(_EntryTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = _isCompress ? 'Compress' : 'Resize';
    final singleSubtitle = _isCompress
        ? 'Reduce file size, keep quality'
        : 'Change dimensions by pixels or %';
    final batchSubtitle = _isCompress
        ? 'Process multiple images at once'
        : 'Resize multiple images, same settings';

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
              // ── Mode header ─────────────────────────────────────────
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _tab == _EntryTab.single
                                ? singleSubtitle
                                : batchSubtitle,
                            key: ValueKey(_tab),
                            style: tt.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(24),

              // ── Tab toggle ───────────────────────────────────────────
              _TabToggle(
                selected: _tab,
                accent: _accent,
                onChanged: _switchTab,
              ),

              const Gap(20),

              // ── Content ─────────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final isIncoming = child.key == ValueKey(_tab);
                    final offset = isIncoming
                        ? (_tab == _EntryTab.batch
                            ? const Offset(1, 0)
                            : const Offset(-1, 0))
                        : (_tab == _EntryTab.batch
                            ? const Offset(-1, 0)
                            : const Offset(1, 0));
                    return SlideTransition(
                      position: Tween<Offset>(
                              begin: offset, end: Offset.zero)
                          .animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: _tab == _EntryTab.single
                      ? _SingleContent(
                          key: const ValueKey(_EntryTab.single),
                          mode: widget.mode,
                          accent: _accent,
                        )
                      : _BatchContent(
                          key: const ValueKey(_EntryTab.batch),
                          mode: widget.mode,
                          accent: _accent,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab toggle ───────────────────────────────────────────────────────────────
// Clean pill toggle — active side gets accent background, no gradient

class _TabToggle extends StatelessWidget {
  final _EntryTab selected;
  final Color accent;
  final ValueChanged<_EntryTab> onChanged;

  const _TabToggle({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.surfaceBorder : AppColors.lightSurfaceBorder;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          // Sliding pill — flat accent, no gradient
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            alignment: selected == _EntryTab.single
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              _TabLabel(
                label: 'Single',
                isSelected: selected == _EntryTab.single,
                onTap: () => onChanged(_EntryTab.single),
              ),
              _TabLabel(
                label: 'Batch',
                isSelected: selected == _EntryTab.batch,
                onTap: () => onChanged(_EntryTab.batch),
                badge: selected != _EntryTab.batch ? 'NEW' : null,
                badgeColor: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _TabLabel({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
              if (badge != null) ...[
                const Gap(5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor?.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: badgeColor?.withOpacity(0.4) ??
                            Colors.transparent),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single content ───────────────────────────────────────────────────────────

class _SingleContent extends ConsumerWidget {
  final ImageMode mode;
  final Color accent;

  const _SingleContent({
    super.key,
    required this.mode,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pickerProvider);
    final notifier = ref.read(pickerProvider.notifier);

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

    return Column(
      children: [
        Expanded(
          child: _PickZone(
            isLoading: state is PickerLoading,
            accent: accent,
            icon: Icons.add_photo_alternate_outlined,
            primaryLabel: 'Select an image',
            secondaryLabel: 'Tap to pick from gallery or camera',
            onTap: notifier.pickImage,
          ),
        ),
        const Gap(12),
        AdManager.instance.getSmallNativeAdWidget(),
        const Gap(8),
        const _PrivacyNote(),
        const Gap(12),
      ],
    );
  }
}

// ─── Batch content ────────────────────────────────────────────────────────────

class _BatchContent extends StatelessWidget {
  final ImageMode mode;
  final Color accent;

  const _BatchContent({
    super.key,
    required this.mode,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isCompress = mode == ImageMode.compress;

    return Column(
      children: [
        Expanded(
          child: _PickZone(
            isLoading: false,
            accent: accent,
            icon: Icons.photo_library_outlined,
            primaryLabel: 'Start batch ${isCompress ? "compression" : "resize"}',
            secondaryLabel: 'Select multiple images at once',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BatchScreen(mode: mode)),
            ),
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoChip(icon: Icons.layers_rounded, label: 'Multiple images', accent: accent),
            const Gap(8),
            _InfoChip(icon: Icons.tune_rounded, label: 'Shared settings', accent: accent),
            const Gap(8),
            _InfoChip(icon: Icons.save_alt_rounded, label: 'Save all at once', accent: accent),
          ],
        ),
        const Gap(8),
        const _PrivacyNote(),
        const Gap(12),
      ],
    );
  }
}

// ─── Pick zone ────────────────────────────────────────────────────────────────
// Clean dashed-border tap target. No pulsing gradient, no glow.

class _PickZone extends StatefulWidget {
  final bool isLoading;
  final Color accent;
  final IconData icon;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onTap;

  const _PickZone({
    required this.isLoading,
    required this.accent,
    required this.icon,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onTap,
  });

  @override
  State<_PickZone> createState() => _PickZoneState();
}

class _PickZoneState extends State<_PickZone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
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
            // note: Flutter Border does not support dashed; keeping solid
          ),
        ),
        child: Center(
          child: widget.isLoading
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
                        widget.icon,
                        size: 34,
                        color: widget.accent,
                      ),
                    ),
                    const Gap(18),
                    Text(
                      widget.primaryLabel,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      widget.secondaryLabel,
                      style: tt.bodyMedium,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.surfaceBorder : AppColors.lightSurfaceBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy note ─────────────────────────────────────────────────────────────

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
          'Fully offline · No data leaves your device',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

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
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isCompress => widget.mode == ImageMode.compress;

  List<Color> get _gradient => _isCompress
      ? [const Color(0xFF6C63FF), const Color(0xFF9D97FF)]
      : [const Color(0xFF11998E), const Color(0xFF38EF7D)];

  void _switchTab(_EntryTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (tab == _EntryTab.batch) {
      _slideCtrl.forward();
    } else {
      _slideCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = _isCompress ? 'Compress' : 'Resize';
    final singleSubtitle = _isCompress
        ? 'Reduce file size while keeping quality'
        : 'Change dimensions by pixels or percentage';
    final batchSubtitle = _isCompress
        ? 'Compress multiple images at the same time'
        : 'Resize multiple images with the same settings';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _isCompress
                          ? Icons.compress_rounded
                          : Icons.photo_size_select_large_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.headlineMedium),
                        const Gap(2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            _tab == _EntryTab.single
                                ? singleSubtitle
                                : batchSubtitle,
                            key: ValueKey(_tab),
                            style: tt.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(28),

              // ── Animated toggle ───────────────────────────────────────
              _TabToggle(
                selected: _tab,
                gradient: _gradient,
                onChanged: _switchTab,
              ),

              const Gap(28),

              // ── Content area — slides between single and batch ────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
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
                        begin: offset,
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: _tab == _EntryTab.single
                      ? _SingleContent(
                          key: const ValueKey(_EntryTab.single),
                          mode: widget.mode,
                          gradient: _gradient,
                        )
                      : _BatchContent(
                          key: const ValueKey(_EntryTab.batch),
                          mode: widget.mode,
                          gradient: _gradient,
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

class _TabToggle extends StatelessWidget {
  final _EntryTab selected;
  final List<Color> gradient;
  final ValueChanged<_EntryTab> onChanged;

  const _TabToggle({
    required this.selected,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Stack(
        children: [
          // Sliding pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            alignment: selected == _EntryTab.single
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(_EntryTab.single),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: selected == _EntryTab.single
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      child: const Text('Single Image'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(_EntryTab.batch),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: selected == _EntryTab.batch
                                ? Colors.white
                                : Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          child: const Text('Batch'),
                        ),
                        const Gap(6),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: selected == _EntryTab.batch ? 0 : 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Single content ───────────────────────────────────────────────────────────

class _SingleContent extends ConsumerWidget {
  final ImageMode mode;
  final List<Color> gradient;

  const _SingleContent({
    super.key,
    required this.mode,
    required this.gradient,
  });

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

    return Column(
      children: [
        Expanded(
          child: _PickZone(
            isLoading: state is PickerLoading,
            gradient: gradient,
            icon: Icons.add_photo_alternate_outlined,
            primaryLabel: 'Tap to select an image',
            secondaryLabel: 'From gallery or camera',
            onTap: notifier.pickImage,
          ),
        ),
        const Gap(12),
        AdManager.instance.getSmallNativeAdWidget(),
        const Gap(8),
        _PrivacyNote(),
        const Gap(12),
      ],
    );
  }
}

// ─── Batch content ────────────────────────────────────────────────────────────

class _BatchContent extends StatelessWidget {
  final ImageMode mode;
  final List<Color> gradient;

  const _BatchContent({
    super.key,
    required this.mode,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isCompress = mode == ImageMode.compress;

    return Column(
      children: [
        Expanded(
          child: _PickZone(
            isLoading: false,
            gradient: gradient,
            icon: Icons.photo_library_outlined,
            primaryLabel:
                'Tap to start batch ${isCompress ? "compression" : "resize"}',
            secondaryLabel: 'Select multiple images at once',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BatchScreen(mode: mode),
              ),
            ),
          ),
        ),
        const Gap(12),
        // Batch info chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoChip(
              icon: Icons.layers_rounded,
              label: 'Multiple images',
              gradient: gradient,
            ),
            const Gap(10),
            _InfoChip(
              icon: Icons.tune_rounded,
              label: 'Shared settings',
              gradient: gradient,
            ),
            const Gap(10),
            _InfoChip(
              icon: Icons.download_outlined,
              label: 'Save all at once',
              gradient: gradient,
            ),
          ],
        ),
        const Gap(8),
        _PrivacyNote(),
        const Gap(12),
      ],
    );
  }
}

// ─── Shared pick zone ─────────────────────────────────────────────────────────

class _PickZone extends StatefulWidget {
  final bool isLoading;
  final List<Color> gradient;
  final IconData icon;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onTap;

  const _PickZone({
    required this.isLoading,
    required this.gradient,
    required this.icon,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onTap,
  });

  @override
  State<_PickZone> createState() => _PickZoneState();
}

class _PickZoneState extends State<_PickZone>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = widget.gradient[0].withOpacity(_pressed ? 0.75 : 0.3);
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _pressed ? widget.gradient[0].withOpacity(0.07) : surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                    Text('Reading image…', style: tt.bodyMedium),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing icon container
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient[0].withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, size: 40, color: Colors.white),
                      ),
                    ),
                    const Gap(22),
                    Text(
                      widget.primaryLabel,
                      style: tt.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      widget.secondaryLabel,
                      style: tt.bodySmall,
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
  final List<Color> gradient;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient[0].withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: gradient[0]),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy note ─────────────────────────────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 12, color: tt.bodySmall?.color),
        const Gap(5),
        Text(
          'Fully offline · No data leaves your device',
          style: tt.bodySmall,
        ),
      ],
    );
  }
}

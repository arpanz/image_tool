import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/app_update_service.dart';
import '../../features/premium/paywall_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../batch/batch_entry_screen.dart';
import '../mode_entry/mode_entry_screen.dart';

enum ImageMode { compress, resize, convert }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AdManager.onShowPaywall = (ctx) async {
      await Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppUpdateService.checkForUpdatesOnLaunch(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pixel Forge', style: tt.headlineLarge),
                        const Gap(3),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            const Gap(4),
                            Text(
                              'Offline · No data leaves your device',
                              style: tt.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Pro badge
                  if (!AdManager.instance.isPro)
                    _ProBadge(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PaywallScreen()),
                      ),
                    )
                  else
                    _ActiveProBadge(),
                  const Gap(6),
                  // Settings — contains theme toggle
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    iconSize: 22,
                    color: cs.onSurfaceVariant,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Gap(28),

            // ── Mode cards ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _ModeCard(
                      icon: Icons.compress_rounded,
                      accentColor: AppColors.compress,
                      title: 'Compress',
                      subtitle: 'Reduce file size without losing quality',
                      tag: 'JPG · PNG · WEBP',
                      onTap: () => _navigate(context, ImageMode.compress),
                    ),
                    const Gap(12),
                    _ModeCard(
                      icon: Icons.photo_size_select_large_rounded,
                      accentColor: AppColors.resize,
                      title: 'Resize',
                      subtitle: 'Change dimensions by pixels or percentage',
                      tag: 'px · % · cm · mm',
                      onTap: () => _navigate(context, ImageMode.resize),
                    ),
                    const Gap(12),
                    _ModeCard(
                      icon: Icons.swap_horiz_rounded,
                      accentColor: AppColors.convert,
                      title: 'Convert',
                      subtitle: 'Change image format instantly',
                      tag: 'JPG → PNG · PNG → WEBP · any format',
                      onTap: () => _navigate(context, ImageMode.convert),
                    ),
                    const Gap(12),
                    _ModeCard(
                      icon: Icons.photo_library_outlined,
                      accentColor: AppColors.batch,
                      title: 'Batch',
                      subtitle: 'Process multiple images with shared settings',
                      tag: 'Compress · Resize',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const BatchEntryScreen()),
                      ),
                    ),
                    const Gap(20),
                    AdManager.instance.getMediumNativeAdWidget(),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, ImageMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ModeEntryScreen(mode: mode)),
    );
  }
}

// ─── Mode card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.surfaceBorder : AppColors.lightSurfaceBorder;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.accentColor.withOpacity(isDark ? 0.06 : 0.04)
              : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _pressed ? widget.accentColor.withOpacity(0.35) : border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 3,
              height: 80,
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            const Gap(16),
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                widget.icon,
                color: widget.accentColor,
                size: 22,
              ),
            ),
            const Gap(14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Gap(3),
                  Text(widget.subtitle, style: tt.bodyMedium),
                  const Gap(6),
                  Text(
                    widget.tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.accentColor.withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}

// ─── Pro badge ────────────────────────────────────────────────────────────────

class _ProBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _ProBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.35),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 13, color: Color(0xFFFFD700)),
            Gap(5),
            Text(
              'Pro',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.compress.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.compress.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 13, color: AppColors.compress),
          const Gap(5),
          Text(
            'Pro',
            style: TextStyle(
              color: AppColors.compress,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

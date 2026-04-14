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
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text('Pixel Forge', style: tt.headlineLarge),
                  ),
                  if (!AdManager.instance.isPro)
                    _ProBadge(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PaywallScreen()),
                      ),
                    )
                  else
                    _ActiveProBadge(),
                  const Gap(4),
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

            const Gap(6),

            // ── Subtitle ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: Text(
                'What would you like to do?',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),

            const Gap(24),

            // ── Mode cards ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    _ModeCard(
                      icon: Icons.compress_rounded,
                      accentColor: AppColors.compress,
                      title: 'Compress',
                      subtitle: 'Reduce file size without losing quality',
                      formats: const ['JPG', 'PNG', 'WEBP'],
                      onTap: () => _navigate(context, ImageMode.compress),
                    ),
                    const Gap(10),
                    _ModeCard(
                      icon: Icons.photo_size_select_large_rounded,
                      accentColor: AppColors.resize,
                      title: 'Resize',
                      subtitle: 'Change dimensions by pixels or percentage',
                      formats: const ['px', '%'],
                      onTap: () => _navigate(context, ImageMode.resize),
                    ),
                    const Gap(10),
                    _ModeCard(
                      icon: Icons.swap_horiz_rounded,
                      accentColor: AppColors.convert,
                      title: 'Convert',
                      subtitle: 'Change image format instantly',
                      formats: const ['JPG', 'PNG', 'WEBP', 'GIF'],
                      onTap: () => _navigate(context, ImageMode.convert),
                    ),
                    const Gap(10),
                    _ModeCard(
                      icon: Icons.photo_library_outlined,
                      accentColor: AppColors.batch,
                      title: 'Batch',
                      subtitle: 'Process multiple images at once',
                      formats: const ['Compress', 'Resize'],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const BatchEntryScreen()),
                      ),
                    ),
                    const Gap(24),
                    AdManager.instance.getMediumNativeAdWidget(),
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

// ── Mode card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final List<String> formats;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.formats,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.982 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.accentColor.withOpacity(0.05)
              : cs.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed
                ? widget.accentColor.withOpacity(0.4)
                : cs.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon box
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                widget.icon,
                color: widget.accentColor,
                size: 22,
              ),
            ),
            const Gap(16),
            // Text + chips
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
                  Text(
                    widget.subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Gap(10),
                  // Format chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.formats.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.accentColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Gap(10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pro badge ─────────────────────────────────────────────────────────────

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
        border: Border.all(color: AppColors.compress.withOpacity(0.3)),
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

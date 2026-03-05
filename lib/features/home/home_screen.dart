import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/ad_manager.dart';
import '../../features/premium/paywall_screen.dart';
import '../batch/batch_screen.dart';
import '../picker/picker_screen.dart';

enum ImageMode { compress, resize }

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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pixel Forge', style: tt.headlineLarge),
                      const Gap(4),
                      Text('What do you want to do?',
                          style: tt.bodyMedium),
                    ],
                  ),
                  Row(
                    children: [
                      if (!AdManager.instance.isPro)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PaywallScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFA000)
                              ]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    size: 13, color: Colors.black87),
                                SizedBox(width: 4),
                                Text('Pro',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF4ADE80),
                              Color(0xFF22C55E)
                            ]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Pro',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      const Gap(10),
                      GestureDetector(
                        onTap: () => ref.read(themeProvider.notifier).state =
                            !isDark,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 52,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark
                                ? cs.primary.withOpacity(0.25)
                                : cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: isDark
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                size: 20,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(36),

              // ── Single-image section label ─────────────────────────────
              _SectionLabel(
                icon: Icons.image_rounded,
                label: 'Single Image',
              ),
              const Gap(12),

              _ModeCard(
                icon: Icons.compress_rounded,
                title: 'Compress',
                subtitle: 'Reduce file size while keeping quality',
                gradient: [
                  const Color(0xFF6C63FF),
                  const Color(0xFF9D97FF)
                ],
                onTap: () => _navigate(context, ImageMode.compress),
              ),
              const Gap(12),
              _ModeCard(
                icon: Icons.photo_size_select_large_rounded,
                title: 'Resize',
                subtitle: 'Change dimensions by pixels or percentage',
                gradient: [
                  const Color(0xFF11998E),
                  const Color(0xFF38EF7D)
                ],
                onTap: () => _navigate(context, ImageMode.resize),
              ),

              const Gap(24),

              // ── Batch section label ───────────────────────────────────
              _SectionLabel(
                icon: Icons.photo_library_rounded,
                label: 'Batch Processing',
                badge: 'NEW',
              ),
              const Gap(12),

              _ModeCard(
                icon: Icons.layers_rounded,
                title: 'Batch Compress',
                subtitle: 'Compress multiple images at the same time',
                gradient: [
                  const Color(0xFFE040FB),
                  const Color(0xFFFF80AB)
                ],
                onTap: () => _navigateBatch(context, ImageMode.compress),
              ),
              const Gap(12),
              _ModeCard(
                icon: Icons.grid_view_rounded,
                title: 'Batch Resize',
                subtitle:
                    'Resize multiple images with the same settings',
                gradient: [
                  const Color(0xFFFF6D00),
                  const Color(0xFFFFAB40)
                ],
                onTap: () => _navigateBatch(context, ImageMode.resize),
              ),

              const Gap(16),

              // ── Ad ────────────────────────────────────────────────────
              AdManager.instance.getMediumNativeAdWidget(),

              const Gap(16),

              // ── Footer ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color),
                  const Gap(6),
                  Text(
                    'Fully offline \u00b7 No data leaves your device',
                    style:
                        Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, ImageMode mode) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PickerScreen(mode: mode)));
  }

  void _navigateBatch(BuildContext context, ImageMode mode) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BatchScreen(mode: mode)));
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  const _SectionLabel(
      {required this.icon, required this.label, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: Theme.of(context).textTheme.bodySmall?.color),
        const Gap(6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        if (badge != null) ...[
          const Gap(8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Mode card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0]
                    .withOpacity(isDark ? 0.35 : 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon,
                    color: Colors.white, size: 28),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3)),
                    const Gap(3),
                    Text(widget.subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

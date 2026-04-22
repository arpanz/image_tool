import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/utils/app_update_service.dart';
import '../../features/premium/paywall_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../batch/batch_entry_screen.dart';
import '../convert/convert_screen.dart';
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

    final tiles = <_ModeGridTileData>[
      _ModeGridTileData(
        icon: Icons.compress_rounded,
        accentColor: AppColors.compress,
        title: 'Compress',
        subtitle: 'Shrink file size',
        onTap: () => _navigateMode(context, ImageMode.compress),
      ),
      _ModeGridTileData(
        icon: Icons.photo_size_select_large_rounded,
        accentColor: AppColors.resize,
        title: 'Resize',
        subtitle: 'Change dimensions',
        onTap: () => _navigateMode(context, ImageMode.resize),
      ),
      _ModeGridTileData(
        icon: Icons.swap_horiz_rounded,
        accentColor: AppColors.convert,
        title: 'Convert',
        subtitle: 'Change format',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConvertScreen()),
        ),
      ),
      _ModeGridTileData(
        icon: Icons.photo_library_outlined,
        accentColor: AppColors.batch,
        title: 'Batch',
        subtitle: 'Process many files',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BatchEntryScreen()),
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Image Resizer',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!AdManager.instance.isPro)
                    _ProBadge(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      ),
                    )
                  else
                    _ActiveProBadge(),
                  const Gap(8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings_rounded),
                      iconSize: 24,
                      color: cs.onSurfaceVariant,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Text(
                'What would you like to edit today?',
                style: tt.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const Gap(24),
              GridView.builder(
                shrinkWrap: true,
                itemCount: tiles.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) =>
                    _ModeGridTile(data: tiles[index]),
              ),
              const Gap(16),
              AdManager.instance.getMediumNativeAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateMode(BuildContext context, ImageMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ModeEntryScreen(mode: mode)),
    );
  }
}

class _ModeGridTileData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeGridTileData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ModeGridTile extends StatelessWidget {
  final _ModeGridTileData data;

  const _ModeGridTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: data.accentColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.accentColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: data.onTap,
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const Gap(4),
                Text(
                  data.subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFF5B041)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 14, color: Color(0xFF6B4C0A)),
            Gap(4),
            Text(
              'PRO',
              style: TextStyle(
                color: Color(0xFF6B4C0A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
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
        color: AppColors.compress.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.compress.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.compress),
          const Gap(4),
          Text(
            'PRO',
            style: TextStyle(
              color: AppColors.compress,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}


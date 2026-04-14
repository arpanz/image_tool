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
    final gridHeight = MediaQuery.of(context).size.width - 24;

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
                children: [
                  Expanded(
                    child: Text('Pixel Forge', style: tt.headlineLarge),
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
                  const Gap(6),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    iconSize: 22,
                    color: cs.onSurfaceVariant,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Gap(4),
              Text(
                'Simple tools for everyday image edits',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Gap(16),
              SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  itemCount: tiles.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.03,
                  ),
                  itemBuilder: (context, index) =>
                      _ModeGridTile(data: tiles[index]),
                ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: data.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.32),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.accentColor,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(4),
              Text(
                data.subtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
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
          Icon(Icons.check_circle_rounded, size: 13, color: AppColors.compress),
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

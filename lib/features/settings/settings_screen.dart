import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.openStoreListing();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out Pixel Forge — compress & resize images offline!\n\n${AdManager.appStoreUrl}',
      ),
    );
  }

  void _showProFeaturesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'Your Pro Features',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Gap(20),
              _ProFeatureRow(
                icon: Icons.block,
                color: Colors.redAccent,
                label: 'Ad-Free Experience',
                description: 'No ads, zero interruptions',
              ),
              const Gap(12),
              _ProFeatureRow(
                icon: Icons.compress_rounded,
                color: AppColors.compress,
                label: 'Unlimited Compression',
                description: 'No daily limits on batch compression',
              ),
              const Gap(12),
              _ProFeatureRow(
                icon: Icons.photo_size_select_large_rounded,
                color: AppColors.resize,
                label: 'Unlimited Resize',
                description: 'Resize as many images as you need',
              ),
              const Gap(12),
              _ProFeatureRow(
                icon: Icons.high_quality_rounded,
                color: Colors.teal,
                label: 'Full Quality Control',
                description: 'Export at any quality level, 1–100',
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final packageInfoFuture = PackageInfo.fromPlatform();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── App identity header ────────────────────────────────────────────
          _AppHeader(
            isPro: AdManager.instance.isPro,
            packageInfoFuture: packageInfoFuture,
          ),
          const Gap(20),

          // ── Premium ─────────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Premium',
            icon: Icons.workspace_premium_rounded,
            children: [
              AdManager.instance.isPro
                  ? _ProActiveTile(
                      onTap: () => _showProFeaturesSheet(context),
                    )
                  : _UpgradeTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      ),
                    ),
            ],
          ),
          const Gap(16),

          // ── Appearance ──────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ThemeChip(
                        label: 'Light',
                        icon: Icons.light_mode_rounded,
                        selected: !isDark,
                        onSelected: (_) =>
                            ref.read(themeProvider.notifier).state = false,
                      ),
                      _ThemeChip(
                        label: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        selected: isDark,
                        onSelected: (_) =>
                            ref.read(themeProvider.notifier).state = true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),

          // ── Support ──────────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Support',
            icon: Icons.favorite_border_rounded,
            children: [
              _SettingsTile(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                title: 'Rate on Play Store',
                subtitle: 'Show your support',
                onTap: _rateApp,
              ),
              _SettingsTile(
                icon: Icons.share_rounded,
                iconColor: Colors.pink,
                title: 'Share App',
                subtitle: 'Spread the word',
                onTap: _shareApp,
              ),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.resize,
                title: 'Contact Us',
                subtitle: 'Questions or feedback',
                showDivider: false,
                onTap: () => _launchUrl(
                  'mailto:connect.livinlabs@gmail.com?subject=Pixel%20Forge%20Support',
                ),
              ),
            ],
          ),
          const Gap(16),

          // ── Legal ───────────────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Legal',
            icon: Icons.gavel_rounded,
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.compress,
                title: 'Privacy Policy',
                onTap: () => _launchUrl(
                  'https://livinlabs.com/privacy',
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: Colors.purple,
                title: 'Terms of Service',
                showDivider: false,
                onTap: () => _launchUrl(
                  'https://livinlabs.com/terms',
                ),
              ),
            ],
          ),
          const Gap(32),

          // ── Footer ────────────────────────────────────────────────────────────
          Center(
            child: Text(
              'Made with \u2764 by LivinLabs',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App header ────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final bool isPro;
  final Future<PackageInfo> packageInfoFuture;

  const _AppHeader({
    required this.isPro,
    required this.packageInfoFuture,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.compress.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.compress.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.photo_filter_rounded,
              color: AppColors.compress,
              size: 36,
            ),
          ),
          const Gap(12),
          // App name + pro badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pixel Forge',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (isPro) ...[
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Gap(4),
          FutureBuilder<PackageInfo>(
            future: packageInfoFuture,
            builder: (ctx, snap) => Text(
              snap.hasData ? 'Version ${snap.data!.version}' : '\u2026',
              style: tt.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings group ──────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: cs.primary.withOpacity(0.65)),
                const Gap(5),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary.withOpacity(0.65),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── Settings tile ──────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsTile({
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: icon != null
              ? _SettingsIcon(
                  icon: icon!,
                  color: iconColor ?? cs.primary,
                )
              : null,
          title: Text(
            title,
            style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: tt.bodySmall,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: cs.onSurfaceVariant.withOpacity(0.45),
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: cs.outlineVariant.withOpacity(0.2),
          ),
      ],
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ─── Theme chip ────────────────────────────────────────────────────────────────

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.black : cs.onSurfaceVariant,
      ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHighest.withOpacity(0.4),
      labelStyle: TextStyle(
        color: selected ? Colors.black : cs.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.4),
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }
}

// ─── Pro active tile ─────────────────────────────────────────────────────────

class _ProActiveTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ProActiveTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: gold, size: 18),
            ),
            const Gap(12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro Active',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Gap(2),
                  Text('All features unlocked \u00b7 Thank you!',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade400, size: 12),
                  const Gap(4),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upgrade tile ─────────────────────────────────────────────────────────────

class _UpgradeTile extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: gold, size: 18),
            ),
            const Gap(12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Pro',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Gap(2),
                  Text('No Ads \u00b7 Unlimited \u00b7 All Pro Tools',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'GET PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pro feature row (bottom sheet) ────────────────────────────────────────────

class _ProFeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;

  const _ProFeatureRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(description,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55))),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: Colors.green.shade400, size: 16),
      ],
    );
  }
}

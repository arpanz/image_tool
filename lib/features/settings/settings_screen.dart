import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/ad_manager.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.openStoreListing();
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showProFeaturesSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
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
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Color(0xFFFFD700),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Pro Features',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProFeatureRow(
                  icon: Icons.compress_rounded,
                  color: Colors.deepPurple,
                  label: 'Unlimited Compression',
                  description: 'Compress any number of images, no daily caps',
                ),
                const SizedBox(height: 12),
                _ProFeatureRow(
                  icon: Icons.photo_size_select_large_rounded,
                  color: Colors.teal,
                  label: 'Unlimited Resizing',
                  description: 'Resize to exact pixels or percentage freely',
                ),
                const SizedBox(height: 12),
                _ProFeatureRow(
                  icon: Icons.layers_rounded,
                  color: Colors.orange,
                  label: 'Batch Processing',
                  description: 'Process entire folders at once',
                ),
                const SizedBox(height: 12),
                _ProFeatureRow(
                  icon: Icons.high_quality_rounded,
                  color: Colors.blue,
                  label: 'Lossless Quality',
                  description: 'Export at maximum quality with no compression artefacts',
                ),
                const SizedBox(height: 12),
                _ProFeatureRow(
                  icon: Icons.block,
                  color: Colors.redAccent,
                  label: 'Ad-Free Experience',
                  description: 'No ads, zero interruptions – thank you for your support!',
                ),
                const SizedBox(height: 20),
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
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // ── App Identity Header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withOpacity(0.28),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pixel Forge',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (AdManager.instance.isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFFFD700).withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Image Resizer & Compressor',
                  style: TextStyle(
                    color:
                        theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Premium ──────────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Premium',
            icon: Icons.workspace_premium_rounded,
            children: [
              AdManager.instance.isPro
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: _ProChip(
                          onTap: () => _showProFeaturesSheet(context)),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: _UpgradeChip(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaywallScreen(),
                            ),
                          ).then((_) {
                            (context as Element).markNeedsBuild();
                          });
                        },
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Appearance ───────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
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
                            ref.read(themeProvider.notifier).setDark(false),
                      ),
                      _ThemeChip(
                        label: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        selected: isDark,
                        onSelected: (_) =>
                            ref.read(themeProvider.notifier).setDark(true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Our Other Apps ───────────────────────────────────────────────
          _SettingsGroup(
            title: 'Our Other Apps',
            icon: Icons.apps_rounded,
            children: [
              _SettingsTile(
                icon: Icons.table_chart_outlined,
                iconColor: Colors.green,
                title: 'CSV Viewer & Editor',
                subtitle: 'Our companion CSV toolkit',
                onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.livinlabs.csvviewer',
                ),
              ),
              _SettingsTile(
                icon: Icons.data_object_rounded,
                iconColor: Colors.orange,
                title: 'JSON Editor & Viewer Pro',
                subtitle: 'Our companion JSON toolkit',
                showDivider: false,
                onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.livinlabs.jsonforge',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Check out Pixel Forge – the best offline image resizer & compressor!\n\nhttps://play.google.com/store/apps/details?id=com.livinlabs.pixelforge',
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: Colors.blue,
                title: 'Contact Us',
                subtitle: 'Questions or feedback',
                showDivider: false,
                onTap: () => _launchUrl(
                  'mailto:connect.livinlabs@gmail.com?subject=Pixel%20Forge%20Support',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Legal ────────────────────────────────────────────────────────
          _SettingsGroup(
            title: 'Legal',
            icon: Icons.gavel_rounded,
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.green,
                title: 'Privacy Policy',
                showDivider: false,
                onTap: () => _launchUrl(
                  'https://livinlabs.com/privacy',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Footer ───────────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Made with \u2764 by LivinLabs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme ChoiceChip ─────────────────────────────────────────────────────────

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
        color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.55),
      ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
      labelStyle: TextStyle(
        color: selected ? cs.onPrimary : cs.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? cs.primary
              : cs.outlineVariant.withOpacity(0.5),
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }
}

// ── Premium chips ────────────────────────────────────────────────────────────

class _ProChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ProChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: goldColor.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: goldColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'All features unlocked · Thank you!',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade400, size: 12),
                  const SizedBox(width: 4),
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

class _UpgradeChip extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    const bgColor = Color(0xFF1A1D2E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: goldColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: goldColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: goldColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'No Ads · Unlimited Processing · All Pro Tools',
                    style: TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: goldColor,
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

// ── Pro feature row (used in bottom sheet) ───────────────────────────────────

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
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.green, size: 18),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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
                Icon(icon, size: 15, color: cs.primary.withOpacity(0.62)),
                const SizedBox(width: 6),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary.withOpacity(0.62),
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? customLeading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsTile({
    this.icon,
    this.iconColor,
    this.customLeading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: customLeading ??
              (icon != null
                  ? _SettingsIcon(
                      icon: icon!, color: iconColor ?? cs.primary)
                  : null),
          title: Text(
            title,
            style:
                textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: cs.onSurfaceVariant.withOpacity(0.50),
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: cs.outlineVariant.withOpacity(0.15),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

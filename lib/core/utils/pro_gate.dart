import 'package:flutter/material.dart';
import 'ad_manager.dart';
import '../../features/premium/paywall_screen.dart';

/// Synchronous Pro-feature gate.
/// Returns true if user can proceed; false + shows upgrade dialog otherwise.
class ProGate {
  static bool guard(BuildContext context, ProFeature feature) {
    if (AdManager.instance.isPro) return true;
    _showUpgradeDialog(context, feature);
    return false;
  }

  static void _showUpgradeDialog(BuildContext context, ProFeature feature) {
    final info = _featureInfo[feature]!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pro gate',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
            scale: curved,
            child: FadeTransition(opacity: anim, child: child));
      },
      pageBuilder: (dialogCtx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: cs.outlineVariant.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Feature icon
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(info.icon, size: 30, color: info.color),
                  ),
                  const SizedBox(height: 16),

                  // PRO badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PRO FEATURE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(info.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),

                  // Body
                  Text(info.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 22),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen()),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Upgrade to Pro',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('One-time payment \u00b7 Offline & private',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Maybe later',
                        style: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.55),
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum ProFeature {
  unlimitedCompress,
  unlimitedResize,
  allFormats,
  removeAds,
}

class _FeatureInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _FeatureInfo(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});
}

const _featureInfo = <ProFeature, _FeatureInfo>{
  ProFeature.unlimitedCompress: _FeatureInfo(
    icon: Icons.compress_rounded,
    color: Color(0xFF6C63FF),
    title: 'Unlimited Compressions',
    body:
        'You\'ve hit today\'s free limit.\nUpgrade to Pro for unlimited compressions with no daily caps.',
  ),
  ProFeature.unlimitedResize: _FeatureInfo(
    icon: Icons.photo_size_select_large_rounded,
    color: Color(0xFF11998E),
    title: 'Unlimited Resizes',
    body:
        'You\'ve hit today\'s free limit.\nUpgrade to Pro for unlimited resizes and all fit modes.',
  ),
  ProFeature.allFormats: _FeatureInfo(
    icon: Icons.auto_fix_high_rounded,
    color: Colors.orangeAccent,
    title: 'All Output Formats',
    body:
        'JPG, PNG and WebP exports are all unlocked in Pro. No format is locked away.',
  ),
  ProFeature.removeAds: _FeatureInfo(
    icon: Icons.block_flipped,
    color: Color(0xFFFF6B6B),
    title: 'Go Completely Ad-Free',
    body:
        'Remove every banner and interstitial ad with a single one-time Pro upgrade.',
  ),
};

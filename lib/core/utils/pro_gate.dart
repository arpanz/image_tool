import 'package:flutter/material.dart';
import 'ad_manager.dart';
import '../../features/premium/paywall_screen.dart';

/// Synchronous Pro-feature guard.
/// Returns true if allowed; otherwise shows upgrade prompt and returns false.
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
      transitionDuration: const Duration(milliseconds: 300),
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
                    Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(info.icon, size: 32, color: info.color),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('PRO FEATURE',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 14),
                  Text(info.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(info.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant, height: 1.45)),
                  const SizedBox(height: 22),
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
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
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
                  Text('One-time payment \u00b7 Lifetime access',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.72),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Maybe later',
                        style: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.6),
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
    color: Colors.blueAccent,
    title: 'Unlimited Compressions',
    body:
        'You\'ve hit the free daily limit.\nUpgrade to Pro for unlimited compressions with no caps.',
  ),
  ProFeature.unlimitedResize: _FeatureInfo(
    icon: Icons.photo_size_select_large_rounded,
    color: Colors.purpleAccent,
    title: 'Unlimited Resizes',
    body:
        'You\'ve hit the free daily limit.\nUpgrade to Pro for unlimited resizes and all fit modes.',
  ),
  ProFeature.removeAds: _FeatureInfo(
    icon: Icons.block_flipped,
    color: Color(0xFFFF6B6B),
    title: 'Go Ad-Free',
    body: 'Remove all ads and banners permanently with a one-time Pro upgrade.',
  ),
};

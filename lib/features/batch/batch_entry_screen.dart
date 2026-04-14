import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ad_manager.dart';
import '../home/home_screen.dart';
import 'batch_screen.dart';

/// Entry point for Batch mode. User picks Compress or Resize,
/// then lands on the existing BatchScreen with the chosen mode.
class BatchEntryScreen extends StatelessWidget {
  const BatchEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Batch'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.batch.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.batch,
                      size: 26,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Process',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Process multiple images simultaneously',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(36),

              // ── Mode label ─────────────────────────────────────────────────
              Text(
                'CHOOSE OPERATION',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const Gap(12),

              // ── Mode cards ─────────────────────────────────────────────────
              _BatchModeCard(
                icon: Icons.compress_rounded,
                accentColor: AppColors.compress,
                title: 'Compress',
                subtitle: 'Shrink file size of multiple images',
                tag: 'JPG · PNG · WEBP',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BatchScreen(mode: ImageMode.compress),
                  ),
                ),
              ),
              const Gap(16),
              _BatchModeCard(
                icon: Icons.photo_size_select_large_rounded,
                accentColor: AppColors.resize,
                title: 'Resize',
                subtitle: 'Change dimensions of multiple images',
                tag: 'Pixels · Percentage',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BatchScreen(mode: ImageMode.resize),
                  ),
                ),
              ),

              const Gap(36),

              // ── Ad + footer ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const Gap(6),
                  Text(
                    'Offline & private processing',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(24),
              AdManager.instance.getMediumNativeAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Batch mode card ──────────────────────────────────────────────────────────

class _BatchModeCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  const _BatchModeCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  @override
  State<_BatchModeCard> createState() => _BatchModeCardState();
}

class _BatchModeCardState extends State<_BatchModeCard> {
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
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: _pressed ? widget.accentColor.withOpacity(0.5) : border,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 28),
            ),
            const Gap(16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    widget.subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

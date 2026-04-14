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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.surfaceBorder : AppColors.lightSurfaceBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Batch'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.batch.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.batch,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch Processing', style: tt.headlineMedium),
                        const Gap(2),
                        Text(
                          'Process multiple images with shared settings',
                          style: tt.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(28),

              // ── Mode label ─────────────────────────────────────────────────
              Text(
                'SELECT MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary.withOpacity(0.65),
                  letterSpacing: 0.8,
                ),
              ),
              const Gap(10),

              // ── Mode cards ─────────────────────────────────────────────────
              _BatchModeCard(
                icon: Icons.compress_rounded,
                accentColor: AppColors.compress,
                title: 'Batch Compress',
                subtitle: 'Reduce file size across multiple images',
                tag: 'JPG · PNG · WEBP',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BatchScreen(mode: ImageMode.compress),
                  ),
                ),
              ),
              const Gap(12),
              _BatchModeCard(
                icon: Icons.photo_size_select_large_rounded,
                accentColor: AppColors.resize,
                title: 'Batch Resize',
                subtitle: 'Apply same dimensions to multiple images',
                tag: 'Pixels · Percentage',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BatchScreen(mode: ImageMode.resize),
                  ),
                ),
              ),

              const Gap(20),

              // ── Feature chips ──────────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeatureChip(
                    icon: Icons.layers_rounded,
                    label: 'Multiple images',
                    surface: surface,
                    border: border,
                  ),
                  _FeatureChip(
                    icon: Icons.tune_rounded,
                    label: 'Shared settings',
                    surface: surface,
                    border: border,
                  ),
                  _FeatureChip(
                    icon: Icons.save_alt_rounded,
                    label: 'Save all at once',
                    surface: surface,
                    border: border,
                  ),
                ],
              ),

              const Spacer(),

              // ── Ad + footer ────────────────────────────────────────────────
              AdManager.instance.getSmallNativeAdWidget(),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  const Gap(6),
                  Text(
                    'Fully offline \u00b7 No data leaves your device',
                    style: tt.bodySmall,
                  ),
                ],
              ),
              const Gap(16),
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
    final border = isDark ? AppColors.surfaceBorder : AppColors.lightSurfaceBorder;
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
            color: _pressed
                ? widget.accentColor.withOpacity(0.35)
                : border,
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
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
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
              child: Icon(widget.icon, color: widget.accentColor, size: 22),
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

// ─── Feature chip ─────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color surface;
  final Color border;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.batch),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

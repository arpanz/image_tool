import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';
import '../utils/ad_manager.dart';
import '../utils/pro_gate.dart';
import '../providers/batch_usage_provider.dart';

class PieCounter extends ConsumerWidget {
  const PieCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageState = ref.watch(batchUsageProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate percentage remaining
    final double percent = usageState.remaining / 3.0; // maxFreeUses is 3
    final color = usageState.remaining == 0
        ? AppColors.error
        : (usageState.remaining == 1 ? Colors.orangeAccent : const Color(0xFF6C63FF));

    return InkWell(
      onTap: () => ProGate.guard(context, ProFeature.batchProcessing),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(18, 18),
              painter: PieChartPainter(
                percentage: percent,
                color: color,
                backgroundColor: isDark
                    ? Colors.white12
                    : Colors.black12,
              ),
            ),
            const Gap(6),
            Text(
              '${usageState.remaining}/3 left',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: usageState.remaining == 0 ? AppColors.error : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  PieChartPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    if (percentage > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      // Start from top (-pi / 2) and go clockwise (sweep angle = percentage * 2 * pi)
      canvas.drawArc(
        rect,
        -math.pi / 2,
        percentage * 2 * math.pi,
        true,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

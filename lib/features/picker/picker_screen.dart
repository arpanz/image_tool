import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/selected_image.dart';
import '../editor/editor_screen.dart';
import 'picker_controller.dart';

class PickerScreen extends ConsumerWidget {
  const PickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pickerProvider);
    final notifier = ref.read(pickerProvider.notifier);

    ref.listen<PickerState>(pickerProvider, (prev, next) {
      if (next is PickerLoaded) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditorScreen(image: next.image),
          ),
        );
      } else if (next is PickerError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compress & Resize',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Gap(4),
              Text(
                'Offline-first. Fast. No quality compromise.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(40),
              Expanded(
                child: _UploadZone(
                  isLoading: state is PickerLoading,
                  onTap: () => notifier.pickImage(),
                ),
              ),
              const Gap(24),
              _BottomHint(),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _UploadZone({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLoading
                ? AppColors.primary.withOpacity(0.6)
                : AppColors.primary.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.none, // we draw dashes manually below
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: isLoading
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.35),
          ),
          child: Center(
            child: isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                      const Gap(16),
                      Text(
                        'Loading image...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const Gap(16),
                      Text(
                        'Tap to select image',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 16),
                      ),
                      const Gap(8),
                      Text(
                        'JPG · PNG · WEBP supported',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    const radius = Radius.circular(16);
    final rect = RRect.fromLTRBR(0, 0, size.width, size.height, radius);
    final path = Path()..addRRect(rect);

    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = 0;
      while (dist < m.length) {
        final end = (dist + dashWidth).clamp(0, m.length);
        canvas.drawPath(
          m.extractPath(dist, end as double),
          paint,
        );
        dist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

class _BottomHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
        const Gap(6),
        Text(
          'Fully offline • No data leaves your device',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

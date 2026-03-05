import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.76),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compress with Control',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Gap(6),
                      Text(
                        'Pick an image to tune quality, dimensions and export format in one flow.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Gap(14),
                      Row(
                        children: const [
                          _InfoChip(
                              label: 'On-device only',
                              icon: Icons.lock_outline),
                          Gap(8),
                          _InfoChip(
                              label: 'JPG / PNG / WEBP',
                              icon: Icons.image_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                Expanded(
                  child: _UploadZone(
                    isLoading: state is PickerLoading,
                    onTap: () => notifier.pickImage(),
                  ),
                ),
                const Gap(16),
                Center(
                  child: Text(
                    'No files are uploaded anywhere.',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _UploadZone extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _UploadZone({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLoading ? AppColors.primary : AppColors.border,
              width: 1.6,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isLoading
                  ? Column(
                      key: const ValueKey('loading'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.8,
                        ),
                        const Gap(16),
                        Text(
                          'Loading image...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: AppGradients.button,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 38,
                            color: AppColors.background,
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'Tap to select image',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Gap(6),
                        Text(
                          'Best quality in, optimized image out.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const Gap(6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

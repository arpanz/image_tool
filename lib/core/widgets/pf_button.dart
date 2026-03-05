import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;

  const PfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final isSecondary = backgroundColor != null;
    final foreground =
        isSecondary ? AppColors.textPrimary : AppColors.background;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isSecondary ? null : AppGradients.button,
          color: isSecondary ? backgroundColor : null,
          borderRadius: BorderRadius.circular(14),
          border: isSecondary ? Border.all(color: AppColors.border) : null,
          boxShadow: isSecondary
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x3312D6A0),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
=======
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? cs.primary;
    final fg = backgroundColor != null ? (isDark ? Colors.white : AppColors.lightTextPrimary) : Colors.white;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        disabledBackgroundColor: cs.primary.withOpacity(0.4),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: fg,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: foreground,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8)
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}

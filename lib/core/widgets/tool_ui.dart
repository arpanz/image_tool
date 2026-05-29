import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../theme/app_theme.dart';

class ToolSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;

  const ToolSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 18,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = accent?.withOpacity(isDark ? 0.24 : 0.2) ??
        cs.outlineVariant.withOpacity(isDark ? 0.46 : 0.58);
    final fill = isDark
        ? Color.alphaBlend(
            Colors.white.withOpacity(0.035),
            cs.surface,
          )
        : Color.alphaBlend(
            cs.primary.withOpacity(0.018),
            cs.surface,
          );

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
            blurRadius: isDark ? 18 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ToolBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ToolBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const Gap(5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ToolSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color accent;

  const ToolSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final trackColor = value
        ? accent.withOpacity(enabled ? 0.22 : 0.12)
        : cs.surfaceContainerHighest.withOpacity(0.72);
    final borderColor = value
        ? accent.withOpacity(enabled ? 0.48 : 0.24)
        : cs.outlineVariant.withOpacity(0.55);

    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? accent : cs.onSurfaceVariant.withOpacity(0.65),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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

class ToolTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? suffixText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Color accent;

  const ToolTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.accent,
    this.hintText,
    this.suffixText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.035), cs.surface)
        : Color.alphaBlend(accent.withOpacity(0.018), cs.surface);

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      cursorColor: accent,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixText: suffixText,
        helperText: helperText,
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant.withOpacity(0.78),
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.42)),
        suffixStyle: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
        helperStyle: TextStyle(
          color: cs.onSurfaceVariant.withOpacity(0.66),
          fontWeight: FontWeight.w500,
        ),
        border: border(cs.outlineVariant.withOpacity(0.62)),
        enabledBorder: border(cs.outlineVariant.withOpacity(0.52)),
        focusedBorder: border(accent.withOpacity(0.86), 1.6),
      ),
    );
  }
}

class ToolSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final Color accent;
  final String? label;

  const ToolSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
    this.divisions,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inactive = cs.surfaceContainerHighest.withOpacity(0.78);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: inactive,
        disabledActiveTrackColor: accent.withOpacity(0.28),
        disabledInactiveTrackColor: inactive.withOpacity(0.62),
        thumbColor: accent,
        disabledThumbColor: cs.onSurfaceVariant.withOpacity(0.35),
        overlayColor: accent.withOpacity(0.14),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        valueIndicatorColor: accent,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}

class ToolPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  const ToolPresetChip({
    super.key,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accent ?? cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              color.withOpacity(0.035),
              cs.surfaceContainerHighest.withOpacity(0.68),
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.54)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class ToolSegment<T> {
  final T value;
  final String label;
  final IconData? icon;

  const ToolSegment({
    required this.value,
    required this.label,
    this.icon,
  });
}

class ToolSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<ToolSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final Color accent;

  const ToolSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((segment) {
          final active = segment.value == value;
          return GestureDetector(
            onTap: () => onChanged(segment.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.24),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segment.icon != null) ...[
                    Icon(
                      segment.icon,
                      size: 14,
                      color: active ? Colors.white : cs.onSurfaceVariant,
                    ),
                    const Gap(5),
                  ],
                  Text(
                    segment.label,
                    style: TextStyle(
                      color: active ? Colors.white : cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ToolProcessingOverlay extends StatefulWidget {
  final bool visible;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final double? progress;

  const ToolProcessingOverlay({
    super.key,
    required this.visible,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.progress,
  });

  @override
  State<ToolProcessingOverlay> createState() => _ToolProcessingOverlayState();
}

class _ToolProcessingOverlayState extends State<ToolProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          color: Colors.black.withOpacity(isDark ? 0.48 : 0.24),
          child: Center(
            child: Container(
              width: 260,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accent.withOpacity(isDark ? 0.26 : 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.42 : 0.16),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * math.pi * 2,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            widget.accent.withOpacity(0.1),
                            widget.accent,
                            widget.accent.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surface : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accent,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Gap(5),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.progress != null) ...[
                    const Gap(16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: widget.progress!.clamp(0, 1),
                        minHeight: 7,
                        backgroundColor:
                            cs.surfaceContainerHighest.withOpacity(0.7),
                        valueColor: AlwaysStoppedAnimation(widget.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

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

// ─────────────────────────────────────────────────────────────────────────────
// ToolSwitch — premium toggle with spring animation, glow, icon & haptics
// ─────────────────────────────────────────────────────────────────────────────

class ToolSwitch extends StatefulWidget {
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
  State<ToolSwitch> createState() => _ToolSwitchState();
}

class _ToolSwitchState extends State<ToolSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _position;
  late final Animation<double> _thumbScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.value ? 1.0 : 0.0,
    );
    _position = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _thumbScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(ToolSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    HapticFeedback.mediumImpact();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onChanged != null;

    return Semantics(
      toggled: widget.value,
      button: true,
      child: GestureDetector(
        onTap: enabled ? _toggle : null,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _position.value;
            final tClamped = t.clamp(
                0.0, 1.0); // easeOutBack overshoots; clamp for color lerps
            final trackColor = Color.lerp(
              isDark
                  ? Colors.white.withOpacity(0.10)
                  : cs.surfaceContainerHighest.withOpacity(0.72),
              widget.accent.withOpacity(enabled ? 0.22 : 0.12),
              tClamped,
            )!;
            final borderColor = Color.lerp(
              isDark
                  ? Colors.white.withOpacity(0.18)
                  : cs.outlineVariant.withOpacity(0.55),
              widget.accent.withOpacity(enabled ? 0.48 : 0.24),
              tClamped,
            )!;
            final thumbColor = Color.lerp(
              isDark
                  ? Colors.white.withOpacity(0.50)
                  : cs.onSurfaceVariant.withOpacity(0.55),
              widget.accent,
              tClamped,
            )!;

            return Container(
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  t,
                )!,
                child: Transform.scale(
                  scale: _thumbScale.value,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                      boxShadow: [
                        BoxShadow(
                          color: thumbColor.withOpacity(0.4 * tClamped),
                          blurRadius: 10 * tClamped,
                          spreadRadius: 1 * tClamped,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: tClamped > 0.5
                        ? Icon(
                            Icons.check_rounded,
                            size: 13,
                            color:
                                Colors.white.withOpacity((tClamped - 0.5) * 2),
                          )
                        : null,
                  ),
                ),
              ),
            );
          },
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

// ─────────────────────────────────────────────────────────────────────────────
// ToolSlider — custom painted slider with gradient track, glowing thumb,
//              and premium continuous haptic feedback on drag
// ─────────────────────────────────────────────────────────────────────────────

class ToolSlider extends StatefulWidget {
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
  State<ToolSlider> createState() => _ToolSliderState();
}

class _ToolSliderState extends State<ToolSlider>
    with SingleTickerProviderStateMixin {
  int? _lastHapticDivision;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onChangeStart(double v) {
    _lastHapticDivision = null;
    _glowCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onChanged(double v) {
    if (widget.onChanged == null) return;
    widget.onChanged!(v);

    // Premium continuous haptics — fire on each discrete division step
    if (widget.divisions != null) {
      final step =
          ((v - widget.min) / (widget.max - widget.min) * widget.divisions!)
              .round();
      if (step != _lastHapticDivision) {
        _lastHapticDivision = step;
        HapticFeedback.selectionClick();
      }
    } else {
      // For continuous sliders, fire haptics at ~2% intervals
      final pct = ((v - widget.min) / (widget.max - widget.min) * 50).round();
      if (pct != _lastHapticDivision) {
        _lastHapticDivision = pct;
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onChangeEnd(double v) {
    _lastHapticDivision = null;
    _glowCtrl.reverse();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glassmorphic translucent background for inactive pill track
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.accent,
            inactiveTrackColor: inactiveColor,
            disabledActiveTrackColor: widget.accent.withOpacity(0.28),
            disabledInactiveTrackColor: inactiveColor.withOpacity(0.62),
            thumbColor: widget.accent,
            disabledThumbColor: cs.onSurfaceVariant.withOpacity(0.35),
            overlayColor: widget.accent.withOpacity(0.0),
            trackHeight: 16,
            trackShape: _PremiumTrackShape(
              accent: widget.accent,
              glowIntensity: _glowAnim.value,
            ),
            thumbShape: _PremiumThumbShape(
              accent: widget.accent,
              glowIntensity: _glowAnim.value,
              isDark: isDark,
            ),
            valueIndicatorColor: widget.accent,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.label,
            onChanged: widget.onChanged != null ? _onChanged : null,
            onChangeStart: widget.onChanged != null ? _onChangeStart : null,
            onChangeEnd: widget.onChanged != null ? _onChangeEnd : null,
          ),
        );
      },
    );
  }
}

/// Custom rounded track with a subtle gradient on the active portion.
class _PremiumTrackShape extends RoundedRectSliderTrackShape {
  final Color accent;
  final double glowIntensity;

  const _PremiumTrackShape({required this.accent, required this.glowIntensity});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 16.0;
    final double trackLeft = offset.dx + 8;
    final double trackWidth = parentBox.size.width - 16;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final canvas = context.canvas;
    
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    
    final trackHeight = trackRect.height;
    final trackLeft = trackRect.left;
    final trackRight = trackRect.right;
    final trackTop = trackRect.top;
    final radius = Radius.circular(trackHeight / 2);

    // Inactive track
    final inactiveRect = RRect.fromLTRBAndCorners(
      trackLeft,
      trackTop,
      trackRight,
      trackTop + trackHeight,
      topLeft: radius,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;
    canvas.drawRRect(inactiveRect, inactivePaint);

    // Active track with gradient
    final activeWidth = (thumbCenter.dx - trackLeft).clamp(0.0, trackRight - trackLeft);
    final activeRect = RRect.fromLTRBAndCorners(
      trackLeft,
      trackTop,
      trackLeft + activeWidth,
      trackTop + trackHeight,
      topLeft: radius,
      bottomLeft: radius,
      topRight: activeWidth >= (trackRight - trackLeft - 4) ? radius : Radius.zero,
      bottomRight: activeWidth >= (trackRight - trackLeft - 4) ? radius : Radius.zero,
    );

    // Create a lighter version of accent for the gradient start
    final lighterAccent = Color.lerp(accent, Colors.white, 0.25)!;
    final activePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(trackLeft, trackTop),
        Offset(trackLeft + activeWidth, trackTop),
        [lighterAccent, accent],
      );
    canvas.drawRRect(activeRect, activePaint);

    // Subtle glow under the active track when dragging
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = accent.withOpacity(0.14 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(activeRect.inflate(1.5), glowPaint);
    }
  }
}

/// Custom thumb that draws an integrated flush handle inside the track.
class _PremiumThumbShape extends SliderComponentShape {
  final Color accent;
  final double glowIntensity;
  final bool isDark;

  const _PremiumThumbShape({
    required this.accent,
    required this.glowIntensity,
    required this.isDark,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(8); // Flush fit for 16px trackHeight

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Sleek vertical white pill inside the track (4px wide, 10px high)
    final handleWidth = 4.0;
    final handleHeight = 10.0;
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: handleWidth,
        height: handleHeight,
      ),
      const Radius.circular(2.0),
    );

    // Subtle drag glow around the vertical handle
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.25 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(handleRect.inflate(3), glowPaint);
    }

    // Drop shadow under the handle
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawRRect(handleRect.shift(const Offset(0.5, 0.5)), shadowPaint);

    // Draw the white capsule handle
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(handleRect, handlePaint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ToolPresetChip — scale-bounce micro-interaction with haptics
// ─────────────────────────────────────────────────────────────────────────────

class ToolPresetChip extends StatefulWidget {
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
  State<ToolPresetChip> createState() => _ToolPresetChipState();
}

class _ToolPresetChipState extends State<ToolPresetChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.accent ?? cs.primary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.alphaBlend(
                        color.withOpacity(0.08),
                        Colors.white.withOpacity(0.08),
                      ),
                      Color.alphaBlend(
                        color.withOpacity(0.04),
                        Colors.white.withOpacity(0.06),
                      ),
                    ]
                  : [
                      Color.alphaBlend(
                        color.withOpacity(0.04),
                        cs.surfaceContainerHighest.withOpacity(0.8),
                      ),
                      Color.alphaBlend(
                        color.withOpacity(0.02),
                        cs.surfaceContainerHighest.withOpacity(0.7),
                      ),
                    ],
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.14)
                  : color.withOpacity(0.14),
            ),
          ),
          child: Text(
            widget.label,
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

// ─────────────────────────────────────────────────────────────────────────────
// ToolSegmentedControl — animated sliding indicator with haptics
// ─────────────────────────────────────────────────────────────────────────────

class ToolSegmentedControl<T> extends StatefulWidget {
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
  State<ToolSegmentedControl<T>> createState() =>
      _ToolSegmentedControlState<T>();
}

class _ToolSegmentedControlState<T> extends State<ToolSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _slideAnim;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeIndex = _indexOf(widget.value);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnim = AlwaysStoppedAnimation(_activeIndex.toDouble());
  }

  @override
  void didUpdateWidget(ToolSegmentedControl<T> old) {
    super.didUpdateWidget(old);
    final newIndex = _indexOf(widget.value);
    if (newIndex != _activeIndex) {
      final oldIndex = _activeIndex;
      _activeIndex = newIndex;
      _slideAnim = Tween<double>(
        begin: oldIndex.toDouble(),
        end: newIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  int _indexOf(T value) {
    for (int i = 0; i < widget.segments.length; i++) {
      if (widget.segments[i].value == value) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.segments.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : cs.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.14)
              : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, _) {
              return Stack(
                children: [
                  // ── Sliding indicator ──
                  if (constraints.maxWidth > 0)
                    _SlidingIndicator(
                      slideValue: _slideAnim.value,
                      segmentCount: count,
                      accent: widget.accent,
                      isDark: isDark,
                      maxWidth: constraints.maxWidth,
                    ),
                  // ── Segment labels ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (i) {
                      final segment = widget.segments[i];
                      final active = segment.value == widget.value;
                      return GestureDetector(
                        onTap: () {
                          if (!active) {
                            HapticFeedback.selectionClick();
                            widget.onChanged(segment.value);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: active ? Colors.white : cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (segment.icon != null) ...[
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      segment.icon,
                                      key: ValueKey(active),
                                      size: 14,
                                      color: active
                                          ? Colors.white
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const Gap(5),
                                ],
                                Text(segment.label),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Animated indicator that slides behind the active segment.
class _SlidingIndicator extends StatelessWidget {
  final double slideValue;
  final int segmentCount;
  final Color accent;
  final bool isDark;
  final double maxWidth;

  const _SlidingIndicator({
    required this.slideValue,
    required this.segmentCount,
    required this.accent,
    required this.isDark,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (maxWidth <= 0 || segmentCount == 0) {
      return const SizedBox.shrink();
    }
    final segmentWidth = maxWidth / segmentCount;
    final left = slideValue * segmentWidth;

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: segmentWidth,
      child: Container(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// ToolChipSelector — generic chip selection list (e.g. for formats) with haptics
// ─────────────────────────────────────────────────────────────────────────────

class ToolChipSelector extends StatelessWidget {
  final String value;
  final List<String> options;
  final Color accent;
  final ValueChanged<String> onChanged;

  const ToolChipSelector({
    super.key,
    required this.value,
    required this.options,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        return _ToolSelectionChip(
          label: opt,
          isSelected: opt == value,
          accent: accent,
          onTap: () => onChanged(opt),
        );
      }).toList(),
    );
  }
}

class _ToolSelectionChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _ToolSelectionChip({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_ToolSelectionChip> createState() => _ToolSelectionChipState();
}

class _ToolSelectionChipState extends State<_ToolSelectionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : cs.surfaceContainerHighest.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : (isDark
                      ? Colors.white.withOpacity(0.14)
                      : cs.outlineVariant.withOpacity(0.4)),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(isDark ? 0.28 : 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withOpacity(0.7)
                      : cs.onSurfaceVariant),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class ToolExpandableCard extends StatefulWidget {
  final String title;
  final Widget child;
  final Color accent;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const ToolExpandableCard({
    super.key,
    required this.title,
    required this.child,
    required this.accent,
    this.isExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<ToolExpandableCard> createState() => _ToolExpandableCardState();
}

class _ToolExpandableCardState extends State<ToolExpandableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _iconTurns;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOutQuart));
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5).chain(CurveTween(curve: Curves.easeInOut)));
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ToolExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _handleTap();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolSurface(
      padding: EdgeInsets.zero,
      accent: widget.accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightFactor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

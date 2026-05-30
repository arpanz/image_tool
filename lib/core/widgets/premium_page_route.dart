import 'package:flutter/material.dart';

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final bool slideFromBottom;

  PremiumPageRoute({
    required this.child,
    this.slideFromBottom = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = Curves.easeOutQuart;

            // Very subtle slide translation for a premium look
            final slideTween = Tween<Offset>(
              begin: slideFromBottom
                  ? const Offset(0.0, 0.04)
                  : const Offset(0.04, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve));

            // Fade transition
            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: curve));

            // Extremely subtle scale transition (0.985 -> 1.0)
            final scaleTween = Tween<double>(
              begin: 0.985,
              end: 1.0,
            ).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: SlideTransition(
                  position: animation.drive(slideTween),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
        );
}

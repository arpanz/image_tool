import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_emoji/animated_emoji.dart';

class ReviewService {
  static const String _kActiveDaysKey = 'ir_active_use_days';
  static const String _kLastActiveDateKey = 'ir_last_active_date';
  static const String _kImagesProcessedKey = 'ir_images_processed_count';
  static const String _kReviewCompletedKey =
      'ir_review_completed'; // true = never ask again
  static const String _kCooldownUntilKey =
      'ir_review_cooldown_until'; // ms since epoch, don't ask before this

  // In-memory session guard: prevents multiple triggers per app session
  // and avoids redundant SharedPreferences lookups on every call.
  static bool _sessionPrompted = false;

  @visibleForTesting
  static void resetSessionPromptedForTesting() {
    _sessionPrompted = false;
  }

  // Call this on app initialization to track active days
  static Future<void> trackDailyLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';

      final lastActiveDate = prefs.getString(_kLastActiveDateKey);

      if (lastActiveDate != todayStr) {
        int activeDays = (prefs.getInt(_kActiveDaysKey) ?? 0) + 1;
        await prefs.setInt(_kActiveDaysKey, activeDays);
        await prefs.setString(_kLastActiveDateKey, todayStr);
      }
    } catch (_) {
      // Fail silently
    }
  }

  // Call this every time an image is successfully processed.
  // This is the primary engagement signal for a utility app.
  static Future<void> trackImageProcessed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kImagesProcessedKey) ?? 0) + 1;
      await prefs.setInt(_kImagesProcessedKey, count);
    } catch (_) {
      // Fail silently
    }
  }

  // Call at high-value moments:
  //   - After an image is successfully processed
  //   - After a successful export or share
  //   - After a search/filter returns results
  // Do NOT restrict to save/edit actions.
  static Future<void> triggerSuccessReview(BuildContext context) async {
    try {
      // Fast in-memory check before hitting disk
      if (_sessionPrompted) return;

      final prefs = await SharedPreferences.getInstance();

      // Permanent flag: user already said "Yes" and got the OS prompt
      final reviewCompleted = prefs.getBool(_kReviewCompletedKey) ?? false;
      if (reviewCompleted) {
        _sessionPrompted = true;
        return;
      }

      // Cooldown: check if we're still within a cooldown window
      final cooldownUntil = prefs.getInt(_kCooldownUntilKey) ?? 0;
      if (cooldownUntil > 0 &&
          DateTime.now().millisecondsSinceEpoch < cooldownUntil) {
        _sessionPrompted = true;
        return;
      }

      // Eligibility: qualify if 5+ images processed OR 2+ active days.
      // This handles two user types:
      //   - Power users who process many images in a single session
      //   - Casual users who return on different days
      final imagesProcessed = prefs.getInt(_kImagesProcessedKey) ?? 0;
      final activeDays = prefs.getInt(_kActiveDaysKey) ?? 0;
      if (imagesProcessed < 5 && activeDays < 2) return;

      final InAppReview inAppReview = InAppReview.instance;
      final isReviewAvailable = await inAppReview.isAvailable();

      if (!context.mounted) return;

      // Set the session flag BEFORE showing the dialog to prevent concurrent triggers
      _sessionPrompted = true;

      // Show Pre-Ask Dialog to filter out negative experiences privately
      final result = await _showPreAskDialog(context);

      if (result == null) {
        // Dismissed without choosing — 5-day cooldown
        final cooldownUntil = DateTime.now()
            .add(const Duration(days: 5))
            .millisecondsSinceEpoch;
        await prefs.setInt(_kCooldownUntilKey, cooldownUntil);
        return;
      }

      if (result == true) {
        // User is happy — mark permanently completed
        await prefs.setBool(_kReviewCompletedKey, true);
        // Let the OS decide to show the actual prompt
        if (isReviewAvailable) {
          await inAppReview.requestReview();
        }
        // Belt-and-suspenders: if the OS silently ate the prompt (quota exhausted),
        // give the user a direct link to the Play Store as a fallback.
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(_buildReviewSnackBar(context));
        }
      } else {
        // User said "Could be better" — 30-day cooldown, try again later
        final cooldownUntil = DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch;
        await prefs.setInt(_kCooldownUntilKey, cooldownUntil);
        if (context.mounted) {
          _showFeedbackRedirect(context);
        }
      }
    } catch (_) {
      // Fail silently
    }
  }

  /// Triggered immediately after a successful purchase.
  /// Bypasses eligibility, cooldown, and session guards — purchase is the
  /// highest-intent signal we have. Only the permanent [_kReviewCompletedKey]
  /// flag is respected (no point asking someone who already reviewed).
  static Future<void> triggerPostPurchaseReview(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewCompleted = prefs.getBool(_kReviewCompletedKey) ?? false;
      if (reviewCompleted) return;

      if (!context.mounted) return;

      final InAppReview inAppReview = InAppReview.instance;
      final isReviewAvailable = await inAppReview.isAvailable();

      if (!context.mounted) return;

      // Mark session as prompted so normal flow doesn't fire again.
      _sessionPrompted = true;

      final result = await _showPreAskDialog(context);

      if (result == true) {
        await prefs.setBool(_kReviewCompletedKey, true);
        if (isReviewAvailable) await inAppReview.requestReview();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(_buildReviewSnackBar(context));
        }
      } else if (result == false) {
        // "Could be better" after a purchase — short 7-day cooldown only.
        final cooldown = DateTime.now()
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch;
        await prefs.setInt(_kCooldownUntilKey, cooldown);
        if (context.mounted) _showFeedbackRedirect(context);
      }
      // Dismissed (null) — no cooldown; they just paid, we won't penalise them.
    } catch (_) {
      // Fail silently
    }
  }

  /// For testing only — shows the pre-ask dialog directly, bypassing all guards.
  static Future<void> showReviewDialogForTesting(BuildContext context) async {
    final result = await _showPreAskDialog(context);
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(_buildReviewSnackBar(context));
    } else if (result == false && context.mounted) {
      _showFeedbackRedirect(context);
    }
  }

  static SnackBar _buildReviewSnackBar(BuildContext context) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 8),
      content: Row(
        children: [
          const AnimatedEmoji(AnimatedEmojis.warmSmile, size: 40),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanks for the love! 💛',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 2),
                Text(
                  'Help us grow by rating the app',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              launchUrl(
                Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.livinlabs.imageresizer',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text(
              'RATE',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _showPreAskDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Review dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: math.min(MediaQuery.of(context).size.width - 48, 380),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.06),
                    blurRadius: 60,
                    spreadRadius: -10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decorative star row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final delay = index * 0.12;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                size: 28 + (index == 2 ? 8 : 0),
                                color: Color.lerp(
                                  colorScheme.primary.withOpacity(0.4),
                                  colorScheme.primary,
                                  value,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Animated sparkle icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primaryContainer.withOpacity(0.7),
                                colorScheme.primaryContainer.withOpacity(0.3),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const AnimatedEmoji(
                            AnimatedEmojis.warmSmile,
                            size: 44,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Enjoying Image Resizer?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'We hope it\'s making your photo workflow faster. How has your experience been?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      // Negative path
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            'Could be better',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Positive path
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Love it!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Maybe later',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _showFeedbackRedirect(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Feedback dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (dialogCtx, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: math.min(MediaQuery.of(context).size.width - 48, 380),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.secondaryContainer.withOpacity(0.7),
                                colorScheme.secondaryContainer.withOpacity(0.3),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.secondary.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: colorScheme.secondary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'We\'d love your thoughts',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Your feedback helps us build a better image resizer. Drop us a quick note — every bit helps!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          final emailUri = Uri.parse(
                            'mailto:connect.livinlabs@gmail.com?subject=Image%20Resizer%20Feedback&body=Hi%2C%20here%27s%20how%20I%20think%20the%20app%20could%20improve%3A%0A%0A',
                          );
                          try {
                            await launchUrl(emailUri);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: const Text(
                                    'Could not open email. Please reach us at connect.livinlabs@gmail.com',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        label: const Text(
                          'Share Feedback',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

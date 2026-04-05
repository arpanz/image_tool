import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static const _successCountKey = 'review_success_count';
  static const _promptCountKey = 'review_prompt_count';
  static const _lastPromptMsKey = 'review_last_prompt_ms';

  static const _minSuccessesBeforePrompt = 4;
  static const _cooldownDays = 21;
  static const _maxPrompts = 3;

  static bool _isPromptInProgress = false;

  static Future<void> registerSuccessfulAction() async {
    if (_isPromptInProgress) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final prefs = await SharedPreferences.getInstance();
    final successCount = (prefs.getInt(_successCountKey) ?? 0) + 1;
    await prefs.setInt(_successCountKey, successCount);

    final promptCount = prefs.getInt(_promptCountKey) ?? 0;
    if (promptCount >= _maxPrompts) return;
    if (successCount < _minSuccessesBeforePrompt) return;

    final lastPromptMs = prefs.getInt(_lastPromptMsKey) ?? 0;
    if (lastPromptMs > 0) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (DateTime.now().difference(lastPrompt).inDays < _cooldownDays) return;
    }

    final inAppReview = InAppReview.instance;
    if (!await inAppReview.isAvailable()) return;

    _isPromptInProgress = true;
    try {
      await inAppReview.requestReview();
      await prefs.setInt(_promptCountKey, promptCount + 1);
      await prefs.setInt(
        _lastPromptMsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt(_successCountKey, 0);
    } catch (e) {
      debugPrint('AppReviewService: review prompt failed: $e');
    } finally {
      _isPromptInProgress = false;
    }
  }
}

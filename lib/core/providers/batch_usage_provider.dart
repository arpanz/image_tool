import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_provider.dart'; // to reuse sharedPreferencesProvider
import '../utils/ad_manager.dart';

class BatchUsageState {
  final int usesToday;
  final int remaining;
  final bool isLimitReached;

  BatchUsageState({
    required this.usesToday,
    required this.remaining,
    required this.isLimitReached,
  });
}

class BatchUsageNotifier extends StateNotifier<BatchUsageState> {
  final SharedPreferences _prefs;
  static const _countKey = 'batch_use_count_today';
  static const _dateKey = 'batch_use_date_today';
  static const int maxFreeUses = 3;

  BatchUsageNotifier(this._prefs)
      : super(BatchUsageState(
            usesToday: 0, remaining: maxFreeUses, isLimitReached: false)) {
    _loadUsage();
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _loadUsage() {
    if (AdManager.instance.isPro) {
      state = BatchUsageState(
          usesToday: 0, remaining: maxFreeUses, isLimitReached: false);
      return;
    }

    final today = _getTodayString();
    final savedDate = _prefs.getString(_dateKey);
    int uses = 0;
    if (savedDate == today) {
      uses = _prefs.getInt(_countKey) ?? 0;
    }
    final remaining = (maxFreeUses - uses).clamp(0, maxFreeUses);
    state = BatchUsageState(
      usesToday: uses,
      remaining: remaining,
      isLimitReached: remaining <= 0,
    );
  }

  Future<bool> checkAndIncrement() async {
    _loadUsage();
    if (AdManager.instance.isPro) return true;

    if (state.isLimitReached) {
      return false;
    }

    final today = _getTodayString();
    final savedDate = _prefs.getString(_dateKey);
    int uses = 0;
    if (savedDate == today) {
      uses = _prefs.getInt(_countKey) ?? 0;
    } else {
      await _prefs.setString(_dateKey, today);
    }
    uses++;
    await _prefs.setInt(_countKey, uses);
    _loadUsage();
    return true;
  }
}

final batchUsageProvider =
    StateNotifierProvider<BatchUsageNotifier, BatchUsageState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BatchUsageNotifier(prefs);
});

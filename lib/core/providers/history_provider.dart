import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

class HistoryState {
  final bool isEnabled;
  final List<HistoryEntry> entries;

  HistoryState({
    required this.isEnabled,
    required this.entries,
  });

  HistoryState copyWith({
    bool? isEnabled,
    List<HistoryEntry>? entries,
  }) {
    return HistoryState(
      isEnabled: isEnabled ?? this.isEnabled,
      entries: entries ?? this.entries,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  static const String _toggleKey = 'history_enabled_toggle';

  final SharedPreferences _prefs;
  final Box _box;

  HistoryNotifier(this._prefs, this._box)
      : super(HistoryState(isEnabled: true, entries: [])) {
    _loadState();
  }

  void _loadState() {
    final isEnabled = _prefs.getBool(_toggleKey) ?? true;
    final List<HistoryEntry> loadedEntries = [];

    for (var key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        try {
          loadedEntries.add(HistoryEntry.fromJson(value));
        } catch (e) {
          // ignore malformed entries
        }
      }
    }

    // Sort entries by timestamp descending (newest first)
    loadedEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = HistoryState(
      isEnabled: isEnabled,
      entries: loadedEntries,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_toggleKey, enabled);
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> addEntry({
    required int originalSize,
    required int newSize,
    required double savedPercent,
    required String tempOutputPath,
    required int width,
    required int height,
    required String mode,
  }) async {
    if (!state.isEnabled) return;

    try {
      final tempFile = File(tempOutputPath);
      if (!tempFile.existsSync()) return;

      final appDocDir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${appDocDir.path}/history');
      if (!historyDir.existsSync()) {
        await historyDir.create(recursive: true);
      }

      // Extract filename with fallback for OS path separators
      final rawFileName = tempOutputPath.replaceAll('\\', '/').split('/').last;
      final fileName =
          'hist_${DateTime.now().millisecondsSinceEpoch}_$rawFileName';
      final persistentPath = '${historyDir.path}/$fileName';

      // Copy file to persistent location
      await tempFile.copy(persistentPath);

      final entry = HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        originalSize: originalSize,
        newSize: newSize,
        savedPercent: savedPercent,
        outputPath: persistentPath,
        width: width,
        height: height,
        mode: mode,
      );

      // Save to Hive
      await _box.put(entry.id, entry.toJson());

      // Update State
      final updatedList = List<HistoryEntry>.from(state.entries)
        ..insert(0, entry);
      state = state.copyWith(entries: updatedList);
    } catch (e) {
      // ignore errors gracefully
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final entry = state.entries.firstWhere((element) => element.id == id);

      // Delete file from local storage
      final file = File(entry.outputPath);
      if (file.existsSync()) {
        await file.delete();
      }

      // Delete from Hive
      await _box.delete(id);

      // Update State
      final updatedList =
          state.entries.where((element) => element.id != id).toList();
      state = state.copyWith(entries: updatedList);
    } catch (e) {
      // ignore errors gracefully
    }
  }

  Future<void> clearAll() async {
    try {
      // Delete all persistent files
      for (var entry in state.entries) {
        final file = File(entry.outputPath);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      // Clear Hive box
      await _box.clear();

      // Update State
      state = state.copyWith(entries: []);
    } catch (e) {
      // ignore errors gracefully
    }
  }

  // Storage calculations
  int get totalSavedBytes {
    int total = 0;
    for (var entry in state.entries) {
      if (entry.originalSize > entry.newSize) {
        total += (entry.originalSize - entry.newSize);
      }
    }
    return total;
  }

  int get totalDiskUsage {
    int total = 0;
    for (var entry in state.entries) {
      total += entry.newSize;
    }
    return total;
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final hiveBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError();
});

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final box = ref.watch(hiveBoxProvider);
  return HistoryNotifier(prefs, box);
});

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';
import '../utils/ad_manager.dart';

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

  Future<void> _enforceNonProLimit() async {
    if (AdManager.instance.isPro) return;

    final List<HistoryEntry> currentEntries = [];
    for (var key in _box.keys) {
      final val = _box.get(key);
      if (val is Map) {
        try {
          currentEntries.add(HistoryEntry.fromJson(val));
        } catch (_) {}
      }
    }

    // Sort oldest first
    currentEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // We are about to add 1 entry, so delete oldest if we currently have 3 or more
    while (currentEntries.length >= 3) {
      final oldest = currentEntries.removeAt(0);

      if (oldest.isBatch && oldest.batchItems != null) {
        for (var item in oldest.batchItems!) {
          final path = item['outputPath'] as String?;
          if (path != null) {
            final file = File(path);
            if (file.existsSync()) {
              await file.delete();
            }
          }
        }
      } else {
        final file = File(oldest.outputPath);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      await _box.delete(oldest.id);
    }
  }

  Future<void> addEntry({
    required int originalSize,
    required int newSize,
    required double savedPercent,
    required String tempOutputPath,
    required int width,
    required int height,
    required int originalWidth,
    required int originalHeight,
    required String originalFormat,
    required String newFormat,
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
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        originalFormat: originalFormat,
        newFormat: newFormat,
        mode: mode,
        isBatch: false,
      );

      // Enforce the 3-item limit for non-Pro users
      await _enforceNonProLimit();

      // Save to Hive
      await _box.put(entry.id, entry.toJson());

      // Update State (filter out deleted items)
      final updatedList = state.entries
          .where((e) => _box.containsKey(e.id))
          .toList()
        ..insert(0, entry);
      state = state.copyWith(entries: updatedList);
    } catch (e) {
      // ignore errors gracefully
    }
  }

  Future<void> addBatchEntry({
    required List<Map<String, dynamic>>
        rawItems, // contains outputPath, originalSize, newSize, width, height, originalWidth, originalHeight
    required String mode,
  }) async {
    if (!state.isEnabled) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${appDocDir.path}/history');
      if (!historyDir.existsSync()) {
        await historyDir.create(recursive: true);
      }

      final List<Map<String, dynamic>> savedBatchItems = [];
      int totalOriginalSize = 0;
      int totalNewSize = 0;

      for (var item in rawItems) {
        final tempPath = item['outputPath'] as String;
        final tempFile = File(tempPath);
        if (!tempFile.existsSync()) continue;

        final rawFileName = tempPath.replaceAll('\\', '/').split('/').last;
        final fileName =
            'hist_${DateTime.now().millisecondsSinceEpoch}_batch_$rawFileName';
        final persistentPath = '${historyDir.path}/$fileName';

        // Copy file to persistent location
        await tempFile.copy(persistentPath);

        totalOriginalSize += item['originalSize'] as int;
        totalNewSize += item['newSize'] as int;

        savedBatchItems.add({
          'outputPath': persistentPath,
          'originalSize': item['originalSize'],
          'newSize': item['newSize'],
          'width': item['width'],
          'height': item['height'],
          'originalWidth': item['originalWidth'] ?? 0,
          'originalHeight': item['originalHeight'] ?? 0,
        });
      }

      if (savedBatchItems.isEmpty) return;

      final double savedPercent = totalOriginalSize > 0
          ? ((totalOriginalSize - totalNewSize) / totalOriginalSize * 100)
          : 0.0;

      final entry = HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        originalSize: totalOriginalSize,
        newSize: totalNewSize,
        savedPercent: savedPercent,
        outputPath: savedBatchItems.first['outputPath'] as String,
        width: 0,
        height: 0,
        mode: mode,
        isBatch: true,
        batchItems: savedBatchItems,
      );

      // Enforce the 3-item limit for non-Pro users
      await _enforceNonProLimit();

      // Save to Hive
      await _box.put(entry.id, entry.toJson());

      // Update State (filter out deleted items)
      final updatedList = state.entries
          .where((e) => _box.containsKey(e.id))
          .toList()
        ..insert(0, entry);
      state = state.copyWith(entries: updatedList);
    } catch (e) {
      // ignore errors gracefully
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final entry = state.entries.firstWhere((element) => element.id == id);

      // Delete file(s) from local storage
      if (entry.isBatch && entry.batchItems != null) {
        for (var item in entry.batchItems!) {
          final path = item['outputPath'] as String?;
          if (path != null) {
            final file = File(path);
            if (file.existsSync()) {
              await file.delete();
            }
          }
        }
      } else {
        final file = File(entry.outputPath);
        if (file.existsSync()) {
          await file.delete();
        }
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
        if (entry.isBatch && entry.batchItems != null) {
          for (var item in entry.batchItems!) {
            final path = item['outputPath'] as String?;
            if (path != null) {
              final file = File(path);
              if (file.existsSync()) {
                await file.delete();
              }
            }
          }
        } else {
          final file = File(entry.outputPath);
          if (file.existsSync()) {
            await file.delete();
          }
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

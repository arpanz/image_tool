import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_provider.dart'; // to reuse sharedPreferencesProvider
import '../models/compression_settings.dart';

class DimensionPreset {
  final String label;
  final int width;
  final int height;

  const DimensionPreset({
    required this.label,
    required this.width,
    required this.height,
  });

  String get displayString => '$width × $height';
}

class RecentResizePreset {
  final int width;
  final int height;
  final bool keepAspectRatio;
  final ResizeFitMode fitMode;
  final int? backgroundColorHex;

  const RecentResizePreset({
    required this.width,
    required this.height,
    required this.keepAspectRatio,
    required this.fitMode,
    this.backgroundColorHex,
  });

  String get displayString => '$width × $height';

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'keepAspectRatio': keepAspectRatio,
        'fitMode': fitMode.name,
        if (backgroundColorHex != null)
          'backgroundColorHex': backgroundColorHex,
      };

  factory RecentResizePreset.fromJson(Map<String, dynamic> json) {
    return RecentResizePreset(
      width: json['width'] as int,
      height: json['height'] as int,
      keepAspectRatio: json['keepAspectRatio'] as bool? ?? true,
      fitMode: ResizeFitMode.values.firstWhere(
        (e) => e.name == json['fitMode'],
        orElse: () => ResizeFitMode.fit,
      ),
      backgroundColorHex: json['backgroundColorHex'] as int?,
    );
  }
}

class ResizePresetsNotifier extends StateNotifier<List<RecentResizePreset>> {
  final SharedPreferences _prefs;
  static const _key = 'recently_used_dimensions_v2';

  ResizePresetsNotifier(this._prefs) : super([]) {
    _loadPresets();
  }

  void _loadPresets() {
    final list = _prefs.getStringList(_key) ?? [];
    final loaded = list
        .map((item) {
          try {
            return RecentResizePreset.fromJson(
                jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentResizePreset>()
        .toList();
    state = loaded;
  }

  Future<void> addPreset({
    required int width,
    required int height,
    required bool keepAspectRatio,
    required ResizeFitMode fitMode,
    int? backgroundColorHex,
  }) async {
    if (width <= 0 || height <= 0) return;

    final newPreset = RecentResizePreset(
      width: width,
      height: height,
      keepAspectRatio: keepAspectRatio,
      fitMode: fitMode,
      backgroundColorHex: backgroundColorHex,
    );

    final current = List<RecentResizePreset>.from(state);

    // Remove duplicates comparing fields
    current.removeWhere((item) =>
        item.width == width &&
        item.height == height &&
        item.keepAspectRatio == keepAspectRatio &&
        item.fitMode == fitMode &&
        item.backgroundColorHex == backgroundColorHex);

    current.insert(0, newPreset);

    // Keep only last 3 items
    if (current.length > 3) {
      current.removeLast();
    }

    final serialized = current.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_key, serialized);
    state = current;
  }

  Future<void> clearPresets() async {
    await _prefs.remove(_key);
    state = [];
  }
}

final resizePresetsProvider =
    StateNotifierProvider<ResizePresetsNotifier, List<RecentResizePreset>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ResizePresetsNotifier(prefs);
});

const List<DimensionPreset> popularPresets = [
  DimensionPreset(label: 'Instagram Square', width: 1080, height: 1080),
  DimensionPreset(label: 'Instagram Story', width: 1080, height: 1920),
  DimensionPreset(label: 'YouTube Thumbnail', width: 1280, height: 720),
  DimensionPreset(label: 'Full HD (16:9)', width: 1920, height: 1080),
  DimensionPreset(label: 'A4 Print (300 dpi)', width: 2480, height: 3508),
];

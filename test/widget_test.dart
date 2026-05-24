// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import 'package:image_resizer/main.dart';
import 'package:image_resizer/core/providers/history_provider.dart';
import 'package:image_resizer/core/utils/ad_manager.dart';

class FakeHiveBox extends Fake implements Box {
  final Map<dynamic, dynamic> _map = {};

  @override
  Iterable<dynamic> get keys => _map.keys;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) => _map[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _map.remove(key);
  }

  @override
  Future<int> clear() async {
    final len = _map.length;
    _map.clear();
    return len;
  }

  @override
  bool containsKey(dynamic key) => _map.containsKey(key);

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('app shows the Image Resizer home screen',
      (WidgetTester tester) async {
    // Initialize SharedPreferences mock values
    SharedPreferences.setMockInitialValues({
      'onboarding_seen_v1': true,
      'is_premium_user': true,
    });
    final prefs = await SharedPreferences.getInstance();
    
    // Set AdManager premium state to disable ads and platform channel calls
    await AdManager.instance.enableProVersion();

    final fakeBox = FakeHiveBox();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          hiveBoxProvider.overrideWithValue(fakeBox),
        ],
        child: const ImageResizerApp(),
      ),
    );
    await tester.pump();
    await tester.idle();
    await tester.pump();

    expect(find.text('Image Resizer'), findsWidgets);
  });
}

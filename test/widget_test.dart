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

void main() {
  testWidgets('app shows the Image Resizer home screen',
      (WidgetTester tester) async {
    // Initialize SharedPreferences mock values
    SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
    final prefs = await SharedPreferences.getInstance();

    // Initialize Hive in a temporary directory for tests
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    final box = await Hive.openBox('image_history');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          hiveBoxProvider.overrideWithValue(box),
        ],
        child: const ImageResizerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Image Resizer'), findsWidgets);

    // Clean up temporary Hive files
    await box.close();
    tempDir.deleteSync(recursive: true);
  });
}

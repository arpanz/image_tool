import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_resizer/core/providers/batch_usage_provider.dart';
import 'package:image_resizer/core/utils/ad_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatchUsageNotifier Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // Reset premium state for testing using our test setter
      AdManager.instance.isProForTesting = false;
    });

    test('initial state when no uses registered', () {
      final notifier = BatchUsageNotifier(prefs);
      expect(notifier.state.usesToday, 0);
      expect(notifier.state.remaining, 3);
      expect(notifier.state.isLimitReached, isFalse);
    });

    test('increment usage updates state and shared preferences', () async {
      final notifier = BatchUsageNotifier(prefs);
      final success = await notifier.checkAndIncrement();
      expect(success, isTrue);
      expect(notifier.state.usesToday, 1);
      expect(notifier.state.remaining, 2);
      expect(notifier.state.isLimitReached, isFalse);

      final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      expect(prefs.getInt('batch_use_count_today'), 1);
      expect(prefs.getString('batch_use_date_today'), today);
    });

    test('reaches limit and blocks increments', () async {
      final notifier = BatchUsageNotifier(prefs);
      
      expect(await notifier.checkAndIncrement(), isTrue);
      expect(await notifier.checkAndIncrement(), isTrue);
      expect(await notifier.checkAndIncrement(), isTrue);
      
      expect(notifier.state.usesToday, 3);
      expect(notifier.state.remaining, 0);
      expect(notifier.state.isLimitReached, isTrue);

      // 4th increment should fail
      expect(await notifier.checkAndIncrement(), isFalse);
      expect(notifier.state.usesToday, 3);
    });

    test('Pro user has no limits', () async {
      AdManager.instance.isProForTesting = true;
      final notifier = BatchUsageNotifier(prefs);
      
      expect(notifier.state.usesToday, 0);
      // When pro, remaining is set to maxFreeUses (3) but isLimitReached is false and stays false
      expect(notifier.state.remaining, 3);
      expect(notifier.state.isLimitReached, isFalse);

      // Increment works even if called many times
      expect(await notifier.checkAndIncrement(), isTrue);
      expect(await notifier.checkAndIncrement(), isTrue);
      expect(await notifier.checkAndIncrement(), isTrue);
      expect(await notifier.checkAndIncrement(), isTrue);
      
      expect(notifier.state.usesToday, 0);
      expect(notifier.state.remaining, 3);
      expect(notifier.state.isLimitReached, isFalse);
    });
  });
}

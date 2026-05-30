import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/utils/ad_manager.dart';
import 'core/providers/history_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AdManager.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  final box = await Hive.openBox('image_history');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hiveBoxProvider.overrideWithValue(box),
      ],
      child: const ImageResizerApp(),
    ),
  );
}

class ImageResizerApp extends ConsumerWidget {
  const ImageResizerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Image Resizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _LaunchGate(),
    );
  }
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_isLoading) {
      child = Scaffold(
        key: const ValueKey('loading'),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    } else if (_showOnboarding) {
      child = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onCompleted: () {
          if (!mounted) return;
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    } else {
      child = const HomeScreen(key: ValueKey('home'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: child,
    );
  }

  Future<void> _checkOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(OnboardingScreen.seenKey) ?? false;

    if (!mounted) return;

    setState(() {
      _showOnboarding = !seen;
      _isLoading = false;
    });
  }
}

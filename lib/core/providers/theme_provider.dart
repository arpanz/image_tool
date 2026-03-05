import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
    (ref) => ThemeNotifier()); // true = dark

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true); // default: dark mode

  void toggle() => state = !state;

  void setDark(bool isDark) => state = isDark;
}

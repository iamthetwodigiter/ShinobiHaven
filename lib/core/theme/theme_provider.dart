import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  ThemeNotifier(this._ref) : super(_getInitialTheme());

  static ThemeMode _getInitialTheme() {
    final mode = UserBoxFunctions.darkModeState();
    if (mode == 0) return ThemeMode.light;
    if (mode == 1) return ThemeMode.dark;
    if (mode == 2) return ThemeMode.system;
    return ThemeMode.dark;
  }

  void setTheme(int mode) {
    UserBoxFunctions.toggleDarkMode(mode);
    if (mode == 0) {
      state = ThemeMode.light;
    } else if (mode == 1) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  void setAccentColor(Color accentColor) {
    UserBoxFunctions.setAccentColor(accentColor);
    _ref.read(accenetColorProvider.notifier).state = accentColor;
    state = state;
  }

  Color getAccentColor() {
    return _ref.read(accenetColorProvider);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  return ThemeNotifier(ref);
});

final accenetColorProvider = StateProvider<Color>(
  (ref) => UserBoxFunctions.getAccentColor(),
);

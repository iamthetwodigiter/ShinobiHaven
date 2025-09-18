import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_getInitialTheme());

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
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
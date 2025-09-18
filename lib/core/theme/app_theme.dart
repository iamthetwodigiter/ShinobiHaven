import 'package:flutter/material.dart';

class AppTheme {
  static const Color gradient1 = Color.fromARGB(255, 219, 45, 105);
  static const Color gradient2 = Color.fromARGB(255, 219, 55, 45);
  static const Color blackGradient = Color.fromARGB(255, 27, 25, 25);
  static const Color whiteGradient = Color.fromARGB(255, 239, 236, 236);

  static const Color greyGradient = Color.fromARGB(255, 84, 84, 84);
  static const Color primaryGreen = Colors.green;
  static const Color primaryBlack = Colors.black;
  static const Color primaryBlue = Colors.blue;
  static const Color primaryAmber = Colors.amber;
  static const Color transparentColor = Colors.transparent;

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: transparentColor,
    titleTextStyle: TextStyle(color: gradient1, fontSize: 22, fontFamily: 'SFPro'),
    iconTheme: IconThemeData(color: gradient1),
    toolbarHeight: 50,
  );

  static const ProgressIndicatorThemeData _progressIndicatorThemeData =
      ProgressIndicatorThemeData(color: AppTheme.gradient1);

  static const BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
        enableFeedback: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: gradient1,
        unselectedItemColor: greyGradient,
      );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryBlack,
    fontFamily: 'SFPro',
    appBarTheme: _appBarTheme,
    progressIndicatorTheme: _progressIndicatorThemeData,
    bottomNavigationBarTheme: _bottomNavigationBarTheme,
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: whiteGradient,
    fontFamily: 'SFPro',
    appBarTheme: _appBarTheme,
    progressIndicatorTheme: _progressIndicatorThemeData,
    bottomNavigationBarTheme: _bottomNavigationBarTheme,
  );
}

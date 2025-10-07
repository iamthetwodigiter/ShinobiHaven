import 'package:flutter/material.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';

class AppTheme {
  static Color get gradient1 => UserBoxFunctions.getAccentColor();
  // static const Color gradient2 = Color.fromARGB(255, 219, 55, 45);
  static const Color blackGradient = Color.fromARGB(255, 27, 25, 25);
  static const Color whiteGradient = Color.fromARGB(255, 239, 236, 236);

  static const Color greyGradient = Color.fromARGB(255, 84, 84, 84);
  static const Color primaryGreen = Colors.green;
  static const Color primaryBlack = Colors.black;
  static const Color primaryBlue = Colors.blue;
  static const Color primaryAmber = Colors.amber;
  static const Color primaryRed = Colors.red;
  static const Color transparentColor = Colors.transparent;

  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: transparentColor,
    titleTextStyle: TextStyle(
      color: gradient1,
      fontSize: 22,
      fontFamily: 'SFPro',
    ),
    iconTheme: IconThemeData(color: gradient1),
    toolbarHeight: 50,
  );

  static ProgressIndicatorThemeData get progressIndicatorThemeData =>
      ProgressIndicatorThemeData(color: AppTheme.gradient1);

  static BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      BottomNavigationBarThemeData(
        enableFeedback: true,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: IconThemeData(size: 20),
        unselectedIconTheme: IconThemeData(size: 18),
        selectedLabelStyle: TextStyle(fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        selectedItemColor: gradient1,
        unselectedItemColor: greyGradient,
      );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryBlack,
    primaryColor: gradient1,
    fontFamily: 'SFPro',
    appBarTheme: appBarTheme,
    progressIndicatorTheme: progressIndicatorThemeData,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: whiteGradient,
    primaryColor: gradient1,
    fontFamily: 'SFPro',
    appBarTheme: appBarTheme,
    progressIndicatorTheme: progressIndicatorThemeData,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
  );
}

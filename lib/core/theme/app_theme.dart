import 'package:flutter/material.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';

class AppTheme {
  static Color get gradient1 => UserBoxFunctions.getAccentColor();
  // static const Color gradient2 = Color.fromARGB(255, 219, 55, 45);
  static const Color blackGradient = Color.fromARGB(255, 27, 25, 25);
  static const Color whiteGradient = Color.fromARGB(255, 255, 255, 255);

  static const Color greyGradient = Color.fromARGB(255, 84, 84, 84);
  static const Color primaryGreen = Colors.green;
  static const Color primaryBlack = Colors.black;
  static const Color primaryBlue = Colors.blue;
  static const Color primaryAmber = Colors.amber;
  static const Color primaryRed = Colors.red;
  static const Color primaryOrange = Colors.orange;
  static const Color transparentColor = Colors.transparent;

  static const List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  static BoxDecoration glassBox({double radius = 12, Color? color}) =>
      BoxDecoration(
        color: (color ?? Colors.white).withAlpha(30),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
      );

  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E1E1E)
      : Colors.white;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF121212)
      : const Color(0xFFF7F7F9);

  static BoxDecoration premiumCard(
    BuildContext context, {
    double radius = 15,
  }) => BoxDecoration(
    color: cardColor(
      context,
    ).withAlpha(Theme.of(context).brightness == Brightness.dark ? 200 : 255),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: gradient1.withAlpha(40)),
    boxShadow: premiumShadow,
  );

  static BoxDecoration mainBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradient1.withAlpha(20),
                isDark ? primaryBlack : whiteGradient,
              ],
            ),
          )
        : BoxDecoration(
            color: whiteGradient,
          );
  }

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
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        selectedLabelStyle: TextStyle(fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        selectedItemColor: gradient1,
        unselectedItemColor: greyGradient,
      );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: gradient1,
    fontFamily: 'SFPro',
    appBarTheme: appBarTheme,
    progressIndicatorTheme: progressIndicatorThemeData,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: gradient1,
    fontFamily: 'SFPro',
    appBarTheme: appBarTheme,
    progressIndicatorTheme: progressIndicatorThemeData,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
  );
}

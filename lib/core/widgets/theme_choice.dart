import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';

class ThemeChoice extends StatelessWidget {
  final int currentThemeChoice;
  final Color themeColor;
  final String title;
  final Color titleTextColor;
  final int themeMode;
  final VoidCallback onTap;
  const ThemeChoice({
    super.key,
    required this.currentThemeChoice,
    required this.themeColor,
    required this.title,
    required this.titleTextColor,
    required this.themeMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 180,
        child: DeviceFrame(
          device: Devices.ios.iPhone15Pro,
          isFrameVisible: true,
          orientation: Orientation.portrait,
          screen: Container(
            color: themeColor,
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(25),
                  child: Image.asset('assets/images/onboarding_poster.png'),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: titleTextColor,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                if (currentThemeChoice == themeMode)
                  Container(
                    height: 75,
                    width: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.gradient1,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Selected',
                      style: TextStyle(
                        color: AppTheme.whiteGradient,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

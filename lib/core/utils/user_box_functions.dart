import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserBoxFunctions {
  UserBoxFunctions._internal();
  static final UserBoxFunctions _instance = UserBoxFunctions._internal();
  factory UserBoxFunctions() => _instance;

  static final Box _userBox = Hive.box('user');

  static bool isSetupDone() {
    return _userBox.get('firstSetup', defaultValue: false);
  }

  static void markFirstSetup() {
    _userBox.put('firstSetup', true);
  }

  static String getInstalledVersion() {
    return _userBox.get('installedVersion');
  }

  static void setInstalledVersion(String version) {
    _userBox.put('installedVersion', version);
  }

  static bool isDarkMode(BuildContext context) {
    /*
      0 - No
      1 - Yes
      2 - System Settings
    */
    final int darkModeStatus = _userBox.get('darkMode', defaultValue: 1);
    if ((darkModeStatus == 2 &&
            Theme.brightnessOf(context) == Brightness.dark) ||
        darkModeStatus == 1) {
      return true;
    }
    return false;
  }

  static int darkModeState () {
    return _userBox.get('darkMode', defaultValue: 1);
  }

  static void toggleDarkMode(int value) {
    _userBox.put('darkMode', value);
  }

  static void setUserName(String name) {
    _userBox.put('name', name);
  }

  static String getUserName() {
    return _userBox.get('name', defaultValue: 'Shinobi');
  }

  static void setUserProfile(String assetPath) {
    _userBox.put('profile', assetPath);
  }

  static String getUserProfile() {
    return _userBox.get('profile', defaultValue: 'assets/images/naruto.jpg');
  }

}

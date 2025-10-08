import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
    final int darkModeStatus = _userBox.get('darkMode', defaultValue: 1);
    if ((darkModeStatus == 2 &&
            Theme.brightnessOf(context) == Brightness.dark) ||
        darkModeStatus == 1) {
      return true;
    }
    return false;
  }

  static int darkModeState() {
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

  static void setAccentColor(Color accentColor) {
    _userBox.put('accentColor', accentColor.toARGB32());
  }

  static Color getAccentColor() {
    final dynamic raw = _userBox.get('accentColor');
    if (raw is Color) return raw;
    if (raw is int) return Color(raw);
    return AppTheme.gradient1;
  }

  static Future<String?> backupAllData() async {
    try {
      if (Platform.isAndroid) {
        if (await _requestStoragePermissions()) {
        } else {
          throw Exception('Storage permissions are required for backup');
        }
      }

      final userBox = Hive.box('user');
      final libraryBox = Hive.box('library');
      final favoritesBox = Hive.box('favorites');

      Box? historyBox;
      try {
        if (Hive.isBoxOpen('history')) {
          historyBox = Hive.box('history');
        } else {
          historyBox = await Hive.openBox('history');
        }
      } catch (_) {}

      final Map<String, dynamic> backupData = {
        'metadata': {
          'backupDate': DateTime.now().toIso8601String(),
          'appVersion': AppDetails.version,
          'backupVersion': '1.0',
          'deviceInfo': Platform.operatingSystem,
        },
        'user': _boxToMap(userBox),
        'library': _boxToMap(libraryBox),
        'favorites': _boxToMap(favoritesBox),
        'history': historyBox != null ? _boxToMap(historyBox) : {},
      };

      final jsonString = jsonEncode(backupData);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory(AppDetails.appDirectory);
        if (!directory.existsSync()) {
           directory.createSync();
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('T', '_')
          .split('.')[0];
      final fileName = 'shinobihaven_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreFromBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        dialogTitle: 'Select ShinobiHaven Backup File',
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.first.path!);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('user') ||
          !backupData.containsKey('library') ||
          !backupData.containsKey('favorites')) {
        throw Exception('Invalid backup file format');
      }

      final metadata = backupData['metadata'] as Map<String, dynamic>?;
      if (metadata?['backupVersion'] == null) {}

      final userBox = Hive.box('user');
      final libraryBox = Hive.box('library');
      final favoritesBox = Hive.box('favorites');

      Box? historyBox;
      try {
        if (Hive.isBoxOpen('history')) {
          historyBox = Hive.box('history');
        } else {
          historyBox = await Hive.openBox('history');
        }
      } catch (_) {}

      await userBox.clear();
      await libraryBox.clear();
      await favoritesBox.clear();
      if (historyBox != null) {
        await historyBox.clear();
      }

      await _restoreBoxData(userBox, backupData['user']);
      await _restoreBoxData(libraryBox, backupData['library']);
      await _restoreBoxData(favoritesBox, backupData['favorites']);

      if (historyBox != null && backupData['history'] != null) {
        await _restoreBoxData(historyBox, backupData['history']);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, String>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (!backupData.containsKey('metadata')) return null;

      final metadata = backupData['metadata'] as Map<String, dynamic>;

      final userItems = (backupData['user'] as Map?)?.length ?? 0;
      final libraryItems = (backupData['library'] as Map?)?.length ?? 0;
      final favoritesItems = (backupData['favorites'] as Map?)?.length ?? 0;
      final historyItems = (backupData['history'] as Map?)?.length ?? 0;

      return {
        'backupDate': metadata['backupDate'] ?? 'Unknown',
        'appVersion': metadata['appVersion'] ?? 'Unknown',
        'backupVersion': metadata['backupVersion'] ?? 'Unknown',
        'deviceInfo': metadata['deviceInfo'] ?? 'Unknown',
        'fileSize': _formatFileSize(await file.length()),
        'totalItems':
            '${userItems + libraryItems + favoritesItems + historyItems}',
        'userItems': userItems.toString(),
        'libraryItems': libraryItems.toString(),
        'favoritesItems': favoritesItems.toString(),
        'historyItems': historyItems.toString(),
      };
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _boxToMap(Box box) {
    final Map<String, dynamic> map = {};
    for (final key in box.keys) {
      final value = box.get(key);
      map[key.toString()] = _serializeValue(value);
    }
    return map;
  }

  static dynamic _serializeValue(dynamic value) {
    if (value is Anime) {
      return {
        '_type': 'Anime',
        'data': {
          'slug': value.slug,
          'link': value.link,
          'title': value.title,
          'jname': value.jname,
          'image': value.image,
          'type': value.type,
          'duration': value.duration,
          'subCount': value.subCount,
          'dubCount': value.dubCount,
        },
      };
    } else if (value is Map) {
      final Map<String, dynamic> serializedMap = {};
      value.forEach((k, v) {
        serializedMap[k.toString()] = _serializeValue(v);
      });
      return serializedMap;
    } else if (value is List) {
      return value.map((item) => _serializeValue(item)).toList();
    }
    return value;
  }

  static Future<void> _restoreBoxData(Box box, dynamic data) async {
    if (data is! Map<String, dynamic>) return;

    for (final entry in data.entries) {
      final key = entry.key;
      final value = _deserializeValue(entry.value);
      await box.put(key, value);
    }
  }

  static dynamic _deserializeValue(dynamic value) {
    if (value is Map<String, dynamic> && value.containsKey('_type')) {
      switch (value['_type']) {
        case 'Anime':
          final data = value['data'] as Map<String, dynamic>;
          return Anime(
            slug: data['slug'] ?? '',
            link: data['link'] ?? '',
            title: data['title'] ?? '',
            jname: data['jname'] ?? '',
            image: data['image'] ?? '',
            type: data['type'] ?? '',
            duration: data['duration'] ?? '',
            subCount: data['subCount'],
            dubCount: data['dubCount'],
          );
        default:
          return value['data'];
      }
    } else if (value is Map) {
      final Map<String, dynamic> deserializedMap = {};
      value.forEach((k, v) {
        deserializedMap[k.toString()] = _deserializeValue(v);
      });
      return deserializedMap;
    } else if (value is List) {
      return value.map((item) => _deserializeValue(item)).toList();
    }
    return value;
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<bool> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        Map<Permission, PermissionStatus> statuses = await permissions
            .request();
        return statuses.values.every((status) => status.isGranted);
      } else if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        final statuses = await [Permission.storage].request();
        return statuses[Permission.storage]?.isGranted ?? false;
      }
    }
    return true;
  }
}

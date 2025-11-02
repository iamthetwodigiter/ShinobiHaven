import 'dart:io';
import 'package:android_intent_plus/flag.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/core/services/notification_service.dart';
import 'package:toastification/toastification.dart';

class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final String downloadUrl;
  final String publishedAt;
  final bool prerelease;

  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.downloadUrl,
    required this.publishedAt,
    required this.prerelease,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    String downloadUrl = '';
    final assets = json['assets'] as List<dynamic>? ?? [];

    for (final asset in assets) {
      final assetName = asset['name'] as String? ?? '';
      if (assetName.toLowerCase().endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        break;
      }
    }

    return GitHubRelease(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      downloadUrl: downloadUrl,
      publishedAt: json['published_at'] as String? ?? '',
      prerelease: json['prerelease'] as bool? ?? false,
    );
  }
}

class UpdateChecker {
  static final Dio _dio = Dio();
  static bool _isDialogOpen = false;

  static Map<String, String>? _parseGitHubUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 2) {
        return {'owner': pathSegments[0], 'repo': pathSegments[1]};
      }
    } catch (_) {}
    return null;
  }

  static Future<GitHubRelease?> getLatestRelease() async {
    try {
      final repoInfo = _parseGitHubUrl(AppDetails.repoURL);
      if (repoInfo == null) {
        throw Exception('Invalid GitHub repository URL');
      }

      final response = await _dio.get(
        'https://api.github.com/repos/${repoInfo['owner']}/${repoInfo['repo']}/releases/latest',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'ShinobiHaven-App',
          },
        ),
      );

      if (response.statusCode == 200) {
        return GitHubRelease.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  static int compareVersions(String version1, String version2) {
    version1 = version1.replaceFirst('v', '');
    version2 = version2.replaceFirst('v', '');

    final parts1 = version1
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final parts2 = version2
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }

    return 0;
  }

  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdateDialog = true,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.gradient1),
              SizedBox(height: 16),
              Text('Checking for updates...'),
            ],
          ),
        ),
      );

      final latestRelease = await getLatestRelease();

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (latestRelease == null) {
        if (showNoUpdateDialog && context.mounted) {
          _showErrorDialog(
            context,
            'Failed to check for updates. Please try again later.',
          );
        }
        return;
      }

      final currentVersion = AppDetails.version;
      final latestVersion = latestRelease.tagName;

      final comparison = compareVersions(currentVersion, latestVersion);

      if (comparison < 0) {
        await NotificationService.cancelNotification(
          NotificationIds.updateAvailable,
        );
        await NotificationServiceExtensions.showUpdateAvailable(
          version: latestVersion,
        );

        if (context.mounted) {
          _showUpdateDialog(context, latestRelease);
        }
      } else {
        if (showNoUpdateDialog && context.mounted) {
          _showNoUpdateDialog(context, currentVersion);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (showNoUpdateDialog && context.mounted) {
        _showErrorDialog(
          context,
          'Error checking for updates: ${e.toString()}',
        );
      }
    }
  }

  static void _showUpdateDialog(BuildContext context, GitHubRelease release) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppTheme.gradient1),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of ShinobiHaven is available!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Current Version: ${AppDetails.version}'),
            Text('Latest Version: ${release.tagName}'),
            SizedBox(height: 12),
            if (release.body.isNotEmpty) ...[
              Text(
                'What\'s New:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity, // Add explicit width
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gradient1.withAlpha(100)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(8),
                  child: MarkdownBody(
                    // Use MarkdownBody instead of Markdown
                    data: release.body,
                    shrinkWrap: true, // Add shrinkWrap
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: 13),
                      h1: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      h2: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      h3: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      listBullet: TextStyle(fontSize: 13),
                      code: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.gradient1)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.gradient1,
              padding: EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (release.downloadUrl.isNotEmpty) {
                _downloadAndInstallUpdate(context, release);
              } else {
                _showErrorDialog(
                  context,
                  'No APK file found in the latest release.',
                );
              }
            },
            child: Text(
              'Download',
              style: TextStyle(color: AppTheme.whiteGradient),
            ),
          ),
        ],
      ),
    );
  }

  static void _showNoUpdateDialog(BuildContext context, String currentVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('You\'re Up to Date!'),
          ],
        ),
        content: Text(
          'You have the latest version of ShinobiHaven ($currentVersion).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.gradient1)),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.primaryRed),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.gradient1)),
          ),
        ],
      ),
    );
  }

  static Future<void> _installApk(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (context.mounted) {
          Toast(
            context: context,
            title: 'File Not Found',
            description: 'The APK file could not be found.',
            type: ToastificationType.error,
          );
        }
        return;
      }

      final installPermission = await Permission.requestInstallPackages
          .request();
      if (!installPermission.isGranted) {
        if (context.mounted) {
          _showInstallPermissionDialog(context, filePath);
        }
        return;
      }

      bool installationSuccess = false;

      if (Platform.isAndroid) {
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'file://$filePath',
            type: 'application/vnd.android.package-archive',
            flags: [
              Flag.FLAG_ACTIVITY_NEW_TASK,
              Flag.FLAG_GRANT_READ_URI_PERMISSION,
            ],
          );
          await intent.launch();
          installationSuccess = true;
        } catch (_) {}
      }

      if (!installationSuccess) {
        try {
          final result = await OpenFile.open(
            filePath,
            type: 'application/vnd.android.package-archive',
          );
          if (result.type == ResultType.done) {
            installationSuccess = true;
          }
        } catch (_) {}
      }

      if (!installationSuccess && context.mounted) {
        _showManualInstallDialog(context, filePath);
      }
    } catch (e) {
      if (context.mounted) {
        Toast(
          context: context,
          title: 'Installation Error',
          description: 'Failed to install APK: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    }
  }

  static void _showInstallPermissionDialog(
    BuildContext context,
    String filePath,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.gradient1),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: Text(
          'ShinobiHaven needs permission to install packages. Please enable "Install unknown apps" for ShinobiHaven in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.gradient1)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.gradient1,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();

              if (context.mounted) {
                Toast(
                  context: context,
                  title: 'Enable Install Permission',
                  description:
                      'Go to Special app access > Install unknown apps > ShinobiHaven > Allow',
                  type: ToastificationType.info,
                );
              }
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static void _showManualInstallDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.gradient1),
            SizedBox(width: 8),
            Text('Manual Installation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please install the APK manually:'),
            SizedBox(height: 12),
            Text('1. Open your file manager'),
            Text('2. Go to Downloads folder'),
            Text('3. Find: ${filePath.split('/').last}'),
            Text('4. Tap the file to install'),
            SizedBox(height: 12),
            Text(
              'Make sure "Install unknown apps" is enabled for your file manager.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.gradient1)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.gradient1,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await OpenFile.open('/storage/emulated/0/Download');
              } catch (e) {
                if (Platform.isAndroid) {
                  final intent = AndroidIntent(
                    action: 'android.intent.action.VIEW',
                    data:
                        'content://com.android.externalstorage.documents/root/primary%3ADownload',
                    type: 'resource/folder',
                  );
                  try {
                    await intent.launch();
                  } catch (_) {}
                }
              }
            },
            child: Text('Open Downloads'),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstallUpdate(
    BuildContext context,
    GitHubRelease release,
  ) async {
    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        final installStatus = await Permission.requestInstallPackages.request();

        if (installStatus.isDenied) {
          await Permission.requestInstallPackages.request();
        }

        if (!storageStatus.isGranted) {
          if (context.mounted) {
            _showErrorDialog(
              context,
              'Storage permission is required to download updates.',
            );
          }
          return;
        }
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (context.mounted) {
          _showErrorDialog(context, 'Could not access storage directory.');
        }
        return;
      }

      final fileName = 'ShinobiHaven_${release.tagName}.apk';
      final filePath = '${directory.path}/$fileName';

      await NotificationService.cancelNotification(
        NotificationIds.updateAvailable,
      );
      await NotificationService.cancelNotification(
        NotificationIds.updateComplete,
      );
      await NotificationService.cancelNotification(
        NotificationIds.updateFailed,
      );

      await NotificationServiceExtensions.showDownloadStarted(
        id: NotificationIds.updateDownload,
        itemName: 'ShinobiHaven ${release.tagName}',
        channel: NotificationChannel.updates,
      );

      final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
      final ValueNotifier<bool> isDownloadingNotifier = ValueNotifier<bool>(
        true,
      );
      final ValueNotifier<bool> isCompletedNotifier = ValueNotifier<bool>(
        false,
      );

      if (context.mounted) {
        _isDialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ValueListenableBuilder<bool>(
            valueListenable: isCompletedNotifier,
            builder: (context, isCompleted, child) {
              if (isCompleted) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.download_done, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Text('Download Complete'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update downloaded successfully!'),
                      SizedBox(height: 12),
                      Text('File: $fileName'),
                      SizedBox(height: 8),
                      Text(
                        'Location: ${Platform.isAndroid ? 'Downloads folder' : 'Documents folder'}',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap "Install" to install the update.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _isDialogOpen = false;
                      },
                      child: Text(
                        'Later',
                        style: TextStyle(color: AppTheme.gradient1),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gradient1,
                        foregroundColor: AppTheme.whiteGradient,
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        _isDialogOpen = false;
                        NotificationService.cancelNotification(
                          NotificationIds.updateComplete,
                        );
                        _installApk(context, filePath);
                      },
                      child: Text('Install'),
                    ),
                  ],
                );
              } else {
                return ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (context, progress, child) => ValueListenableBuilder<bool>(
                    valueListenable: isDownloadingNotifier,
                    builder: (context, isDownloading, child) => AlertDialog(
                      title: Text('Downloading Update'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.whiteGradient.withAlpha(
                              100,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.gradient1,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('${(progress * 100).toInt()}%'),
                          SizedBox(height: 8),
                          Text(
                            'Downloading ${release.tagName}...',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You can minimize the app. You\'ll get a notification when download completes.',
                            style: TextStyle(fontSize: 12, color: AppTheme.greyGradient),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            isDownloadingNotifier.value = false;
                            Navigator.pop(dialogContext);
                            _isDialogOpen = false;
                            NotificationService.cancelNotification(
                              NotificationIds.updateDownload,
                            );
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppTheme.gradient1),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _isDialogOpen = false;
                            if (context.mounted) {
                              Toast(
                                context: context,
                                title: 'Download in Background',
                                description:
                                    'Download continues in background. Check notifications for progress.',
                                type: ToastificationType.info,
                              );
                            }
                          },
                          child: Text(
                            'Minimize',
                            style: TextStyle(color: AppTheme.gradient1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ).then((_) {
          _isDialogOpen = false;
        });
      }

      await _dio.download(
        release.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) async {
          if (total != -1 && isDownloadingNotifier.value) {
            final newProgress = received / total;
            final progressPercent = (newProgress * 100).toInt();

            progressNotifier.value = newProgress;

            if (progressPercent % 10 == 0) {
              await NotificationServiceExtensions.updateDownloadProgress(
                id: NotificationIds.updateDownload,
                itemName: 'ShinobiHaven ${release.tagName}',
                channel: NotificationChannel.updates,
                progress: progressPercent,
              );
            }
          }
        },
      );

      progressNotifier.dispose();

      if (!isDownloadingNotifier.value) {
        await NotificationService.cancelNotification(
          NotificationIds.updateDownload,
        );
        isDownloadingNotifier.dispose();
        isCompletedNotifier.dispose();
        return;
      }

      await NotificationServiceExtensions.showDownloadCompleted(
        id: NotificationIds.updateComplete,
        itemName: 'ShinobiHaven ${release.tagName}',
        description: 'ShinobiHaven ${release.tagName} is ready! Tap to install.',
        channel: NotificationChannel.updates,
        actionText: 'Install Now',
        actionId: 'install',
        filePath: filePath,
        progressNotificationId: NotificationIds.updateDownload,
      );

      isCompletedNotifier.value = true;

      Future.delayed(Duration(seconds: 1), () {
        isDownloadingNotifier.dispose();
        isCompletedNotifier.dispose();
      });
    } catch (e) {
      if (context.mounted && _isDialogOpen) {
        Navigator.pop(context);
        _isDialogOpen = false;
      }

      await NotificationServiceExtensions.showDownloadFailed(
        id: NotificationIds.updateFailed,
        itemName: 'ShinobiHaven ${release.tagName}',
        channel: NotificationChannel.updates,
        error: e.toString(),
        progressNotificationId: NotificationIds.updateDownload,
      );

      if (context.mounted) {
        _showErrorDialog(context, 'Download failed: ${e.toString()}');
      }
    }
  }
}

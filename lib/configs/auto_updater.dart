import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:app_installer/app_installer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dnd/configs/version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dnd/l10n/app_localizations.dart';

const String repoOwner = 'BonobosInc';
const String repoName = 'dnd';

Future<void> checkForUpdate(BuildContext context) async {
  if (!Platform.isAndroid) return;

  try {
    final response = await http.get(Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final latestVersion = data['tag_name']?.replaceFirst('v', '');
      final apkAsset = (data['assets'] as List)
          .firstWhere((a) => a['name'].endsWith('.apk'), orElse: () => null);

      if (latestVersion != null &&
          isNewerVersion(latestVersion, appVersion) &&
          apkAsset != null) {
        final apkUrl = apkAsset['browser_download_url'];

        if (context.mounted) {
          final loc = AppLocalizations.of(context)!;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Text(loc.updateAvailableTitle),
              content: Text(
                loc.updateAvailableContent(latestVersion, appVersion),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(loc.skip),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _downloadAndInstallApk(context, apkUrl);
                  },
                  child: Text(loc.update),
                ),
              ],
            ),
          );
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Update check failed: $e');
    }
  }
}

bool isNewerVersion(String latest, String current) {
  final latestParts = latest.split('.').map(int.parse).toList();
  final currentParts = current.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }

  return false;
}

Future<void> _downloadAndInstallApk(BuildContext context, String url) async {
  final dir = await getExternalStorageDirectory();
  final filePath = '${dir!.path}/update.apk';
  final file = File(filePath);

  if (context.mounted) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(loc.downloadingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loc.downloadingContent),
            ],
          ),
        ),
      ),
    );
  }

  try {
    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_apk_cleanup', filePath);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    await AppInstaller.installApk(filePath);
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    final loc = AppLocalizations.of(context)!;

    if (e.toString().contains("INSTALL_FAILED_PERMISSION_DENIED")) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(loc.installPermissionTitle),
            content: Text(loc.installPermissionContent),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: Text(loc.openSettings),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.cancel),
              ),
            ],
          ),
        );
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(loc.updateFailedTitle),
            content: Text(loc.updateFailedContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.ok),
              )
            ],
          ),
        );
      }
    }
  }
}

Future<void> cleanupPendingApk() async {
  final prefs = await SharedPreferences.getInstance();
  final apkPath = prefs.getString('pending_apk_cleanup');

  if (apkPath != null) {
    final file = File(apkPath);
    if (await file.exists()) {
      try {
        await file.delete();
        if (kDebugMode) print("Old APK file deleted.");
      } catch (e) {
        if (kDebugMode) print("Failed to delete old APK file: $e");
      }
    }
    await prefs.remove('pending_apk_cleanup');
  }
}

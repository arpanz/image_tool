import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static bool _checkedThisSession = false;

  static Future<void> checkForUpdatesOnLaunch(BuildContext context) async {
    if (_checkedThisSession || !Platform.isAndroid) return;
    _checkedThisSession = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
      if (!context.mounted) return;

      final shouldUpdate = await _showUpdateDialog(context);
      if (!shouldUpdate || !context.mounted) return;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('AppUpdateService: update check failed: $e');
    }
  }

  static Future<bool> _showUpdateDialog(BuildContext context) async {
    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Update available'),
        content: const Text(
          'A new version of Image Resizer is available. Update now for the best experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Update now'),
          ),
        ],
      ),
    );

    return choice ?? false;
  }
}


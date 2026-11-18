import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Checks Google Play for an update when the app starts.
/// This works only for builds installed from Google Play.
class AppUpdateService {
  AppUpdateService._();

  static Future<void> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      // Prefer an immediate Play Store update when Google marks it as required.
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Otherwise download the update through the Play Store's flexible flow.
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (error) {
      // Sideloaded APKs and devices without Play Store update eligibility
      // should continue to open normally.
      debugPrint('RYZONE update check skipped: $error');
    }
  }
}

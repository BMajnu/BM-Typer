import 'package:bm_typer/core/services/in_app_update_service.dart';
import 'package:bm_typer/core/services/version_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InAppUpdateService.resolvePlan', () {
    test('chooses in-app APK install for Android direct APK links', () {
      const result = UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        message: 'নতুন আপডেট আছে',
        downloadUrl: 'https://example.com/bm-typer-release.apk',
        actionLabel: 'ডাউনলোড ও ইনস্টল করুন',
        preferInAppUpdate: true,
      );

      final plan = InAppUpdateService.resolvePlan(
        result,
        isWeb: false,
        platform: TargetPlatform.android,
      );

      expect(plan.mode, UpdateInstallMode.inAppApk);
      expect(plan.url, result.downloadUrl);
      expect(plan.actionLabel, 'ডাউনলোড ও ইনস্টল করুন');
    });

    test('falls back to external links when target is not an APK', () {
      const result = UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        message: 'নতুন আপডেট আছে',
        downloadUrl: 'https://play.google.com/store/apps/details?id=com.techzoneit.bm_typer',
        actionLabel: 'Play Store খুলুন',
      );

      final plan = InAppUpdateService.resolvePlan(
        result,
        isWeb: false,
        platform: TargetPlatform.android,
      );

      expect(plan.mode, UpdateInstallMode.externalUrl);
      expect(plan.url, result.downloadUrl);
      expect(plan.actionLabel, 'Play Store খুলুন');
    });
  });
}

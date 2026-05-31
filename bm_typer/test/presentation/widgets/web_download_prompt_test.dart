import 'package:bm_typer/core/services/version_service.dart';
import 'package:bm_typer/presentation/widgets/web_download_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WebDownloadPromptLogic direct download helpers', () {
    test('recognizes direct downloadable installer files', () {
      expect(
        WebDownloadPromptLogic.isDirectDownloadUrl(
          'https://downloads.example.com/BM-Typer-Setup.exe',
        ),
        isTrue,
      );
      expect(
        WebDownloadPromptLogic.isDirectDownloadUrl(
          'https://downloads.example.com/BM-Typer-Setup.msi',
        ),
        isTrue,
      );
      expect(
        WebDownloadPromptLogic.isDirectDownloadUrl(
          '/downloads/BM-Typer-Setup.exe',
        ),
        isTrue,
      );
    });

    test('ignores non-download landing pages', () {
      expect(
        WebDownloadPromptLogic.isDirectDownloadUrl(
          'https://www.techzoneit.top',
        ),
        isFalse,
      );
      expect(
        WebDownloadPromptLogic.isDirectDownloadUrl(
          'https://example.com/downloads/windows',
        ),
        isFalse,
      );
    });
  });

  group('WebDownloadPromptLogic.resolveRecommendation', () {
    const config = AppVersionConfig(
      currentVersion: '1.0.0',
      minimumVersion: '1.0.0',
      androidApkUrl: 'https://downloads.example.com/bm-typer.apk',
      windowsInstallerUrl: 'https://downloads.example.com/BM-Typer-Setup.exe',
      webUpdateUrl: 'https://www.example.com',
    );

    test('shows Android recommendation for web mobile visitors', () {
      final recommendation = WebDownloadPromptLogic.resolveRecommendation(
        isWeb: true,
        platform: TargetPlatform.android,
        config: config,
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.target, WebDownloadPromptTarget.android);
      expect(recommendation.actionLabel, contains('Android'));
      expect(recommendation.downloadUrl, config.androidApkUrl);
    });

    test('shows Windows recommendation for web Windows visitors', () {
      final recommendation = WebDownloadPromptLogic.resolveRecommendation(
        isWeb: true,
        platform: TargetPlatform.windows,
        config: config,
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.target, WebDownloadPromptTarget.windows);
      expect(recommendation.actionLabel, contains('Windows'));
      expect(recommendation.downloadUrl, config.windowsInstallerUrl);
    });

    test('falls back to bundled windows installer for landing-page urls', () {
      const configWithPageUrl = AppVersionConfig(
        currentVersion: '1.0.0',
        minimumVersion: '1.0.0',
        windowsInstallerUrl: 'https://www.techzoneit.top',
        webUpdateUrl: 'https://www.example.com',
      );

      final recommendation = WebDownloadPromptLogic.resolveRecommendation(
        isWeb: true,
        platform: TargetPlatform.windows,
        config: configWithPageUrl,
      );

      expect(recommendation, isNotNull);
      expect(
        recommendation!.downloadUrl,
        WebDownloadPromptLogic.bundledWindowsInstallerPath,
      );
    });

    test('does not show recommendation outside web', () {
      final recommendation = WebDownloadPromptLogic.resolveRecommendation(
        isWeb: false,
        platform: TargetPlatform.windows,
        config: config,
      );

      expect(recommendation, isNull);
    });
  });

  testWidgets(
    'failed windows download attempts do not throw overlay-related exceptions',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      const config = AppVersionConfig(
        currentVersion: '1.0.0',
        minimumVersion: '1.0.0',
        windowsInstallerUrl: 'https://www.techzoneit.top',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            versionConfigProvider.overrideWith(
              (ref) => Stream.value(config),
            ),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Theme(
                data: ThemeData(),
                child: Material(
                  child: WebDownloadPrompt(
                    isWeb: true,
                    platformOverride: TargetPlatform.windows,
                    openUrl: (uri, windowName) async => false,
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Windows Setup ডাউনলোড'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

import 'dart:io';

import 'package:bm_typer/core/services/in_app_update_types.dart';
import 'package:bm_typer/core/services/version_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  static UpdateInstallPlan resolvePlan(
    UpdateCheckResult result, {
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    final url = result.downloadUrl?.trim();

    if (url == null || url.isEmpty) {
      return UpdateInstallPlan(
        mode: UpdateInstallMode.none,
        url: null,
        actionLabel: result.actionLabel,
      );
    }

    if (!isWeb &&
        resolvedPlatform == TargetPlatform.android &&
        (result.preferInAppUpdate || _looksLikeApkUrl(url))) {
      return UpdateInstallPlan(
        mode: UpdateInstallMode.inAppApk,
        url: url,
        actionLabel: result.actionLabel,
      );
    }

    return UpdateInstallPlan(
      mode: UpdateInstallMode.externalUrl,
      url: url,
      actionLabel: result.actionLabel,
    );
  }

  static Future<void> startUpdate(
    BuildContext context,
    UpdateCheckResult result,
  ) async {
    final plan = resolvePlan(result);

    if (plan.url == null) {
      _showMessage(context, 'ডাউনলোড লিংক পাওয়া যায়নি।');
      return;
    }

    switch (plan.mode) {
      case UpdateInstallMode.inAppApk:
        await _downloadAndInstallApk(context, plan.url!);
        return;
      case UpdateInstallMode.externalUrl:
        await launchUrl(
          Uri.parse(plan.url!),
          mode: LaunchMode.externalApplication,
        );
        return;
      case UpdateInstallMode.none:
        _showMessage(context, 'এই আপডেটের জন্য কোনো অ্যাকশন পাওয়া যায়নি।');
        return;
    }
  }

  static Future<void> _downloadAndInstallApk(
    BuildContext context,
    String url,
  ) async {
    final progressNotifier = ValueNotifier<double?>(null);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final client = http.Client();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: ValueListenableBuilder<double?>(
            valueListenable: progressNotifier,
            builder: (context, progress, _) {
              final progressText = progress == null
                  ? 'আপডেট প্যাকেজ ডাউনলোড প্রস্তুত হচ্ছে...'
                  : 'ডাউনলোড হচ্ছে ${((progress.clamp(0, 1)) * 100).toStringAsFixed(0)}%';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/BMT.png', width: 56, height: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'নতুন আপডেট ডাউনলোড হচ্ছে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progressText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: progress),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      final supportDirectory = await getApplicationSupportDirectory();
      final updateDirectory = Directory(
        '${supportDirectory.path}${Platform.pathSeparator}updates',
      );
      if (!updateDirectory.existsSync()) {
        await updateDirectory.create(recursive: true);
      }

      final apkFile = File(
        '${updateDirectory.path}${Platform.pathSeparator}bm-typer-update.apk',
      );
      if (apkFile.existsSync()) {
        await apkFile.delete();
      }

      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode >= 400) {
        throw Exception('ডাউনলোড সার্ভার রেসপন্স: ${response.statusCode}');
      }

      final sink = apkFile.openWrite();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          progressNotifier.value = receivedBytes / totalBytes;
        }
      }

      await sink.flush();
      await sink.close();

      if (rootNavigator.mounted) {
        rootNavigator.pop();
      }

      final openResult = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      if (openResult.type != ResultType.done) {
        _showMessage(
          context,
          'ডাউনলোড সম্পন্ন হয়েছে, কিন্তু installer চালু করা যায়নি। Unknown Apps অনুমতি দিয়ে আবার চেষ্টা করুন।',
        );
      }
    } catch (error) {
      if (rootNavigator.mounted) {
        rootNavigator.pop();
      }
      _showMessage(context, 'আপডেট ডাউনলোড করতে সমস্যা হয়েছে: $error');
    } finally {
      client.close();
      progressNotifier.dispose();
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static bool _looksLikeApkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return false;
    }

    return uri.path.toLowerCase().endsWith('.apk');
  }
}

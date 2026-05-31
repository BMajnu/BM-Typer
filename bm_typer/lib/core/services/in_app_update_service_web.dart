import 'package:bm_typer/core/services/in_app_update_types.dart';
import 'package:bm_typer/core/services/version_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  static UpdateInstallPlan resolvePlan(
    UpdateCheckResult result, {
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    return UpdateInstallPlan(
      mode: result.downloadUrl == null || result.downloadUrl!.trim().isEmpty
          ? UpdateInstallMode.none
          : UpdateInstallMode.externalUrl,
      url: result.downloadUrl?.trim(),
      actionLabel: result.actionLabel,
    );
  }

  static Future<void> startUpdate(
    BuildContext context,
    UpdateCheckResult result,
  ) async {
    final plan = resolvePlan(result);
    if (plan.url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ডাউনলোড লিংক পাওয়া যায়নি।')),
      );
      return;
    }

    await launchUrl(Uri.parse(plan.url!), mode: LaunchMode.externalApplication);
  }
}

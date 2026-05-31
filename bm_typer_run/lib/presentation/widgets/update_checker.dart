import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bm_typer/core/services/version_service.dart';

/// Widget to check for updates on app start
class UpdateChecker extends ConsumerWidget {
  final Widget child;
  
  const UpdateChecker({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateCheckAsync = ref.watch(updateCheckProvider);
    
    return updateCheckAsync.when(
      data: (result) {
        // Show appropriate screen based on status
        switch (result.status) {
          case UpdateStatus.maintenance:
            return MaintenanceScreen(message: result.message);
          case UpdateStatus.forceUpdate:
            return ForceUpdateScreen(
              message: result.message,
              downloadUrl: result.downloadUrl,
              latestVersion: result.latestVersion,
              actionLabel: result.actionLabel,
              releaseNotes: result.releaseNotes,
            );
          case UpdateStatus.updateAvailable:
            // Show dialog but allow using app
            WidgetsBinding.instance.addPostFrameCallback((_) {
              UpdateDialogHelper.showOptionalUpdateDialog(context, result);
            });
            return child;
          default:
            return child;
        }
      },
      loading: () => child, // Don't block app while loading
      error: (error, stack) => child, // Don't block on error
    );
  }
  
}

bool _hasShownUpdateDialog = false;

class UpdateDialogHelper {
  static Future<void> showOptionalUpdateDialog(
      BuildContext context, UpdateCheckResult result) async {
    if (_hasShownUpdateDialog) return;
    _hasShownUpdateDialog = true;
    await _showUpdateAvailableDialog(context, result, allowLater: true);
  }

  static Future<void> showManualCheckResultDialog(
      BuildContext context, UpdateCheckResult result) async {
    switch (result.status) {
      case UpdateStatus.upToDate:
        await _showInfoDialog(
          context,
          title: 'অ্যাপ আপ টু ডেট',
          message: result.message,
          icon: Icons.verified_rounded,
          iconColor: Colors.green,
        );
        return;
      case UpdateStatus.updateAvailable:
        await _showUpdateAvailableDialog(context, result, allowLater: false);
        return;
      case UpdateStatus.forceUpdate:
        await _showForceUpdateDialog(context, result);
        return;
      case UpdateStatus.maintenance:
        await _showInfoDialog(
          context,
          title: 'মেইনটেন্যান্স চলছে',
          message: result.message,
          icon: Icons.construction_rounded,
          iconColor: Colors.orange,
        );
        return;
      case UpdateStatus.error:
        await _showInfoDialog(
          context,
          title: 'আপডেট চেক করা যায়নি',
          message: result.message,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
        );
        return;
    }
  }

  static Future<void> _showUpdateAvailableDialog(
      BuildContext context, UpdateCheckResult result,
      {required bool allowLater}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Colors.blue),
            const SizedBox(width: 12),
            Text('আপডেট উপলব্ধ',
                style:
                    GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: GoogleFonts.hindSiliguri()),
            if (result.latestVersion != null) ...[
              const SizedBox(height: 8),
              Text('নতুন ভার্সন: ${result.latestVersion}',
                  style: GoogleFonts.hindSiliguri(
                      color: Colors.grey, fontSize: 12)),
            ],
            if (result.releaseNotes != null &&
                result.releaseNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('নতুন কী আছে',
                  style: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(result.releaseNotes!, style: GoogleFonts.hindSiliguri()),
            ],
          ],
        ),
        actions: [
          if (allowLater)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('পরে', style: GoogleFonts.hindSiliguri()),
            ),
          ElevatedButton.icon(
            onPressed: result.downloadUrl == null
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _launchUpdateUrl(result.downloadUrl!);
                  },
            icon: const Icon(Icons.download_rounded),
            label: Text(result.actionLabel,
                style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }

  static Future<void> _showForceUpdateDialog(
      BuildContext context, UpdateCheckResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_alt_rounded, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text('আপডেট প্রয়োজন',
                style:
                    GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: GoogleFonts.hindSiliguri()),
            if (result.latestVersion != null) ...[
              const SizedBox(height: 8),
              Text('নতুন ভার্সন: ${result.latestVersion}',
                  style: GoogleFonts.hindSiliguri(
                      color: Colors.grey, fontSize: 12)),
            ],
            if (result.releaseNotes != null &&
                result.releaseNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('নতুন কী আছে',
                  style: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(result.releaseNotes!, style: GoogleFonts.hindSiliguri()),
            ],
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: result.downloadUrl == null
                ? null
                : () async {
                    await _launchUpdateUrl(result.downloadUrl!);
                  },
            icon: const Icon(Icons.download_rounded),
            label: Text(result.actionLabel,
                style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }

  static Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Text(title,
                style:
                    GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: GoogleFonts.hindSiliguri()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ঠিক আছে', style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchUpdateUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Screen shown when app is in maintenance mode
class MaintenanceScreen extends StatelessWidget {
  final String message;
  
  const MaintenanceScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.purple.shade800,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Maintenance Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'মেইনটেন্যান্স চলছে',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Retry button
                OutlinedButton.icon(
                  onPressed: () {
                    // Trigger a refresh
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'আবার চেষ্টা করুন',
                    style: GoogleFonts.hindSiliguri(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen shown when force update is required
class ForceUpdateScreen extends StatelessWidget {
  final String message;
  final String? downloadUrl;
  final String? latestVersion;
  final String actionLabel;
  final String? releaseNotes;
  
  const ForceUpdateScreen({
    super.key,
    required this.message,
    this.downloadUrl,
    this.latestVersion,
    required this.actionLabel,
    this.releaseNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Update Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'আপডেট প্রয়োজন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                
                if (latestVersion != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'নতুন ভার্সন: $latestVersion',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                ],

                if (releaseNotes != null && releaseNotes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'নতুন কী আছে',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          releaseNotes!,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Download button
                ElevatedButton.icon(
                  onPressed: downloadUrl == null ? null : () {
                    if (downloadUrl != null) {
                      UpdateDialogHelper._launchUpdateUrl(downloadUrl!);
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    actionLabel,
                    style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

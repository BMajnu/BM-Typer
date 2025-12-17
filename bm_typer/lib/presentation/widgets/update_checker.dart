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
            );
          case UpdateStatus.updateAvailable:
            // Show dialog but allow using app
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showOptionalUpdateDialog(context, result);
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
  
  void _showOptionalUpdateDialog(BuildContext context, UpdateCheckResult result) {
    // Only show once per session
    if (_hasShownUpdateDialog) return;
    _hasShownUpdateDialog = true;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.blue),
            const SizedBox(width: 12),
            Text('আপডেট উপলব্ধ', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: GoogleFonts.hindSiliguri()),
            if (result.latestVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                'নতুন ভার্সন: ${result.latestVersion}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('পরে', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              if (result.downloadUrl != null) {
                launchUrl(Uri.parse(result.downloadUrl!));
              }
            },
            icon: const Icon(Icons.download),
            label: Text('আপডেট করুন', style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }
}

bool _hasShownUpdateDialog = false;

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
  
  const ForceUpdateScreen({
    super.key,
    required this.message,
    this.downloadUrl,
    this.latestVersion,
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
                
                const SizedBox(height: 32),
                
                // Download button
                ElevatedButton.icon(
                  onPressed: () {
                    if (downloadUrl != null) {
                      launchUrl(Uri.parse(downloadUrl!));
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    'এখনই আপডেট করুন',
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
                
                const SizedBox(height: 16),
                
                // What's new link
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'নতুন কী কী আছে দেখুন',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white.withOpacity(0.7),
                      decoration: TextDecoration.underline,
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

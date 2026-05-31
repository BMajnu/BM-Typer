import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Model for app version configuration
class AppVersionConfig {
  final String currentVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String? updateMessage;
  final String? maintenanceMessage;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final String? androidApkUrl;
  final String? windowsInstallerUrl;
  final String? webUpdateUrl;
  final String? releaseNotes;
  
  const AppVersionConfig({
    required this.currentVersion,
    required this.minimumVersion,
    this.forceUpdate = false,
    this.maintenanceMode = false,
    this.updateMessage,
    this.maintenanceMessage,
    this.playStoreUrl,
    this.appStoreUrl,
    this.androidApkUrl,
    this.windowsInstallerUrl,
    this.webUpdateUrl,
    this.releaseNotes,
  });
  
  factory AppVersionConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppVersionConfig(
      currentVersion: data['currentVersion'] ?? '1.0.0',
      minimumVersion: data['minimumVersion'] ?? '1.0.0',
      forceUpdate: data['forceUpdate'] ?? false,
      maintenanceMode: data['maintenanceMode'] ?? false,
      updateMessage: data['updateMessage'],
      maintenanceMessage: data['maintenanceMessage'],
      playStoreUrl: data['playStoreUrl'],
      appStoreUrl: data['appStoreUrl'],
      androidApkUrl: data['androidApkUrl'],
      windowsInstallerUrl: data['windowsInstallerUrl'],
      webUpdateUrl: data['webUpdateUrl'],
      releaseNotes: data['releaseNotes'],
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'currentVersion': currentVersion,
      'minimumVersion': minimumVersion,
      'forceUpdate': forceUpdate,
      'maintenanceMode': maintenanceMode,
      if (updateMessage != null) 'updateMessage': updateMessage,
      if (maintenanceMessage != null) 'maintenanceMessage': maintenanceMessage,
      if (playStoreUrl != null) 'playStoreUrl': playStoreUrl,
      if (appStoreUrl != null) 'appStoreUrl': appStoreUrl,
      if (androidApkUrl != null) 'androidApkUrl': androidApkUrl,
      if (windowsInstallerUrl != null) 'windowsInstallerUrl': windowsInstallerUrl,
      if (webUpdateUrl != null) 'webUpdateUrl': webUpdateUrl,
      if (releaseNotes != null) 'releaseNotes': releaseNotes,
    };
  }
  
  static AppVersionConfig defaultConfig() {
    return const AppVersionConfig(
      currentVersion: '1.0.0',
      minimumVersion: '1.0.0',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.techzoneit.bm_typer',
      androidApkUrl: 'https://www.techzoneit.top',
      windowsInstallerUrl: 'https://www.techzoneit.top',
      webUpdateUrl: 'https://www.techzoneit.top',
    );
  }
}

/// Service for checking app version and updates
class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Document reference for app config
  DocumentReference get _configRef => _firestore.collection('app_config').doc('version');
  
  /// Get current app version from package
  Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('❌ Error getting package info: $e');
      return '1.0.0';
    }
  }
  
  /// Get version config from Firestore
  Future<AppVersionConfig> getVersionConfig() async {
    try {
      final doc = await _configRef.get();
      if (doc.exists) {
        return AppVersionConfig.fromFirestore(doc);
      }
      return AppVersionConfig.defaultConfig();
    } catch (e) {
      debugPrint('❌ Error getting version config: $e');
      return AppVersionConfig.defaultConfig();
    }
  }
  
  /// Stream version config
  Stream<AppVersionConfig> streamVersionConfig() {
    return _configRef.snapshots().map((doc) {
      if (doc.exists) {
        return AppVersionConfig.fromFirestore(doc);
      }
      return AppVersionConfig.defaultConfig();
    });
  }
  
  /// Check if update is required
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final appVersion = await getCurrentAppVersion();
      final config = await getVersionConfig();
      
      debugPrint('📱 App version: $appVersion');
      debugPrint('📱 Latest version: ${config.currentVersion}');
      debugPrint('📱 Minimum version: ${config.minimumVersion}');
      
      // Check maintenance mode first
      if (config.maintenanceMode) {
        return UpdateCheckResult(
          status: UpdateStatus.maintenance,
          message: config.maintenanceMessage ?? 'অ্যাপটি মেইনটেন্যান্সে আছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।',
          actionLabel: 'ঠিক আছে',
        );
      }
      
      // Compare versions
      final currentVersionNum = _parseVersion(appVersion);
      final latestVersionNum = _parseVersion(config.currentVersion);
      final minimumVersionNum = _parseVersion(config.minimumVersion);
      final resolvedDownloadUrl = _getDownloadUrl(config);
      final resolvedActionLabel = _getActionLabel(config);
      
      // Force update required
      if (currentVersionNum < minimumVersionNum ||
          (config.forceUpdate && currentVersionNum < latestVersionNum)) {
        return UpdateCheckResult(
          status: UpdateStatus.forceUpdate,
          message: config.updateMessage ?? 'এই ভার্সন আর সাপোর্টেড নয়। অনুগ্রহ করে নতুন ভার্সন ইনস্টল করুন।',
          latestVersion: config.currentVersion,
          downloadUrl: resolvedDownloadUrl,
          actionLabel: resolvedActionLabel,
          releaseNotes: config.releaseNotes,
        );
      }
      
      // Optional update available
      if (currentVersionNum < latestVersionNum) {
        return UpdateCheckResult(
          status: UpdateStatus.updateAvailable,
          message: config.updateMessage ?? 'নতুন ভার্সন ${config.currentVersion} উপলব্ধ!',
          latestVersion: config.currentVersion,
          downloadUrl: resolvedDownloadUrl,
          actionLabel: resolvedActionLabel,
          releaseNotes: config.releaseNotes,
        );
      }
      
      // Up to date
      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        message: 'আপনার অ্যাপ আপ টু ডেট!',
        actionLabel: 'ঠিক আছে',
      );
    } catch (e) {
      debugPrint('❌ Error checking for update: $e');
      return UpdateCheckResult(
        status: UpdateStatus.error,
        message: 'আপডেট চেক করা যায়নি: $e',
        actionLabel: 'বন্ধ করুন',
      );
    }
  }
  
  /// Update version config (Admin only)
  Future<void> updateVersionConfig(AppVersionConfig config) async {
    try {
      await _configRef.set(config.toFirestore());
      debugPrint('✅ Version config updated');
    } catch (e) {
      debugPrint('❌ Error updating version config: $e');
      rethrow;
    }
  }
  
  /// Parse version string to comparable number
  int _parseVersion(String version) {
    try {
      final parts = version.split('.');
      final major = int.parse(parts[0]) * 10000;
      final minor = parts.length > 1 ? int.parse(parts[1]) * 100 : 0;
      final patch = parts.length > 2 ? int.parse(parts[2]) : 0;
      return major + minor + patch;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get download URL based on platform
  String? _getDownloadUrl(AppVersionConfig config) {
    if (kIsWeb) {
      return _firstNonEmpty([
        config.webUpdateUrl,
        config.windowsInstallerUrl,
        config.androidApkUrl,
      ]);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _firstNonEmpty([
          config.playStoreUrl,
          config.androidApkUrl,
          config.webUpdateUrl,
          config.windowsInstallerUrl,
        ]);
      case TargetPlatform.iOS:
        return _firstNonEmpty([
          config.appStoreUrl,
          config.webUpdateUrl,
        ]);
      case TargetPlatform.windows:
        return _firstNonEmpty([
          config.windowsInstallerUrl,
          config.webUpdateUrl,
        ]);
      default:
        return _firstNonEmpty([
          config.webUpdateUrl,
          config.windowsInstallerUrl,
          config.playStoreUrl,
          config.androidApkUrl,
        ]);
    }
  }

  String _getActionLabel(AppVersionConfig config) {
    if (kIsWeb) {
      return 'আপডেট পেজ খুলুন';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if ((config.playStoreUrl ?? '').isNotEmpty) {
          return 'Play Store খুলুন';
        }
        return 'APK ডাউনলোড করুন';
      case TargetPlatform.windows:
        return 'Windows Setup ডাউনলোড করুন';
      case TargetPlatform.iOS:
        return 'App Store খুলুন';
      default:
        return 'আপডেট পেজ খুলুন';
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

/// Update check status
enum UpdateStatus {
  upToDate,
  updateAvailable,
  forceUpdate,
  maintenance,
  error,
}

/// Result of update check
class UpdateCheckResult {
  final UpdateStatus status;
  final String message;
  final String? latestVersion;
  final String? downloadUrl;
  final String actionLabel;
  final String? releaseNotes;
  
  const UpdateCheckResult({
    required this.status,
    required this.message,
    this.latestVersion,
    this.downloadUrl,
    required this.actionLabel,
    this.releaseNotes,
  });
}

/// Provider for version service
final versionServiceProvider = Provider<VersionService>((ref) {
  return VersionService();
});

/// Provider for version config stream
final versionConfigProvider = StreamProvider<AppVersionConfig>((ref) {
  final service = ref.watch(versionServiceProvider);
  return service.streamVersionConfig();
});

/// Provider for update check
final updateCheckProvider = FutureProvider<UpdateCheckResult>((ref) {
  final service = ref.watch(versionServiceProvider);
  return service.checkForUpdate();
});

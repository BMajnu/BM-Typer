import 'dart:async';

import 'package:bm_typer/core/services/version_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

typedef DownloadUrlOpener = Future<bool> Function(Uri uri, String windowName);

enum WebDownloadPromptTarget {
  android,
  windows,
}

Future<bool> _defaultDownloadUrlOpener(Uri uri, String windowName) {
  return launchUrl(
    uri,
    webOnlyWindowName: windowName,
  );
}

@immutable
class WebDownloadPromptRecommendation {
  final WebDownloadPromptTarget target;
  final String title;
  final String message;
  final String actionLabel;
  final String downloadUrl;

  const WebDownloadPromptRecommendation({
    required this.target,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.downloadUrl,
  });
}

class WebDownloadPromptLogic {
  static const String bundledWindowsInstallerPath =
      '/downloads/BM-Typer-Setup.exe';

  static WebDownloadPromptRecommendation? resolveRecommendation({
    required bool isWeb,
    required TargetPlatform platform,
    required AppVersionConfig config,
  }) {
    if (!isWeb) {
      return null;
    }

    if (platform == TargetPlatform.windows) {
      final downloadUrl = resolveWindowsDownloadUrl(config);
      if (downloadUrl == null) {
        return null;
      }

      return WebDownloadPromptRecommendation(
        target: WebDownloadPromptTarget.windows,
        title: 'Windows অ্যাপ ব্যবহার করুন',
        message:
            'আপনি Windows থেকে ওয়েব ভার্সন ব্যবহার করছেন। আরও স্মুথ অভিজ্ঞতার জন্য BM Typer-এর setup ডাউনলোড করুন।',
        actionLabel: 'Windows Setup ডাউনলোড',
        downloadUrl: downloadUrl,
      );
    }

    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      final downloadUrl = _firstNonEmpty([
        config.androidApkUrl,
        config.playStoreUrl,
        config.webUpdateUrl,
      ]);
      if (downloadUrl == null) {
        return null;
      }

      return WebDownloadPromptRecommendation(
        target: WebDownloadPromptTarget.android,
        title: 'মোবাইলে অ্যাপটি ইনস্টল করুন',
        message:
            'মোবাইল ব্রাউজারের বদলে BM Typer-এর Android ভার্সন ব্যবহার করলে টাইপিং অভিজ্ঞতা আরও ভালো হবে।',
        actionLabel: 'Android ডাউনলোড',
        downloadUrl: downloadUrl,
      );
    }

    return null;
  }

  static String? resolveWindowsDownloadUrl(AppVersionConfig config) {
    final installerUrl = config.windowsInstallerUrl?.trim();

    if (isDirectDownloadUrl(installerUrl)) {
      return installerUrl;
    }

    return bundledWindowsInstallerPath;
  }

  static String dismissalKey({
    required WebDownloadPromptRecommendation recommendation,
    required AppVersionConfig config,
  }) {
    return 'web_download_prompt_${recommendation.target.name}_${config.currentVersion}';
  }

  static bool isDirectDownloadUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final normalizedValue = value.trim();
    final uri = Uri.tryParse(normalizedValue);
    final path = (uri?.path ?? normalizedValue).toLowerCase();

    return path.endsWith('.exe') ||
        path.endsWith('.msi') ||
        path.endsWith('.zip') ||
        path.endsWith('.apk') ||
        path.endsWith('.appinstaller') ||
        path.endsWith('.msix') ||
        path.endsWith('.msixbundle');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

class WebDownloadPrompt extends ConsumerStatefulWidget {
  final Widget child;
  final bool isWeb;
  final TargetPlatform? platformOverride;
  final DownloadUrlOpener openUrl;

  const WebDownloadPrompt({
    super.key,
    required this.child,
    this.isWeb = kIsWeb,
    this.platformOverride,
    this.openUrl = _defaultDownloadUrlOpener,
  });

  @override
  ConsumerState<WebDownloadPrompt> createState() => _WebDownloadPromptState();
}

class _WebDownloadPromptState extends ConsumerState<WebDownloadPrompt> {
  SharedPreferences? _prefs;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrefs());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _prefs = prefs;
      _prefsLoaded = true;
    });
  }

  Future<void> _dismissPrompt(String key) async {
    await _prefs?.setBool(key, true);
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openDownloadLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final launched = await widget.openUrl(
      uri,
      WebDownloadPromptLogic.isDirectDownloadUrl(url) ? '_self' : '_blank',
    );
    if (!mounted || launched) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ডাউনলোড লিংক খোলা যায়নি। পরে আবার চেষ্টা করুন।'),
        ),
      );
      return;
    }

    debugPrint('Web download launch failed for url: $url');
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(versionConfigProvider);
    final config = configAsync.maybeWhen(
      data: (value) => value,
      orElse: AppVersionConfig.defaultConfig,
    );
    final platform = widget.platformOverride ?? defaultTargetPlatform;
    final recommendation = WebDownloadPromptLogic.resolveRecommendation(
      isWeb: widget.isWeb,
      platform: platform,
      config: config,
    );

    if (!_prefsLoaded || recommendation == null) {
      return widget.child;
    }

    final dismissalKey = WebDownloadPromptLogic.dismissalKey(
      recommendation: recommendation,
      config: config,
    );
    final isDismissed = _prefs?.getBool(dismissalKey) ?? false;

    if (isDismissed) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _PromptCard(
                  recommendation: recommendation,
                  onDownload: () =>
                      _openDownloadLink(recommendation.downloadUrl),
                  onDismiss: () => _dismissPrompt(dismissalKey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  final WebDownloadPromptRecommendation recommendation;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  const _PromptCard({
    required this.recommendation,
    required this.onDownload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = recommendation.target == WebDownloadPromptTarget.android;
    final accentColor =
        isAndroid ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);
    final iconData =
        isAndroid ? Icons.phone_android_rounded : Icons.desktop_windows_rounded;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0141B2D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 470;
              final infoSection = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconData, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recommendation.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recommendation.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFCBD5E1),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionButton = FilledButton.icon(
                onPressed: onDownload,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(recommendation.actionLabel),
              );

              if (isCompact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: infoSection),
                        IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: actionButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: infoSection),
                  const SizedBox(width: 14),
                  actionButton,
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

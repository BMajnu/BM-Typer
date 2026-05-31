enum UpdateInstallMode {
  none,
  externalUrl,
  inAppApk,
}

class UpdateInstallPlan {
  final UpdateInstallMode mode;
  final String? url;
  final String actionLabel;

  const UpdateInstallPlan({
    required this.mode,
    required this.url,
    required this.actionLabel,
  });
}

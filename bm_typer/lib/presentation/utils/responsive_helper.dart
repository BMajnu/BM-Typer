import 'package:flutter/material.dart';

/// Helper class to manage responsive layout breakpoints and constants
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Height Breakpoints
  static const double ultraCompactHeight = 500;
  static const double compactHeight = 700;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
  
  // Custom check for "Small Desktop" vs "Large Desktop" if needed
  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Returns true if the screen height is very limited (e.g. landscape mobile)
  /// In this mode, we should hide headers/footers/extras to focus on typing.
  static bool isUltraCompactHeight(BuildContext context) =>
      MediaQuery.of(context).size.height < ultraCompactHeight;

  /// Returns true if the screen height is somewhat limited
  static bool isCompactHeight(BuildContext context) =>
      MediaQuery.of(context).size.height < compactHeight;
  
  // Layout Constants
  static const double sidebarWidth = 280.0;
  static const double maxContentWidth = 1000.0;
  
  /// Get responsive value based on screen size
  static T getValue<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return desktop;
  }
}

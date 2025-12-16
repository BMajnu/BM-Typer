/// স্পেসিং এবং সাইজিং টোকেন - BM Typer
/// 
/// কনসিস্টেন্ট স্পেসিং এবং সাইজিং এর জন্য ডিজাইন টোকেন।
class AppSpacing {
  AppSpacing._();

  // ============================================
  // SPACING SCALE (4px base unit)
  // ============================================
  
  /// 2px - Extra extra small
  static const double xxs = 2;
  
  /// 4px - Extra small
  static const double xs = 4;
  
  /// 8px - Small
  static const double sm = 8;
  
  /// 12px - Medium small
  static const double md = 12;
  
  /// 16px - Medium
  static const double lg = 16;
  
  /// 20px - Medium large
  static const double xl = 20;
  
  /// 24px - Large
  static const double xxl = 24;
  
  /// 32px - Extra large
  static const double xxxl = 32;
  
  /// 40px - Extra extra large
  static const double xxxxl = 40;
  
  /// 48px - Huge
  static const double huge = 48;
  
  /// 64px - Massive
  static const double massive = 64;

  // ============================================
  // COMPONENT SPACING
  // ============================================
  
  /// Card padding
  static const double cardPadding = 16;
  
  /// Card padding compact
  static const double cardPaddingCompact = 12;
  
  /// Section spacing
  static const double sectionSpacing = 24;
  
  /// Page margin (horizontal)
  static const double pageMargin = 16;
  
  /// Page margin large screens
  static const double pageMarginLarge = 24;
  
  /// List item spacing
  static const double listItemSpacing = 12;
  
  /// Inline spacing (between inline elements)
  static const double inlineSpacing = 8;

  // ============================================
  // SCREEN SAFE AREAS
  // ============================================
  
  /// Top safe area padding
  static const double safeAreaTop = 16;
  
  /// Bottom safe area padding
  static const double safeAreaBottom = 24;
}

/// সাইজ কনস্ট্যান্ট
class AppSizes {
  AppSizes._();

  // ============================================
  // BORDER RADIUS
  // ============================================
  
  /// 4px - Extra small radius
  static const double radiusXs = 4;
  
  /// 8px - Small radius
  static const double radiusSm = 8;
  
  /// 12px - Medium radius
  static const double radiusMd = 12;
  
  /// 16px - Large radius
  static const double radiusLg = 16;
  
  /// 20px - Extra large radius
  static const double radiusXl = 20;
  
  /// 24px - Extra extra large radius
  static const double radiusXxl = 24;
  
  /// Full rounded (circular)
  static const double radiusFull = 9999;

  // ============================================
  // ICON SIZES
  // ============================================
  
  /// 16px - Small icon
  static const double iconSm = 16;
  
  /// 20px - Default icon
  static const double iconMd = 20;
  
  /// 24px - Large icon
  static const double iconLg = 24;
  
  /// 32px - Extra large icon
  static const double iconXl = 32;
  
  /// 48px - Huge icon
  static const double iconHuge = 48;

  // ============================================
  // BUTTON SIZES
  // ============================================
  
  /// Small button height
  static const double buttonHeightSm = 32;
  
  /// Medium button height
  static const double buttonHeightMd = 40;
  
  /// Large button height
  static const double buttonHeightLg = 48;
  
  /// Extra large button height
  static const double buttonHeightXl = 56;

  // ============================================
  // INPUT SIZES
  // ============================================
  
  /// Default input height
  static const double inputHeight = 48;
  
  /// Compact input height
  static const double inputHeightCompact = 40;

  // ============================================
  // CARD SIZES
  // ============================================
  
  /// Stats card min width
  static const double statsCardMinWidth = 100;
  
  /// Stats card max width
  static const double statsCardMaxWidth = 160;
  
  /// Achievement badge size
  static const double achievementBadgeSize = 64;
  
  /// Avatar size small
  static const double avatarSm = 32;
  
  /// Avatar size medium
  static const double avatarMd = 48;
  
  /// Avatar size large
  static const double avatarLg = 64;
  
  /// Avatar size extra large
  static const double avatarXl = 96;

  // ============================================
  // KEYBOARD SIZES
  // ============================================
  
  /// Keyboard key size
  static const double keySize = 48;
  
  /// Keyboard key size compact
  static const double keySizeCompact = 40;
  
  /// Keyboard key spacing
  static const double keySpacing = 4;
  
  /// Keyboard max width
  static const double keyboardMaxWidth = 800;

  // ============================================
  // TYPING AREA SIZES
  // ============================================
  
  /// Typing area min height
  static const double typingAreaMinHeight = 120;
  
  /// Typing area max width
  static const double typingAreaMaxWidth = 900;

  // ============================================
  // BREAKPOINTS
  // ============================================
  
  /// Mobile breakpoint
  static const double breakpointMobile = 600;
  
  /// Tablet breakpoint
  static const double breakpointTablet = 900;
  
  /// Desktop breakpoint
  static const double breakpointDesktop = 1200;
  
  /// Wide desktop breakpoint
  static const double breakpointWide = 1536;

  // ============================================
  // ELEVATION/SHADOWS
  // ============================================
  
  /// Low elevation
  static const double elevationLow = 2;
  
  /// Medium elevation
  static const double elevationMedium = 4;
  
  /// High elevation
  static const double elevationHigh = 8;
  
  /// Extra high elevation
  static const double elevationExtraHigh = 16;
}

/// অ্যানিমেশন ডিউরেশন কনস্ট্যান্ট
class AppDurations {
  AppDurations._();

  /// Extra fast animation (100ms)
  static const Duration extraFast = Duration(milliseconds: 100);
  
  /// Fast animation (150ms)
  static const Duration fast = Duration(milliseconds: 150);
  
  /// Normal animation (200ms)
  static const Duration normal = Duration(milliseconds: 200);
  
  /// Medium animation (300ms)
  static const Duration medium = Duration(milliseconds: 300);
  
  /// Slow animation (400ms)
  static const Duration slow = Duration(milliseconds: 400);
  
  /// Extra slow animation (500ms)
  static const Duration extraSlow = Duration(milliseconds: 500);
  
  /// Page transition (300ms)
  static const Duration pageTransition = Duration(milliseconds: 300);
}

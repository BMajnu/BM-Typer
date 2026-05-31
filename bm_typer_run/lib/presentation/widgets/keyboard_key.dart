import 'package:flutter/material.dart';
import 'package:bm_typer/core/theme/theme.dart';

enum KeyHand { left, right, neutral }

/// আধুনিক কীবোর্ড কী উইজেট
/// 
/// গ্র্যাডিয়েন্ট এবং উন্নত অ্যানিমেশন সহ।
class KeyboardKey extends StatelessWidget {
  final String character;
  final bool isPressed;
  final bool isHighlighted;
  final double height;
  final double? width;
  final VoidCallback? onTap;

  const KeyboardKey({
    super.key,
    required this.character,
    this.isPressed = false,
    this.isHighlighted = false,
    this.height = 40.0,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Determine key type and hand
    KeyHand hand = KeyHand.neutral;
    bool isSpecial = false;

    if ('asdfgzxcvb'.contains(character.toLowerCase())) {
      hand = KeyHand.left;
    } else if ("hjkl;'nm,./".contains(character.toLowerCase())) {
      hand = KeyHand.right;
    }

    if (character == 'shift' || character == '⌫' || character == ' ') {
      isSpecial = true;
    }

    // Determine colors based on state
    Color backgroundColor;
    Color textColor;
    List<BoxShadow> shadows = [];

    if (isPressed) {
      // Pressed state - bright color
      backgroundColor = colorScheme.primary;
      textColor = Colors.white;
    } else if (isHighlighted) {
      // Highlighted state - glowing effect
      backgroundColor = isDarkMode 
          ? AppColors.keyHighlightDark 
          : AppColors.keyHighlightLight;
      textColor = isDarkMode ? Colors.white : colorScheme.primary;
      shadows = [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.5),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    } else {
      // Normal state - hand-based colors
      switch (hand) {
        case KeyHand.left:
          backgroundColor = isDarkMode
              ? AppColors.keyLeftHandDark
              : AppColors.keyLeftHandLight;
          textColor = isDarkMode ? Colors.white : AppColors.textPrimaryLight;
        case KeyHand.right:
          backgroundColor = isDarkMode
              ? AppColors.keyRightHandDark
              : AppColors.keyRightHandLight;
          textColor = isDarkMode ? Colors.white : AppColors.textPrimaryLight;
        case KeyHand.neutral:
          backgroundColor = isDarkMode
              ? AppColors.keyNeutralDark
              : AppColors.keyNeutralLight;
          textColor = isDarkMode
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight;
      }
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ];
    }

    // Calculate width
    final keyWidth = width ??
        (character == 'shift' ? 70.0 : (character == '⌫' ? 80.0 : 45.0));

    // Get display label
    String displayLabel = character;
    if (character == 'shift') displayLabel = '⇧';
    if (character == ' ') displayLabel = 'SPACE';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        width: keyWidth,
        height: height,
        margin: EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          gradient: isPressed || isHighlighted
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.8),
                  ],
                )
              : null,
          color: isPressed || isHighlighted ? null : backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isHighlighted
                ? colorScheme.primary
                : Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: isPressed ? [] : shadows,
        ),
        transform: isPressed ? Matrix4.translationValues(0, 2, 0) : null,
        transformAlignment: Alignment.center,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayLabel,
              style: TextStyle(
                fontSize: isSpecial ? 12 : 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// বাংলা কী উইজেট - দুই লেয়ার লেবেল সহ
class BanglaKeyboardKey extends StatelessWidget {
  final String normalLabel;
  final String? shiftLabel;
  final bool isPressed;
  final bool isHighlighted;
  final bool isShiftActive;
  final double height;
  final double? width;
  final VoidCallback? onTap;

  const BanglaKeyboardKey({
    super.key,
    required this.normalLabel,
    this.shiftLabel,
    this.isPressed = false,
    this.isHighlighted = false,
    this.isShiftActive = false,
    this.height = 50.0,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Determine colors
    Color backgroundColor;
    Color primaryTextColor;
    Color secondaryTextColor;

    if (isPressed) {
      backgroundColor = colorScheme.primary;
      primaryTextColor = Colors.white;
      secondaryTextColor = Colors.white.withOpacity(0.7);
    } else if (isHighlighted) {
      backgroundColor = isDarkMode
          ? AppColors.keyHighlightDark
          : AppColors.keyHighlightLight;
      primaryTextColor = isDarkMode ? Colors.white : colorScheme.primary;
      secondaryTextColor = colorScheme.primary.withOpacity(0.7);
    } else {
      backgroundColor = isDarkMode
          ? AppColors.keyNeutralDark
          : AppColors.keyNeutralLight;
      primaryTextColor = isDarkMode
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight;
      secondaryTextColor = isDarkMode
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight;
    }

    // Active label based on shift state
    final activeLabel = isShiftActive && shiftLabel != null
        ? shiftLabel!
        : normalLabel;
    final inactiveLabel = isShiftActive ? normalLabel : shiftLabel;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: width ?? 50.0,
        height: height,
        margin: EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          gradient: isHighlighted
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.7),
                  ],
                )
              : null,
          color: isHighlighted ? null : backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isHighlighted
                ? colorScheme.primary
                : Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: isHighlighted
                        ? colorScheme.primary.withOpacity(0.4)
                        : Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: isHighlighted ? 8 : 4,
                  ),
                ],
        ),
        transform: isPressed ? Matrix4.translationValues(0, 2, 0) : null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Secondary label (shift or normal depending on state)
                if (inactiveLabel != null && inactiveLabel.isNotEmpty)
                  Text(
                    inactiveLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                    ),
                  ),
                // Primary label
                Text(
                  activeLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
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

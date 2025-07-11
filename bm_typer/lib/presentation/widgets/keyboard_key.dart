import 'package:flutter/material.dart';

enum KeyHand { left, right, neutral }

class KeyboardKey extends StatelessWidget {
  final String character;
  final bool isPressed;
  final double height;
  final double? width;

  const KeyboardKey({
    super.key,
    required this.character,
    this.isPressed = false,
    this.height = 35.0,
    this.width,
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
    } else if ('hjkl;\'nm,./'.contains(character.toLowerCase())) {
      hand = KeyHand.right;
    }

    if (character == 'shift' || character == '⌫' || character == ' ') {
      isSpecial = true;
    }

    // Determine background color based on hand
    Color backgroundColor;
    switch (hand) {
      case KeyHand.left:
        backgroundColor = isDarkMode
            ? colorScheme.primary.withOpacity(0.6)
            : colorScheme.primaryContainer.withOpacity(0.7);
      case KeyHand.right:
        backgroundColor = isDarkMode
            ? colorScheme.tertiary.withOpacity(0.6)
            : colorScheme.tertiaryContainer.withOpacity(0.7);
      case KeyHand.neutral:
        backgroundColor =
            isDarkMode ? colorScheme.surfaceVariant : colorScheme.surface;
    }

    // Override color if pressed
    if (isPressed) {
      backgroundColor = isDarkMode ? Colors.white : colorScheme.primary;
    }

    // Calculate width based on character
    final keyWidth = width ??
        (character == 'shift' ? 70.0 : (character == '⌫' ? 80.0 : 45.0));

    final borderColor = colorScheme.outline.withOpacity(0.2);
    final textColor =
        isDarkMode ? colorScheme.onSurface : colorScheme.onSurfaceVariant;
    final displayTextColor = isPressed && isDarkMode
        ? Colors.black
        : (isPressed ? colorScheme.onPrimary : textColor);

    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor),
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 3,
              ),
            ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: keyWidth,
      height: height,
      margin: const EdgeInsets.all(2),
      decoration: decoration,
      transform: isPressed ? Matrix4.translationValues(0, 2, 0) : null,
      transformAlignment: Alignment.center,
      child: Center(
        child: Text(
          character,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
            color: displayTextColor,
          ),
        ),
      ),
    );
  }
}

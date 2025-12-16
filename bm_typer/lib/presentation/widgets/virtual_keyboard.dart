import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/presentation/widgets/keyboard_key.dart';

/// আধুনিক ভার্চুয়াল কীবোর্ড
/// 
/// গ্লাসমরফিজম এবং হ্যান্ড-ভিত্তিক কালার কোডিং সহ।
class VirtualKeyboard extends StatelessWidget {
  final Set<String> pressedKeys;
  final String? highlightedKey;

  const VirtualKeyboard({
    super.key,
    required this.pressedKeys,
    this.highlightedKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardWidth = constraints.maxWidth;
        final keyboardHeight = constraints.maxHeight;

        // Calculate responsive key sizes
        final baseKeyWidth = (keyboardWidth - 60) / 14;
        final keyHeight = (keyboardHeight - 40) / 4.5;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: keyboardWidth,
              height: keyboardHeight,
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          AppColors.glassWhiteDark.withOpacity(0.1),
                          AppColors.glassWhiteDark.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: isDarkMode
                      ? AppColors.glassBorderDark
                      : AppColors.glassBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? AppColors.glassShadowDark
                        : AppColors.glassShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTopRow(baseKeyWidth, keyHeight),
                  _buildHomeRow(baseKeyWidth, keyHeight),
                  _buildBottomRow(baseKeyWidth, keyHeight),
                  _buildSpaceRow(baseKeyWidth, keyHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRow(double keyWidth, double keyHeight) {
    final characters = ['`','1','2','3','4','5','6','7','8','9','0','-','=','⌫'];
    return _buildKeyboardRow(characters, keyWidth, keyHeight);
  }

  Widget _buildHomeRow(double keyWidth, double keyHeight) {
    final characters = ['q','w','e','r','t','y','u','i','o','p','[',']','\\'];
    return _buildKeyboardRow(characters, keyWidth, keyHeight);
  }

  Widget _buildBottomRow(double keyWidth, double keyHeight) {
    final characters = ['a','s','d','f','g','h','j','k','l',';','\''];
    return Padding(
      padding: EdgeInsets.only(left: keyWidth * 0.5),
      child: _buildKeyboardRow(characters, keyWidth, keyHeight),
    );
  }

  Widget _buildSpaceRow(double keyWidth, double keyHeight) {
    final characters = ['shift','z','x','c','v','b','n','m',',','.','/','shift'];
    return _buildKeyboardRow(characters, keyWidth, keyHeight);
  }

  Widget _buildKeyboardRow(List<String> keys, double keyWidth, double keyHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((char) {
        // Special key widths
        double width = keyWidth;
        if (char == '⌫') width = keyWidth * 1.8;
        if (char == 'shift') width = keyWidth * 1.5;
        if (char == '\\') width = keyWidth * 1.2;

        final isPressed = pressedKeys.contains(char);
        final isHighlighted = highlightedKey?.toLowerCase() == char.toLowerCase();

        return KeyboardKey(
          character: char,
          isPressed: isPressed,
          isHighlighted: isHighlighted,
          height: keyHeight,
          width: width,
        );
      }).toList(),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/presentation/widgets/keyboard_key.dart' as common;

/// আধুনিক বাংলা ভার্চুয়াল কীবোর্ড
/// 
/// গ্লাসমরফিজম, হ্যান্ড-বেইজড কালার কোডিং এবং উন্নত লেআউট সহ।
/// প্রতিটি কী এবং রো Flexible/Expanded উইজেট দিয়ে র‍্যাপ করা হয়েছে যাতে কোনো ওভারফ্লো না হয়।
class BanglaVirtualKeyboard extends ConsumerWidget {
  final Set<String> pressedKeys;
  final Function(String)? onKeyPressed;
  final bool showLayoutSwitcher;

  const BanglaVirtualKeyboard({
    super.key,
    required this.pressedKeys,
    this.onKeyPressed,
    this.showLayoutSwitcher = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(keyboardLayoutProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final keyboardWidth = constraints.maxWidth;
      // Use the full available height provided by the parent
      final keyboardHeight = constraints.maxHeight; 
      
      // Only show layout switcher if there is enough vertical space
      final isSpaceSufficientForSwitcher = keyboardHeight > 180;

      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: keyboardWidth,
            height: keyboardHeight,
            padding: EdgeInsets.all(AppSpacing.xs), 
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                      ? [
                          AppColors.glassWhiteDark.withOpacity(0.15),
                          AppColors.glassWhiteDark.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.85),
                          Colors.white.withOpacity(0.65),
                        ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
              ),
              boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.glassShadowDark
                        : AppColors.glassShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
            ),
            child: Column(
              children: [
                // Layout switcher header with glass effect
                if (showLayoutSwitcher && isSpaceSufficientForSwitcher)
                  SizedBox(
                    height: 40, // Fixed height for switcher
                    child: _buildLayoutSwitcher(context, ref, layoutState),
                  ),
                
                if (showLayoutSwitcher && isSpaceSufficientForSwitcher)
                  SizedBox(height: AppSpacing.xs), // Minimal spacing

                // Keyboard Content - Expanded to fill remaining space
                Expanded(
                  child: _buildKeyboardContent(context, ref, layoutState),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLayoutSwitcher(
    BuildContext context,
    WidgetRef ref,
    KeyboardLayoutState layoutState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2, // Minimal vertical padding
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.surfaceDark.withOpacity(0.5) 
            : AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current layout indicator
          Row(
            children: [
              Icon(
                layoutState.isBengali ? Icons.language : Icons.keyboard,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                layoutState.layoutName,
                style: AppTypography.labelSmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Layout buttons - 3 layouts: QWERTY, Bijoy, Phonetic
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLayoutButton(
                context,
                ref,
                'EN',
                KeyboardLayout.qwerty,
                layoutState,
                isFirst: true,
              ),
              _buildLayoutButton(
                context,
                ref,
                'বি',
                KeyboardLayout.bijoy,
                layoutState,
              ),
              _buildLayoutButton(
                context,
                ref,
                'ফ',
                KeyboardLayout.phonetic,
                layoutState,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    KeyboardLayout layout,
    KeyboardLayoutState currentState, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isActive = currentState.currentLayout == layout;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ref.read(keyboardLayoutProvider.notifier).setLayout(layout);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? Radius.circular(AppSizes.radiusSm) : Radius.zero,
            right: isLast ? Radius.circular(AppSizes.radiusSm) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardContent(
    BuildContext context,
    WidgetRef ref,
    KeyboardLayoutState layoutState,
  ) {
    final rows = layoutState.getDisplayRows();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
          for (int i = 0; i < rows.length; i++)
          Expanded( // Make each row expand to fill vertical space
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: _buildKeyboardRow(
                context,
                ref,
                rows[i],
                layoutState,
              ),
            ),
          ),
        
        // Space bar row also expanded
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: _buildSpaceRow(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardRow(
    BuildContext context,
    WidgetRef ref,
    List<String> keys,
    KeyboardLayoutState layoutState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure keys stretch vertically
      children: keys.map((char) {
        // Flex factors for different keys
        int flex = 10;
        if (char == '⌫') flex = 18; // 1.8x
        if (char == 'shift') flex = 15; // 1.5x
        if (char == '\\') flex = 12; // 1.2x

        final isPressed = pressedKeys.contains(char) ||
            (char == 'shift' && layoutState.isShiftPressed);

        // Get labels for Bengali key
        String normalLabel = char;

        return Flexible(
          flex: flex,
          child: common.BanglaKeyboardKey(
            normalLabel: normalLabel,
            shiftLabel: null,
            isPressed: isPressed,
            isShiftActive: layoutState.isShiftPressed,
            height: double.infinity, // Fill the row height
            // Width is handled by Flexible + Container inside KeyboardKey
            width: double.infinity, 
            onTap: () {
              if (char == 'shift') {
                ref.read(keyboardLayoutProvider.notifier).setShift(!layoutState.isShiftPressed);
              } else if (char == '⌫') {
                onKeyPressed?.call('\b');
              } else {
                onKeyPressed?.call(char);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpaceRow(
    BuildContext context, 
    WidgetRef ref, 
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure keys stretch vertically
      children: [
        // Language - Flex 1.5
         Flexible(
           flex: 15,
           child: GestureDetector(
            onTap: () => ref.read(keyboardLayoutProvider.notifier).toggleLayout(),
            child: Container(
              height: double.infinity,
              margin: EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
              ),
              child: Center(
                child: Icon(Icons.language, color: AppColors.secondary, size: 18),
              ),
            ),
                   ),
         ),

        // Space - Flex 6
        Flexible(
          flex: 60,
          child: GestureDetector(
            onTap: () => onKeyPressed?.call(' '),
            child: Container(
              height: double.infinity,
              margin: EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceLight,
                    AppColors.backgroundLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'SPACE', 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Enter - Flex 2
        Flexible(
          flex: 20,
          child: GestureDetector(
            onTap: () => onKeyPressed?.call('\n'),
            child: Container(
              height: double.infinity,
              margin: EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Center(
                child: Icon(Icons.keyboard_return, color: AppColors.primary, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

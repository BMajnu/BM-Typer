import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';

/// বাংলা Virtual Keyboard Widget
/// Supports Bijoy, Probhat, and QWERTY layouts
/// Cross-platform compatible (Windows, Mac, Linux, Web, Mobile)
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
    final colorScheme = Theme.of(context).colorScheme;
    final layoutState = ref.watch(keyboardLayoutProvider);

    final keyHeight = 38.0;
    final rowSpacing = 4.0;
    final keySpacing = 3.0;

    return LayoutBuilder(builder: (context, constraints) {
      final keyboardWidth = constraints.maxWidth;
      final keyboardHeight = constraints.maxHeight;

      // Calculate row heights including header
      final headerHeight = showLayoutSwitcher ? 36.0 : 0.0;
      final availableHeight = keyboardHeight - headerHeight;
      final totalRowHeight = keyHeight * 4 + rowSpacing * 3;

      final heightScale = totalRowHeight > availableHeight
          ? availableHeight / totalRowHeight
          : 1.0;
      final scaledKeyHeight = keyHeight * heightScale;

      final rows = layoutState.getDisplayRows();

      return Container(
        width: keyboardWidth,
        height: keyboardHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layout switcher header
            if (showLayoutSwitcher)
              _buildLayoutSwitcher(context, ref, layoutState),

            // Keyboard rows
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: keySpacing,
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: keyboardWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < rows.length; i++) ...[
                          _buildKeyboardRow(
                            context,
                            ref,
                            rows[i],
                            scaledKeyHeight,
                            keySpacing,
                            isHomeRow: i == 2, // Middle row
                            layoutState: layoutState,
                          ),
                          if (i < rows.length - 1)
                            SizedBox(height: rowSpacing * heightScale),
                        ],
                        // Space bar row
                        SizedBox(height: rowSpacing * heightScale),
                        _buildSpaceBarRow(context, ref, scaledKeyHeight, keySpacing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build layout switcher header
  Widget _buildLayoutSwitcher(
    BuildContext context,
    WidgetRef ref,
    KeyboardLayoutState layoutState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                layoutState.layoutName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),

          // Layout switch buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLayoutButton(
                context,
                ref,
                'EN',
                KeyboardLayout.qwerty,
                layoutState,
              ),
              const SizedBox(width: 4),
              _buildLayoutButton(
                context,
                ref,
                'বি',
                KeyboardLayout.bijoy,
                layoutState,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual layout button
  Widget _buildLayoutButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    KeyboardLayout layout,
    KeyboardLayoutState currentState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = currentState.currentLayout == layout;

    return GestureDetector(
      onTap: () {
        ref.read(keyboardLayoutProvider.notifier).setLayout(layout);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Build keyboard row
  Widget _buildKeyboardRow(
    BuildContext context,
    WidgetRef ref,
    List<String> keys,
    double keyHeight,
    double keySpacing, {
    bool isHomeRow = false,
    double leftPadding = 0,
    required KeyboardLayoutState layoutState,
  }) {
    final keyWidgets = <Widget>[];

    if (leftPadding > 0) {
      keyWidgets.add(SizedBox(width: leftPadding));
    }

    for (int i = 0; i < keys.length; i++) {
      final char = keys[i];

      // Special handling for wider keys
      double widthMultiplier = 1.0;
      if (char == '⌫') widthMultiplier = 1.8;
      if (char == 'shift') widthMultiplier = 1.4;

      final isPressed = pressedKeys.contains(char) ||
          (char == 'shift' && layoutState.isShiftPressed);

      keyWidgets.add(
        Flexible(
          flex: (widthMultiplier * 10).toInt(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: keySpacing / 2),
            child: GestureDetector(
              onTapDown: (_) => _handleKeyPress(ref, char),
              onTapUp: (_) => _handleKeyRelease(ref, char),
              onTapCancel: () => _handleKeyRelease(ref, char),
              child: BanglaKeyboardKey(
                character: char,
                isPressed: isPressed,
                height: keyHeight,
                isHomeRow: isHomeRow,
                isBengali: layoutState.isBengali,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keyWidgets,
    );
  }

  /// Build space bar row
  Widget _buildSpaceBarRow(
    BuildContext context,
    WidgetRef ref,
    double keyHeight,
    double keySpacing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Language toggle key
        GestureDetector(
          onTap: () {
            ref.read(keyboardLayoutProvider.notifier).toggleLayout();
          },
          child: Container(
            width: 50,
            height: keyHeight,
            margin: EdgeInsets.symmetric(horizontal: keySpacing),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.language, size: 18),
            ),
          ),
        ),

        // Space bar
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () => onKeyPressed?.call(' '),
            child: Container(
              height: keyHeight,
              margin: EdgeInsets.symmetric(horizontal: keySpacing),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: const Center(
                child: Text('Space', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ),

        // Enter key
        GestureDetector(
          onTap: () => onKeyPressed?.call('\n'),
          child: Container(
            width: 60,
            height: keyHeight,
            margin: EdgeInsets.symmetric(horizontal: keySpacing),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.keyboard_return, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  /// Handle key press
  void _handleKeyPress(WidgetRef ref, String key) {
    if (key == 'shift') {
      ref.read(keyboardLayoutProvider.notifier).setShift(true);
    } else if (key != '⌫') {
      onKeyPressed?.call(key);
    }
  }

  /// Handle key release
  void _handleKeyRelease(WidgetRef ref, String key) {
    if (key == 'shift') {
      ref.read(keyboardLayoutProvider.notifier).setShift(false);
    } else if (key == '⌫') {
      onKeyPressed?.call('\b'); // Backspace
    }
  }
}

/// Bengali Keyboard Key widget
class BanglaKeyboardKey extends StatelessWidget {
  final String character;
  final bool isPressed;
  final double height;
  final double? width;
  final bool isHomeRow;
  final bool isBengali;

  const BanglaKeyboardKey({
    super.key,
    required this.character,
    this.isPressed = false,
    this.height = 38.0,
    this.width,
    this.isHomeRow = false,
    this.isBengali = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Special keys
    final isSpecial =
        character == 'shift' || character == '⌫' || character == ' ';

    // Determine background color
    Color backgroundColor;
    if (isPressed) {
      backgroundColor = colorScheme.primary;
    } else if (isHomeRow && !isSpecial) {
      // Highlight home row keys
      backgroundColor = isDarkMode
          ? colorScheme.primaryContainer.withOpacity(0.4)
          : colorScheme.primaryContainer.withOpacity(0.6);
    } else if (isSpecial) {
      backgroundColor = colorScheme.secondaryContainer;
    } else {
      backgroundColor = isDarkMode
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surface;
    }

    // Calculate width
    final keyWidth = width ??
        (character == 'shift' ? 55.0 : (character == '⌫' ? 65.0 : 40.0));

    final textColor = isPressed
        ? colorScheme.onPrimary
        : (isDarkMode ? colorScheme.onSurface : colorScheme.onSurfaceVariant);

    // Display text
    String displayText = character;
    if (character == 'shift') {
      displayText = '⇧';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: keyWidth,
      height: height,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.15),
        ),
        boxShadow: isPressed
            ? []
            : [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 2,
                ),
              ],
      ),
      transform: isPressed ? Matrix4.translationValues(0, 1, 0) : null,
      transformAlignment: Alignment.center,
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: isBengali && !isSpecial ? 16 : 13,
            fontWeight: isSpecial || isHomeRow ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

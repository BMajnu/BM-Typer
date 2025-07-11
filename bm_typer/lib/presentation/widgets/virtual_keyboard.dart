import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bm_typer/presentation/widgets/keyboard_key.dart';

class VirtualKeyboard extends StatelessWidget {
  final Set<String> pressedKeys;

  const VirtualKeyboard({
    Key? key,
    required this.pressedKeys,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Make key height responsive to container height
    final keyHeight = 35.0; // Fixed height for keys
    final rowSpacing = 4.0;
    final keySpacing = 4.0;

    return LayoutBuilder(builder: (context, constraints) {
      final keyboardWidth = constraints.maxWidth;
      final keyboardHeight = constraints.maxHeight;

      // Calculate row heights
      final totalRowHeight = keyHeight * 4 + rowSpacing * 3;

      // If totalRowHeight is greater than keyboardHeight, we need to adjust
      final heightScale = totalRowHeight > keyboardHeight
          ? keyboardHeight / totalRowHeight
          : 1.0;
      final scaledKeyHeight = keyHeight * heightScale;

      return Container(
        width: keyboardWidth,
        height: keyboardHeight,
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: keySpacing),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: keyboardWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Use minimum space needed
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTopRow(context, scaledKeyHeight, keySpacing),
                SizedBox(height: rowSpacing * heightScale),
                _buildMiddleRow(context, scaledKeyHeight, keySpacing),
                SizedBox(height: rowSpacing * heightScale),
                _buildBottomRow(context, scaledKeyHeight, keySpacing),
                SizedBox(height: rowSpacing * heightScale),
                _buildSpaceRow(context, scaledKeyHeight, keySpacing),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopRow(
      BuildContext context, double keyHeight, double keySpacing) {
    final characters = [
      '`',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '0',
      '-',
      '=',
      '⌫'
    ];
    return _buildKeyboardRow(context, characters, keyHeight, keySpacing);
  }

  Widget _buildMiddleRow(
      BuildContext context, double keyHeight, double keySpacing) {
    final characters = [
      'q',
      'w',
      'e',
      'r',
      't',
      'y',
      'u',
      'i',
      'o',
      'p',
      '[',
      ']',
      '\\'
    ];
    return _buildKeyboardRow(context, characters, keyHeight, keySpacing);
  }

  Widget _buildBottomRow(
      BuildContext context, double keyHeight, double keySpacing) {
    final characters = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\''];
    return _buildKeyboardRow(context, characters, keyHeight, keySpacing,
        leftPadding: 20);
  }

  Widget _buildSpaceRow(
      BuildContext context, double keyHeight, double keySpacing) {
    final characters = [
      'shift',
      'z',
      'x',
      'c',
      'v',
      'b',
      'n',
      'm',
      ',',
      '.',
      '/',
      'shift'
    ];
    return _buildKeyboardRow(context, characters, keyHeight, keySpacing);
  }

  Widget _buildKeyboardRow(BuildContext context, List<String> keys,
      double keyHeight, double keySpacing,
      {double leftPadding = 0}) {
    final keyWidgets = <Widget>[];

    if (leftPadding > 0) {
      keyWidgets.add(SizedBox(width: leftPadding));
    }

    for (int i = 0; i < keys.length; i++) {
      final char = keys[i];

      // Special handling for wider keys
      double widthMultiplier = 1.0;
      if (char == '⌫') widthMultiplier = 2.0;
      if (char == 'shift') widthMultiplier = 1.5;

      final isPressed = pressedKeys.contains(char);

      keyWidgets.add(
        Flexible(
          flex: (widthMultiplier * 10).toInt(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: keySpacing / 2),
            child: KeyboardKey(
              character: char,
              isPressed: isPressed,
              height: keyHeight,
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
}

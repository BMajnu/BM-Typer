import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/constants/app_text_styles.dart';
import 'package:bm_typer/core/models/lesson_model.dart';

class TypingArea extends StatelessWidget {
  final String text;
  final int currentIndex;
  final List<int> incorrectIndices;
  final bool isFocused;
  final VoidCallback onTap;
  final ExerciseType exerciseType;
  final String? source;

  const TypingArea({
    super.key,
    required this.text,
    required this.currentIndex,
    required this.incorrectIndices,
    required this.isFocused,
    required this.onTap,
    required this.exerciseType,
    this.source,
  });

  bool get isParagraph => exerciseType == ExerciseType.paragraph;
  bool get isMultiLine => text.contains('\n');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final surfaceColor = isDarkMode
        ? colorScheme.surfaceVariant.withOpacity(0.7)
        : colorScheme.surface;
    final borderColor = colorScheme.outline.withOpacity(0.2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: isParagraph ? null : 150,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isFocused ? colorScheme.primary.withOpacity(0.6) : borderColor,
            width: isFocused ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source citation if available
                  if (source != null && source!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Source: $source',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // Main typing content
                  isMultiLine || isParagraph
                      ? _buildParagraphText(context)
                      : Center(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.notoSans(
                                fontSize: 32.0, // Increased font size
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.8),
                                letterSpacing: 1.2,
                                height: 1.5,
                              ),
                              children: _buildTextSpans(context),
                            ),
                          ),
                        ),
                ],
              ),
            ),

            // Overlay when not focused with animated opacity
            AnimatedOpacity(
              opacity: !isFocused ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDarkMode ? Colors.black : Colors.white)
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Icon(
                          Icons.keyboard,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isParagraph
                              ? 'অনুচ্ছেদ টাইপিং শুরু করতে এখানে ক্লিক করুন'
                              : 'অনুশীলন শুরু করতে এখানে ক্লিক করুন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tips section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              _buildTip(
                                  context,
                                  'আপনার আঙুলগুলি হোম রো-তে রাখুন (ASDF JKL;)',
                                  Icons.keyboard_alt_outlined),
                              const SizedBox(height: 8),
                              _buildTip(context, 'কীবোর্ড নয়, স্ক্রিনে তাকান',
                                  Icons.visibility),
                              const SizedBox(height: 8),
                              _buildTip(
                                  context,
                                  'সঠিক আঙ্গুল দিয়ে সঠিক কী টিপুন',
                                  Icons.touch_app),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'শুরু করুন',
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Current progress indicator
            if (isFocused && text.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: text.isEmpty ? 0 : currentIndex / text.length,
                      backgroundColor: colorScheme.surfaceVariant,
                      color: colorScheme.primary,
                      minHeight: 4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isMultiLine) {
      // For single-line paragraphs, wrap with padding and use RichText
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.notoSans(
              fontSize: 28.0, // Increased font size
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.8),
              letterSpacing: 1.2,
              height: 1.5,
            ),
            children: _buildTextSpans(context),
          ),
        ),
      );
    }

    // For multi-line text, split by newlines and create separate RichText widgets
    final lines = text.split('\n');
    int charOffset = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final lineSpans = _buildTextSpansForRange(
          context,
          charOffset,
          charOffset + line.length,
        );
        charOffset += line.length + 1; // +1 for the newline character

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.notoSans(
                fontSize: 24.0, // Slightly smaller for multi-line
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
                letterSpacing: 1.2,
                height: 1.5,
              ),
              children: lineSpans,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    return _buildTextSpansForRange(context, 0, text.length);
  }

  List<TextSpan> _buildTextSpansForRange(
      BuildContext context, int start, int end) {
    final List<TextSpan> spans = [];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    for (int i = start; i < end; i++) {
      final char = text[i];
      TextStyle style;

      if (i < currentIndex) {
        // Character has been typed
        if (incorrectIndices.contains(i)) {
          style = TextStyle(
            color: isDark ? AppColors.incorrectDark : AppColors.incorrectLight,
            fontWeight: FontWeight.normal,
          );
        } else {
          style = TextStyle(
            color: isDark ? AppColors.correctDark : AppColors.correctLight,
            fontWeight: FontWeight.normal,
          );
        }
      } else if (i == currentIndex) {
        // Current character with blinking animation
        style = TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary,
          decorationThickness: 2,
        );
      } else {
        // Not yet typed
        style = TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.normal,
        );
      }

      spans.add(TextSpan(text: char, style: style));
    }

    return spans;
  }

  // Helper method to build a tip with icon
  Widget _buildTip(BuildContext context, String tipText, IconData iconData) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tipText,
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

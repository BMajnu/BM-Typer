import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/core/constants/app_colors.dart' as legacy_colors;
import 'package:bm_typer/core/models/lesson_model.dart';

/// আধুনিক টাইপিং এরিয়া উইজেট
/// 
/// গ্লাসমরফিজম ইফেক্ট এবং উন্নত অ্যানিমেশন সহ।
class TypingArea extends StatefulWidget {
  final String text;
  final int currentIndex;
  final List<int> incorrectIndices;
  final bool isFocused;
  final VoidCallback onTap;
  final ExerciseType exerciseType;
  final String? source;
  final String? pendingPreBaseVowel;

  const TypingArea({
    super.key,
    required this.text,
    required this.currentIndex,
    required this.incorrectIndices,
    required this.isFocused,
    required this.onTap,
    required this.exerciseType,
    this.source,
    this.pendingPreBaseVowel,
  });

  @override
  State<TypingArea> createState() => _TypingAreaState();
}

class _TypingAreaState extends State<TypingArea> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  
  bool get isParagraph => widget.exerciseType == ExerciseType.paragraph;
  bool get isMultiLine => widget.text.contains('\n');

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        width: double.infinity, // Full width
        constraints: BoxConstraints(
          minHeight: isParagraph ? 200 : 100,
        ),
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm), // Reduced margin
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: AppDurations.medium,
              padding: EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                // Glassmorphism effect
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          AppColors.glassWhiteDark,
                          AppColors.glassWhiteDark.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: widget.isFocused
                      ? colorScheme.primary.withOpacity(0.6)
                      : (isDarkMode ? AppColors.glassBorderDark : AppColors.glassBorder),
                  width: widget.isFocused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? AppColors.glassShadowDark 
                        : AppColors.glassShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  if (widget.isFocused)
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Progress indicator at top
                  if (widget.isFocused && widget.text.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildProgressBar(colorScheme),
                    ),

                  // Main content
                  Padding(
                    padding: EdgeInsets.only(top: widget.isFocused ? AppSpacing.lg : 0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Source citation
                          if (widget.source != null && widget.source!.isNotEmpty)
                            _buildSourceCitation(colorScheme),

                          // Main typing content
                          isMultiLine || isParagraph
                              ? _buildParagraphText(context)
                              : _buildSingleLineText(context),
                        ],
                      ),
                    ),
                  ),

                  // Click to focus overlay
                  if (!widget.isFocused)
                    _buildFocusOverlay(context, isDarkMode, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    final progress = widget.text.isEmpty ? 0.0 : widget.currentIndex / widget.text.length;
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCitation(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(
          'উৎস: ${widget.source}',
          style: AppTypography.labelSmall(context).copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleLineText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.notoSansBengali(
            fontSize: 36.0,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.9),
            letterSpacing: 2,
            height: 1.6,
          ),
          children: _buildTextSpans(context),
        ),
      ),
    );
  }

  Widget _buildParagraphText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isMultiLine) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.notoSansBengali(
              fontSize: 28.0,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.9),
              letterSpacing: 1.5,
              height: 1.6,
            ),
            children: _buildTextSpans(context),
          ),
        ),
      );
    }

    final lines = widget.text.split('\n');
    int charOffset = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final lineSpans = _buildTextSpansForRange(
          context,
          charOffset,
          charOffset + line.length,
        );
        charOffset += line.length + 1;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.notoSansBengali(
                fontSize: 24.0,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.9),
                letterSpacing: 1.5,
                height: 1.6,
              ),
              children: lineSpans,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    return _buildTextSpansForRange(context, 0, widget.text.length);
  }

  List<TextSpan> _buildTextSpansForRange(BuildContext context, int start, int end) {
    final List<TextSpan> spans = [];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    const preBaseVowels = ['ি', 'ে', 'ৈ'];
    const postBaseVowels = ['া', 'ী', 'ু', 'ূ', 'ৃ', 'ৄ', 'ো', 'ৌ', '্'];

    bool isPreBasePair(int idx) {
      return idx < end - 1 && preBaseVowels.contains(widget.text[idx + 1]);
    }

    bool isCurrentToType(int idx) {
      if (widget.currentIndex < end - 1 && preBaseVowels.contains(widget.text[widget.currentIndex + 1])) {
        if (widget.pendingPreBaseVowel != null) {
          return idx == widget.currentIndex;
        } else {
          return idx == widget.currentIndex + 1;
        }
      }
      return idx == widget.currentIndex;
    }

    TextStyle getStyleForIndex(int idx, bool forceHighlight) {
      if (idx < widget.currentIndex) {
        if (widget.incorrectIndices.contains(idx)) {
          return TextStyle(
            color: isDark 
                ? legacy_colors.AppColors.incorrectDark 
                : legacy_colors.AppColors.incorrectLight,
            fontWeight: FontWeight.normal,
          );
        } else {
          return TextStyle(
            color: isDark 
                ? legacy_colors.AppColors.correctDark 
                : legacy_colors.AppColors.correctLight,
            fontWeight: FontWeight.normal,
          );
        }
      } else if (forceHighlight || isCurrentToType(idx)) {
        // Current character - animated highlight
        return TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: colorScheme.primary.withOpacity(0.15),
          shadows: [
            Shadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        );
      } else {
        return TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.normal,
        );
      }
    }

    int i = start;
    while (i < end) {
      final char = widget.text[i];

      if (i < end - 1 && preBaseVowels.contains(widget.text[i + 1])) {
        final consonant = char;
        final vowel = widget.text[i + 1];
        final isThisPairCurrent = (i == widget.currentIndex);

        if (isThisPairCurrent) {
          spans.add(const TextSpan(text: ' '));
          spans.add(TextSpan(text: vowel, style: getStyleForIndex(i + 1, true)));
          spans.add(const TextSpan(text: ' '));
          spans.add(TextSpan(text: consonant, style: getStyleForIndex(i, false)));
          spans.add(const TextSpan(text: ' '));
        } else {
          spans.add(TextSpan(text: consonant, style: getStyleForIndex(i, false)));
          spans.add(TextSpan(text: vowel, style: getStyleForIndex(i + 1, false)));
        }
        i += 2;
      } else if (postBaseVowels.contains(char)) {
        final isThisCurrent = (i == widget.currentIndex);
        if (isThisCurrent) {
          spans.add(const TextSpan(text: ' '));
          spans.add(TextSpan(text: char, style: getStyleForIndex(i, true)));
          spans.add(const TextSpan(text: ' '));
        } else {
          spans.add(TextSpan(text: char, style: getStyleForIndex(i, false)));
        }
        i++;
      } else {
        spans.add(TextSpan(text: char, style: getStyleForIndex(i, false)));
        i++;
      }
    }

    return spans;
  }

  Widget _buildFocusOverlay(BuildContext context, bool isDarkMode, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AnimatedContainer(
          duration: AppDurations.medium,
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.85),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Removed the Keyboard Icon
                  Text(
                    isParagraph
                        ? 'অনুচ্ছেদ টাইপিং শুরু করতে এখানে ক্লিক করুন'
                        : 'অনুশীলন শুরু করতে এখানে ক্লিক করুন',
                    style: AppTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.md),
                  
                  // Tips
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      children: [
                        _buildTip(
                          context,
                          'আপনার আঙুলগুলি হোম রো-তে রাখুন (ASDF JKL;)',
                          Icons.keyboard_alt_outlined,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _buildTip(
                          context,
                          'কীবোর্ড নয়, স্ক্রিনে তাকান',
                          Icons.visibility_rounded,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _buildTip(
                          context,
                          'সঠিক আঙ্গুল দিয়ে সঠিক কী টিপুন',
                          Icons.touch_app_rounded,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  
                  // Start button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: AppSizes.iconMd,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'শুরু করুন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String tipText, IconData iconData) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusXs),
            ),
            child: Icon(
              iconData,
              size: AppSizes.iconSm,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              tipText,
              style: AppTypography.bodySmall(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

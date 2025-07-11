import 'package:flutter/material.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/constants/app_text_styles.dart';

class LessonNavigation extends StatelessWidget {
  final int currentLessonIndex;
  final int totalLessons;
  final bool isPrevDisabled;
  final bool isNextDisabled;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const LessonNavigation({
    super.key,
    required this.currentLessonIndex,
    required this.totalLessons,
    required this.isPrevDisabled,
    required this.isNextDisabled,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: isPrevDisabled ? null : onPrevious,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
            ),
            child: Text(
              'আগের পাঠ',
              style: AppTextStyles.buttonText,
            ),
          ),
          Text(
            '${currentLessonIndex + 1} / $totalLessons',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: isNextDisabled ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLegacy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
            ),
            child: Text(
              'পরবর্তী পাঠ',
              style: AppTextStyles.buttonText,
            ),
          ),
        ],
      ),
    );
  }
}

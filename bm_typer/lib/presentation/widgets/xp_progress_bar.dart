import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/models/user_model.dart';

/// আধুনিক XP প্রগ্রেস বার উইজেট
/// 
/// শাইনি অ্যানিমেশন এবং লেভেল কালার সহ।
class XPProgressBar extends ConsumerStatefulWidget {
  final bool isExpanded;

  const XPProgressBar({
    super.key,
    this.isExpanded = false,
  });

  @override
  ConsumerState<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends ConsumerState<XPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    final level = user.level;
    final nextLevelProgress = user.nextLevelProgress;
    final xpToNextLevel = user.xpToNextLevel;
    final currentLevelXp =
        user.xpPoints - (xpToNextLevel - UserModel.xpRequiredForLevel(level));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getLevelColor(level).withOpacity(isDark ? 0.3 : 0.15),
            AppColors.getLevelColor(level).withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.getLevelColor(level).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.getLevelColor(level).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: widget.isExpanded
          ? _buildExpandedView(
              context, level, nextLevelProgress, currentLevelXp, xpToNextLevel)
          : _buildCompactView(
              level, nextLevelProgress, currentLevelXp, xpToNextLevel),
    );
  }

  Widget _buildCompactView(
    int level,
    double nextLevelProgress,
    int currentLevelXp,
    int xpToNextLevel,
  ) {
    final levelColor = AppColors.getLevelColor(level);
    
    return Row(
      children: [
        _buildLevelBadge(level),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'লেভেল $level',
                    style: AppTypography.titleSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: levelColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.xpGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: AppSizes.iconSm,
                          color: AppColors.xpGold,
                        ),
                        SizedBox(width: AppSpacing.xxs),
                        Text(
                          '$currentLevelXp XP',
                          style: AppTypography.labelSmall(context).copyWith(
                            color: AppColors.xpGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              _buildProgressBar(nextLevelProgress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    int level,
    double nextLevelProgress,
    int currentLevelXp,
    int xpToNextLevel,
  ) {
    final levelColor = AppColors.getLevelColor(level);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'লেভেল প্রগ্রেস',
              style: AppTypography.labelMedium(context),
            ),
            _buildLevelBadge(level),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        
        // Level Title
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [levelColor, levelColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: levelColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getLevelIcon(level),
                size: AppSizes.iconLg,
                color: Colors.white,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'লেভেল $level টাইপিস্ট',
                    style: AppTypography.headlineSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _getLevelTitle(level),
                    style: AppTypography.bodyMedium(context).copyWith(
                      color: levelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        
        // Progress Bar
        _buildProgressBar(nextLevelProgress),
        SizedBox(height: AppSpacing.sm),
        
        // XP Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildXPChip(Icons.star_rounded, '$currentLevelXp XP', AppColors.xpGold),
            Text(
              'পরবর্তী লেভেলে $xpToNextLevel XP',
              style: AppTypography.labelSmall(context),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        
        // Description
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Text(
            _getLevelDescription(level),
            style: AppTypography.bodySmall(context).copyWith(
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: AppDurations.slow,
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clampedProgress,
                decoration: BoxDecoration(
                  gradient: AppColors.xpBarGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.xpGold.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Shimmer effect
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Positioned(
                    left: -100 + (constraints.maxWidth + 100) * _shimmerController.value,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge(int level) {
    final levelColor = AppColors.getLevelColor(level);
    
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [levelColor, levelColor.withOpacity(0.7)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildXPChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.labelMedium(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLevelIcon(int level) {
    if (level < 5) return Icons.emoji_events_outlined;
    if (level < 10) return Icons.military_tech_outlined;
    if (level < 15) return Icons.workspace_premium_outlined;
    if (level < 20) return Icons.diamond_outlined;
    if (level < 30) return Icons.auto_awesome;
    return Icons.star_rounded;
  }

  String _getLevelTitle(int level) {
    if (level < 3) return 'নবীন';
    if (level < 6) return 'শিক্ষানবীশ';
    if (level < 10) return 'দক্ষ টাইপিস্ট';
    if (level < 15) return 'বিশেষজ্ঞ টাইপিস্ট';
    if (level < 20) return 'মাস্টার টাইপিস্ট';
    if (level < 30) return 'গ্র্যান্ডমাস্টার';
    return 'কিংবদন্তি টাইপিস্ট';
  }

  String _getLevelDescription(int level) {
    if (level < 3) {
      return 'আপনার টাইপিং দক্ষতা উন্নত করতে অনুশীলন চালিয়ে যান। লেসন সম্পূর্ণ করে বোনাস XP অর্জন করুন!';
    } else if (level < 6) {
      return 'আপনার ধারাবাহিকতা ফল দিচ্ছে! নিয়মিত অনুশীলন করে নতুন অর্জন আনলক করুন।';
    } else if (level < 10) {
      return 'আপনি দক্ষ হয়ে উঠছেন! আপনার নির্ভুলতা এবং গতি উন্নত করতে মনোযোগ দিন।';
    } else if (level < 15) {
      return 'চমৎকার অগ্রগতি! আপনি শীর্ষ টাইপিস্টদের মধ্যে আছেন।';
    } else if (level < 20) {
      return 'আপনার নিষ্ঠা আপনাকে মাস্টার টাইপিস্ট করেছে! অল্প কয়েকজনই এই স্তরে পৌঁছায়।';
    } else if (level < 30) {
      return 'অসাধারণ টাইপিং দক্ষতা! আপনি টাইপিংয়ের শিল্পে দক্ষতা অর্জন করেছেন।';
    } else {
      return 'আপনি কিংবদন্তি মর্যাদা অর্জন করেছেন! আপনার টাইপিং দক্ষতা অতুলনীয়।';
    }
  }
}

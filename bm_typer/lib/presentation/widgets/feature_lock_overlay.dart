import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A beautiful overlay widget that shows when a feature is locked for free users
class FeatureLockOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final String featureName;
  final VoidCallback? onUpgradePressed;
  final bool showBlur;
  final double blurIntensity;
  
  const FeatureLockOverlay({
    super.key,
    required this.child,
    required this.isLocked,
    this.featureName = 'এই ফিচার',
    this.onUpgradePressed,
    this.showBlur = true,
    this.blurIntensity = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    
    return Stack(
      children: [
        // The actual content (blurred if locked)
        if (showBlur)
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurIntensity,
              sigmaY: blurIntensity,
            ),
            child: child,
          )
        else
          Opacity(
            opacity: 0.5,
            child: child,
          ),
        
        // Lock overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _buildLockContent(context),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLockContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock icon with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade600,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            'প্রিমিয়াম ফিচার',
            style: GoogleFonts.hindSiliguri(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            '$featureName প্রিমিয়াম ইউজারদের জন্য উপলব্ধ',
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Upgrade button
          ElevatedButton.icon(
            onPressed: onUpgradePressed ?? () {
              Navigator.pushNamed(context, '/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.stars_rounded, size: 20),
            label: Text(
              'প্রিমিয়ামে আপগ্রেড করুন',
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small lock badge to show on locked items (like lesson cards)
class LockBadge extends StatelessWidget {
  final bool isLocked;
  final double size;
  
  const LockBadge({
    super.key,
    required this.isLocked,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade600,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.lock_rounded,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}

/// A premium crown badge for premium features
class PremiumBadge extends StatelessWidget {
  final String text;
  final double fontSize;
  
  const PremiumBadge({
    super.key,
    this.text = 'PRO',
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: fontSize + 2,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily limit warning banner
class DailyLimitBanner extends StatelessWidget {
  final int remainingMinutes;
  final VoidCallback? onUpgradePressed;
  
  const DailyLimitBanner({
    super.key,
    required this.remainingMinutes,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = remainingMinutes <= 3;
    final bool isZero = remainingMinutes <= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isZero 
            ? [Colors.red.shade400, Colors.red.shade600]
            : isLow 
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isZero ? Colors.red : isLow ? Colors.orange : Colors.blue)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isZero ? Icons.timer_off_rounded : Icons.timer_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isZero 
                ? 'দৈনিক সীমা শেষ!'
                : 'বাকি সময়: $remainingMinutes মিনিট',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (isLow || isZero)
            TextButton(
              onPressed: onUpgradePressed ?? () {
                Navigator.pushNamed(context, '/subscription');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(
                'আপগ্রেড',
                style: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paywall widget shown when free user exceeds limits
class PaywallWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onUpgrade;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const PaywallWidget({
    super.key,
    required this.title,
    required this.message,
    this.onUpgrade,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade800,
            Colors.deepPurple.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          if (showCloseButton && onClose != null)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ),
          
          // Premium icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 64,
              color: Colors.amber,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            message,
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Premium features
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildFeatureRow(Icons.all_inclusive, 'সীমাহীন প্র্যাক্টিস'),
                _buildFeatureRow(Icons.menu_book, 'সব লেসন আনলক'),
                _buildFeatureRow(Icons.emoji_events, 'অ্যাচিভমেন্ট সিস্টেম'),
                _buildFeatureRow(Icons.leaderboard, 'লিডারবোর্ড এন্ট্রি'),
                _buildFeatureRow(Icons.record_voice_over, 'সীমাহীন TTS'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'প্রিমিয়ামে আপগ্রেড করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Price info
          Text(
            'মাত্র ৳99/মাস থেকে শুরু',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.amber),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact limit warning banner
class LimitWarningBanner extends StatelessWidget {
  final String message;
  final int current;
  final int max;
  final VoidCallback? onUpgrade;

  const LimitWarningBanner({
    super.key,
    required this.message,
    required this.current,
    required this.max,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / max;
    final isNearLimit = progress >= 0.8;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNearLimit ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNearLimit ? Colors.orange.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNearLimit ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isNearLimit ? Colors.orange.shade700 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isNearLimit ? Colors.orange.shade900 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    isNearLimit ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$current / $max',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (onUpgrade != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                'আপগ্রেড',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog helper to show paywall
void showPaywallDialog(BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onUpgrade,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: PaywallWidget(
        title: title,
        message: message,
        onUpgrade: onUpgrade ?? () {
          Navigator.pop(context);
          // Navigate to subscription screen
          Navigator.pushNamed(context, '/subscription');
        },
        onClose: () => Navigator.pop(context),
      ),
    ),
  );
}

/// Premium badge widget
class PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final double size;

  const PremiumBadge({
    super.key,
    required this.isPremium,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: Colors.amber.shade700,
      ),
    );
  }
}

/// Lock icon overlay for premium content
class PremiumLockOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final VoidCallback? onTap;

  const PremiumLockOverlay({
    super.key,
    required this.child,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    
    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: child,
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'প্রিমিয়াম',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

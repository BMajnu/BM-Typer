import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/models/subscription_model.dart';
import 'package:bm_typer/core/providers/subscription_provider.dart';

/// Subscription screen showing available plans and current status
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('সাবস্ক্রিপশন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Plan Card
            _buildCurrentPlanCard(context, subscriptionState, colorScheme),
            
            const SizedBox(height: 24),
            
            // Features Comparison
            Text(
              'প্ল্যান তুলনা',
              style: GoogleFonts.hindSiliguri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildFeaturesTable(context, colorScheme),
            
            const SizedBox(height: 24),
            
            // Subscription Plans
            Text(
              'প্রিমিয়াম প্ল্যান',
              style: GoogleFonts.hindSiliguri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPlanCard(
              context,
              title: 'মাসিক',
              price: '৳299/মাস',
              features: ['সব লেসন আনলক', 'আনলিমিটেড প্র্যাক্টিস', 'Achievement সিস্টেম', 'লিডারবোর্ড অ্যাক্সেস'],
              colorScheme: colorScheme,
              isPopular: false,
            ),
            
            const SizedBox(height: 12),
            
            _buildPlanCard(
              context,
              title: 'বার্ষিক',
              price: '৳2,499/বছর',
              originalPrice: '৳3,588',
              features: ['সব লেসন আনলক', 'আনলিমিটেড প্র্যাক্টিস', 'Achievement সিস্টেম', 'লিডারবোর্ড অ্যাক্সেস', '২ মাস ফ্রি!'],
              colorScheme: colorScheme,
              isPopular: true,
            ),
            
            const SizedBox(height: 24),
            
            // Coming Soon Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'পেমেন্ট সিস্টেম শীঘ্রই আসছে। এখন সব ফিচার বিনামূল্যে ব্যবহার করতে পারবেন!',
                      style: GoogleFonts.hindSiliguri(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionState state, ColorScheme colorScheme) {
    final isPremium = state.isPremium;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium 
            ? [Colors.amber.shade400, Colors.orange.shade600]
            : [colorScheme.primaryContainer, colorScheme.primary.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? Colors.orange : colorScheme.primary).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPremium ? Icons.workspace_premium_rounded : Icons.person_outline,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'বর্তমান প্ল্যান',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      isPremium ? 'প্রিমিয়াম' : 'ফ্রি',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'সক্রিয়',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'বাকি প্র্যাক্টিস সময়: ${state.remainingMinutes} মিনিট',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFeaturesTable(BuildContext context, ColorScheme colorScheme) {
    final features = [
      {'name': 'লেসন অ্যাক্সেস', 'free': 'প্রথম ৫টি', 'premium': 'সব'},
      {'name': 'দৈনিক প্র্যাক্টিস', 'free': '১০ মিনিট', 'premium': 'আনলিমিটেড'},
      {'name': 'Achievement', 'free': '❌', 'premium': '✅'},
      {'name': 'লিডারবোর্ড', 'free': '❌', 'premium': '✅'},
      {'name': 'TTS (বাক সংশ্লেষণ)', 'free': '❌', 'premium': '✅'},
      {'name': 'বিস্তারিত পরিসংখ্যান', 'free': '❌', 'premium': '✅'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('ফিচার', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Center(
                    child: Text('ফ্রি', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('প্রিমিয়াম', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: index < features.length - 1 
                  ? Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)))
                  : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(feature['name']!, style: GoogleFonts.hindSiliguri(fontSize: 13)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(feature['free']!, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(feature['premium']!, style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    String? originalPrice,
    required List<String> features,
    required ColorScheme colorScheme,
    bool isPopular = false,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPopular ? Colors.deepPurple.shade50 : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPopular ? Colors.deepPurple : colorScheme.outline.withOpacity(0.2),
              width: isPopular ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'জনপ্রিয়',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPopular ? Colors.deepPurple : colorScheme.primary,
                    ),
                  ),
                  if (originalPrice != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      originalPrice,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(feature, style: GoogleFonts.hindSiliguri(fontSize: 13)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('পেমেন্ট সিস্টেম শীঘ্রই আসছে!', style: GoogleFonts.hindSiliguri()),
                        backgroundColor: Colors.deepPurple,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? Colors.deepPurple : colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'এখনই সাবস্ক্রাইব করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            right: 16,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '৩০% ছাড়',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

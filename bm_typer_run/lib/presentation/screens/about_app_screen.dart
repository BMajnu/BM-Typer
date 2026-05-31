import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const Color _orgNavyBlue = Color(0xFF000080);
  static const Color _orgAmber = Color(0xFFFFBF00);
  static const Color _orgLightBlue = Color(0xFF4169E1);
  static const Color _orgGold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(isDark, colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, colorScheme, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAppInfoCard(colorScheme, isDark),
                      const SizedBox(height: 16),
                      _buildFeaturesCard(colorScheme, isDark),
                      const SizedBox(height: 16),
                      _buildDeveloperCard(context, colorScheme, isDark),
                      const SizedBox(height: 16),
                      _buildTechZoneCard(context, colorScheme, isDark),
                      const SizedBox(height: 16),
                      _buildCreditsCard(colorScheme, isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground(bool isDark, ColorScheme colorScheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
                const Color(0xFF0f0f1a)
              ]
            : [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surface,
                colorScheme.surface
              ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: isDark ? Colors.white : Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Icon(Icons.info_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'অ্যাপ সম্পর্কে',
            style: GoogleFonts.hindSiliguri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(bool isDark, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
        isDark,
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/BMT.png',
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'BM Typer',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            Text(
              'Interactive Bangla Typing Tutor',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('ভার্সন ১.০.০',
                  style: GoogleFonts.hindSiliguri(
                      color: colorScheme.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            Text(
              'বাংলা টাইপিং শেখার সবচেয়ে সহজ এবং কার্যকর অ্যাপ। বিজয় ও অভ্র উভয় পদ্ধতিতে টাইপিং শিখুন।',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ));
  }

  Widget _buildFeaturesCard(ColorScheme colorScheme, bool isDark) {
    final features = [
      {
        'icon': Icons.school_rounded,
        'title': 'ইন্টারেক্টিভ লেসন',
        'desc': 'ধাপে ধাপে টাইপিং শেখা'
      },
      {
        'icon': Icons.keyboard_alt_rounded,
        'title': 'বিজয় কীবোর্ড',
        'desc': 'বিজয় লেআউটে বাংলা টাইপিং'
      },
      {
        'icon': Icons.translate_rounded,
        'title': 'অভ্র সাপোর্ট',
        'desc': 'অভ্র পদ্ধতিতে বাংলা টাইপিং'
      },
      {
        'icon': Icons.abc_rounded,
        'title': 'ইংলিশ QWERTY',
        'desc': 'ইংরেজি কীবোর্ড লেআউট সাপোর্ট'
      },
      {
        'icon': Icons.speed_rounded,
        'title': 'স্পিড টেস্ট',
        'desc': 'টাইপিং গতি পরীক্ষা করুন'
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'অ্যাচিভমেন্ট',
        'desc': 'ব্যাজ ও পুরস্কার অর্জন করুন'
      },
      {
        'icon': Icons.leaderboard_rounded,
        'title': 'লিডারবোর্ড',
        'desc': 'অন্যদের সাথে প্রতিযোগিতা'
      },
      {
        'icon': Icons.record_voice_over_rounded,
        'title': 'টেক্সট টু স্পীচ',
        'desc': 'অডিও সহ শিক্ষা'
      },
      {
        'icon': Icons.dark_mode_rounded,
        'title': 'ডার্ক মোড',
        'desc': 'চোখের জন্য আরামদায়ক'
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'রিমাইন্ডার',
        'desc': 'দৈনিক অনুশীলনের জন্য'
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'অগ্রগতি ট্র্যাকিং',
        'desc': 'আপনার উন্নতি দেখুন'
      },
    ];

    return _buildGlassCard(
        isDark,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Text('ফিচার সমূহ',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features
                  .map((f) => _buildFeatureChip(
                      f['icon'] as IconData,
                      f['title'] as String,
                      f['desc'] as String,
                      colorScheme,
                      isDark))
                  .toList(),
            ),
          ],
        ));
  }

  Widget _buildFeatureChip(IconData icon, String title, String desc,
      ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(desc,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(
      BuildContext context, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
        isDark,
        Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      colorScheme.primary.withOpacity(0.2),
                      colorScheme.tertiary.withOpacity(0.2),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 22, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text('Developer',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: colorScheme.tertiary.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: const AssetImage('assets/BMajnu.jpg'),
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Developer photo error: $exception');
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Badiuzzaman Majnu',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 6),
            Text('Designer • Developer • Freelancer',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"Crafting digital experiences with passion and precision"',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildContactButton(Icons.language_rounded, 'Website',
                    'https://www.techzoneit.top', colorScheme, isDark,
                    accentColor: Colors.cyan),
                _buildContactButton(
                    Icons.email_rounded,
                    'Email',
                    'mailto:badiuzzamanmajnu786@gmail.com',
                    colorScheme,
                    isDark,
                    accentColor: Colors.red),
                _buildContactButton(Icons.facebook_rounded, 'Facebook',
                    'https://www.facebook.com/bmajnu786', colorScheme, isDark,
                    accentColor: const Color(0xFF1877F2)),
                _buildContactButton(Icons.chat_rounded, 'WhatsApp',
                    'https://wa.me/8801796072129', colorScheme, isDark,
                    accentColor: const Color(0xFF25D366)),
                _buildContactButton(Icons.phone_rounded, 'Call',
                    'tel:+8801796072129', colorScheme, isDark,
                    accentColor: Colors.blue),
              ],
            ),
          ],
        ));
  }

  Widget _buildContactButton(IconData icon, String label, String url,
      ColorScheme colorScheme, bool isDark,
      {Color? accentColor}) {
    final buttonColor = accentColor ?? colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Use url_launcher for all platforms (works on web too)
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: buttonColor),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: buttonColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechZoneCard(
      BuildContext context, ColorScheme colorScheme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      _orgNavyBlue.withOpacity(0.15),
                      _orgAmber.withOpacity(0.08),
                    ]
                  : [
                      _orgNavyBlue.withOpacity(0.08),
                      _orgAmber.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? _orgNavyBlue.withOpacity(0.3)
                  : _orgNavyBlue.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _orgNavyBlue.withOpacity(0.3),
                          _orgAmber.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.business_rounded,
                        size: 22, color: isDark ? _orgGold : _orgNavyBlue),
                  ),
                  const SizedBox(width: 12),
                  Text('Our Organization',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [_orgNavyBlue, _orgAmber],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _orgNavyBlue.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: _orgAmber.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
                    child: Image.asset('assets/D_Main Logo Color.png',
                        width: 72, height: 72, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_orgNavyBlue, _orgAmber],
                ).createShader(bounds),
                child: Text('TechZone IT',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text('টেকজোন আইটি',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.grey[700])),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _orgNavyBlue.withOpacity(0.1),
                      _orgAmber.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _orgAmber.withOpacity(0.3)),
                ),
                child: Text('"সকল প্রযুক্তি সমাধান এক জায়গায়"',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.grey[700])),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.location_on_rounded,
                  'স্টেশন রোড, আদিতমারী, লালমনিরহাট', _orgGold, isDark),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhoneChip('01796072129', isDark, _orgLightBlue),
                  const SizedBox(width: 8),
                  _buildPhoneChip('01717444557', isDark, _orgGold),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text('Service Zones',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 12),
              _buildServiceGrid(isDark),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildContactButton(Icons.language_rounded, 'Website',
                      'https://www.techzoneit.top', colorScheme, isDark,
                      accentColor: _orgAmber),
                  _buildContactButton(Icons.facebook_rounded, 'Facebook',
                      'https://www.facebook.com/bmajnu786',
                      colorScheme,
                      isDark,
                      accentColor: _orgLightBlue),
                  _buildContactButton(Icons.phone_rounded, 'Call',
                      'tel:+8801796072129', colorScheme, isDark,
                      accentColor: _orgGold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid(bool isDark) {
    final services = [
      {'icon': Icons.shopping_cart_rounded, 'label': 'Store'},
      {'icon': Icons.build_rounded, 'label': 'Service'},
      {'icon': Icons.print_rounded, 'label': 'প্রিন্টিং'},
      {'icon': Icons.palette_rounded, 'label': 'গ্রাফিক্স'},
      {'icon': Icons.code_rounded, 'label': 'ডেভেলপমেন্ট'},
      {'icon': Icons.school_rounded, 'label': 'Training'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: services
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s['icon'] as IconData,
                        color: isDark ? _orgGold : _orgLightBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      s['label'] as String,
                      style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color:
                    (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
      ],
    );
  }

  Widget _buildPhoneChip(String text, bool isDark, Color chipColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_rounded, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildCreditsCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
        isDark,
        Column(
          children: [
            Text('কৃতজ্ঞতা ও স্বীকৃতি',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            Text(
              'এই অ্যাপটি তৈরিতে Flutter, Riverpod, Google Fonts এবং অন্যান্য ওপেন সোর্স প্রজেক্ট ব্যবহার করা হয়েছে।',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('© ২০২৬ TechZone IT. সর্বস্বত্ব সংরক্ষিত।',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.4))),
            const SizedBox(height: 8),
            Text('Made with ❤️ in Bangladesh 🇧🇩',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.4))),
          ],
        ));
  }
}

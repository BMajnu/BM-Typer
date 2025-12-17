import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Analytics Screen - Shows app usage statistics
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Range Selector
          Row(
            children: [
              _buildTimeChip('আজ', true, colorScheme),
              const SizedBox(width: 8),
              _buildTimeChip('৭ দিন', false, colorScheme),
              const SizedBox(width: 8),
              _buildTimeChip('৩০ দিন', false, colorScheme),
              const SizedBox(width: 8),
              _buildTimeChip('সব সময়', false, colorScheme),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: Text('রিপোর্ট ডাউনলোড', style: GoogleFonts.hindSiliguri()),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Main Stats Grid - Real Data
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              final totalUsers = snapshot.data?.docs.length ?? 0;
              
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildLargeStatCard(
                        title: 'মোট ইউজার',
                        value: '$totalUsers',
                        subtitle: 'নিবন্ধিত ইউজার',
                        icon: Icons.people_rounded,
                        color: Colors.blue,
                        width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      ),
                      _buildLargeStatCard(
                        title: 'গড় সেশন সময়',
                        value: '-',
                        subtitle: 'নির্মানাধীন',
                        icon: Icons.timer_rounded,
                        color: Colors.green,
                        width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      ),
                      _buildLargeStatCard(
                        title: 'মোট টাইপিং সেশন',
                        value: '-',
                        subtitle: 'নির্মানাধীন',
                        icon: Icons.keyboard_rounded,
                        color: Colors.purple,
                        width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Charts Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Users Chart
              Expanded(
                flex: 2,
                child: _buildChartCard(
                  title: 'দৈনিক সক্রিয় ইউজার',
                  colorScheme: colorScheme,
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 48, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text(
                            'পর্যাপ্ত ডাটা নেই',
                            style: GoogleFonts.hindSiliguri(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Popular Lessons
              Expanded(
                child: _buildChartCard(
                  title: 'জনপ্রিয় লেসন',
                  colorScheme: colorScheme,
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Text(
                      'কোনো ডাটা নেই',
                      style: GoogleFonts.hindSiliguri(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // More Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Growth
              Expanded(
                child: _buildChartCard(
                  title: 'ইউজার গ্রোথ',
                  colorScheme: colorScheme,
                  child: Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Text('ডাটা নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Typing Stats
              Expanded(
                child: _buildChartCard(
                  title: 'টাইপিং পরিসংখ্যান',
                  colorScheme: colorScheme,
                  child: Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Text('ডাটা নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Platform Stats
              Expanded(
                child: _buildChartCard(
                  title: 'প্ল্যাটফর্ম ব্রেকডাউন',
                  colorScheme: colorScheme,
                  child: Column(
                    children: [
                      _buildPlatformItem('ওয়েব', '100%', Icons.web, Colors.blue),
                      _buildPlatformItem('উইন্ডোজ', '0%', Icons.laptop_windows, Colors.grey),
                      _buildPlatformItem('অ্যান্ড্রয়েড', '0%', Icons.android, Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeChip(String label, bool isSelected, ColorScheme colorScheme) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.hindSiliguri()),
      selected: isSelected,
      onSelected: (selected) {},
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
    );
  }
  
  Widget _buildLargeStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.hindSiliguri(color: Colors.grey, fontSize: 13)),
              Text(value, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: GoogleFonts.hindSiliguri(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildChartCard({
    required String title,
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  Widget _buildRankItem(int rank, String name, String count, Color? medalColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: medalColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: medalColor ?? Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.hindSiliguri(fontSize: 13))),
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildGrowthItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.hindSiliguri(fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
  
  Widget _buildPlatformItem(String name, String percentage, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.hindSiliguri(fontSize: 13))),
          Text(percentage, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

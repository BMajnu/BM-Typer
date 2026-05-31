import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin Settings Screen
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Settings
          _buildSettingsSection(
            title: 'সাধারণ সেটিংস',
            icon: Icons.settings,
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.dark_mode,
                title: 'ডার্ক মোড',
                subtitle: 'অ্যাডমিন প্যানেল ডার্ক মোড',
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
              _buildSettingTile(
                icon: Icons.language,
                title: 'ভাষা',
                subtitle: 'অ্যাডমিন প্যানেল ভাষা',
                trailing: DropdownButton<String>(
                  value: 'bn',
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) {},
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // App Settings
          _buildSettingsSection(
            title: 'অ্যাপ সেটিংস',
            icon: Icons.phone_android,
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.update,
                title: 'অ্যাপ ভার্সন',
                subtitle: 'বর্তমান ভার্সন: 1.0.0',
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: Text('আপডেট চেক', style: GoogleFonts.hindSiliguri(fontSize: 12)),
                ),
              ),
              _buildSettingTile(
                icon: Icons.system_update,
                title: 'Force Update',
                subtitle: 'ইউজারদের আপডেট করতে বাধ্য করুন',
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
              _buildSettingTile(
                icon: Icons.cloud_off,
                title: 'মেইনটেন্যান্স মোড',
                subtitle: 'অ্যাপ সাময়িকভাবে বন্ধ রাখুন',
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Subscription Settings
          _buildSettingsSection(
            title: 'সাবস্ক্রিপশন সেটিংস',
            icon: Icons.star,
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.timer,
                title: 'ফ্রি ট্রায়াল সময়',
                subtitle: 'প্রিমিয়াম ফ্রি ট্রায়াল দিন',
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixText: 'দিন',
                    ),
                    controller: TextEditingController(text: '7'),
                  ),
                ),
              ),
              _buildSettingTile(
                icon: Icons.access_time,
                title: 'দৈনিক প্র্যাক্টিস লিমিট',
                subtitle: 'ফ্রি ইউজারদের জন্য',
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixText: 'মি.',
                    ),
                    controller: TextEditingController(text: '10'),
                  ),
                ),
              ),
              _buildSettingTile(
                icon: Icons.book,
                title: 'ফ্রি লেসন সংখ্যা',
                subtitle: 'ফ্রি ইউজারদের জন্য',
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: '5'),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Security Settings
          _buildSettingsSection(
            title: 'সিকিউরিটি',
            icon: Icons.security,
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.password,
                title: 'পাসওয়ার্ড পরিবর্তন',
                subtitle: 'অ্যাডমিন পাসওয়ার্ড পরিবর্তন করুন',
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: Text('পরিবর্তন', style: GoogleFonts.hindSiliguri(fontSize: 12)),
                ),
              ),
              _buildSettingTile(
                icon: Icons.admin_panel_settings,
                title: 'অ্যাডমিন একাউন্ট',
                subtitle: 'অন্যান্য অ্যাডমিন যোগ/সরান',
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: Text('ম্যানেজ', style: GoogleFonts.hindSiliguri(fontSize: 12)),
                ),
              ),
              _buildSettingTile(
                icon: Icons.history,
                title: 'অ্যাক্টিভিটি লগ',
                subtitle: 'অ্যাডমিন কার্যক্রম দেখুন',
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: Text('দেখুন', style: GoogleFonts.hindSiliguri(fontSize: 12)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Save Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('সেটিংস সেভ হয়েছে', style: GoogleFonts.hindSiliguri()),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: Text('সেটিংস সেভ করুন', style: GoogleFonts.hindSiliguri()),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

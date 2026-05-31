import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/reminder_service.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  bool _isLoading = true;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await ReminderService.isReminderEnabled();
    final time = await ReminderService.getReminderTime();
    setState(() {
      _remindersEnabled = enabled;
      if (time != null) _reminderTime = time;
      _isLoading = false;
    });
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() => _remindersEnabled = value);
    await ReminderService.toggleReminders(value);
  }

  Future<void> _selectTime(ColorScheme colorScheme, bool isDark) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: isDark ? ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: colorScheme.primary)) 
                     : ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: colorScheme.primary)),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _reminderTime = time);
      await ReminderService.setReminderTime(time);
    }
  }

  Future<void> _showTestNotification() async {
    await ReminderService.showTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('টেস্ট নোটিফিকেশন পাঠানো হয়েছে!', style: GoogleFonts.hindSiliguri()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(colorScheme, isDark),
                            const SizedBox(height: 16),
                            _buildReminderToggleCard(colorScheme, isDark),
                            if (_remindersEnabled) ...[
                              const SizedBox(height: 12),
                              _buildTimeCard(colorScheme, isDark),
                              const SizedBox(height: 16),
                              _buildTestButton(colorScheme),
                            ],
                            const SizedBox(height: 24),
                            _buildInfoCard(colorScheme, isDark),
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
            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f0f1a)]
            : [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface, colorScheme.surface],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isDark) {
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
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Icon(Icons.notifications_active_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'রিমাইন্ডার সেটিংস',
            style: GoogleFonts.hindSiliguri(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('দৈনিক প্র্যাকটিস রিমাইন্ডার', style: GoogleFonts.hindSiliguri(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text('প্রতিদিন প্র্যাকটিস করতে এবং আপনার স্ট্রিক বজায় রাখতে একটি রিমাইন্ডার সেট করুন।', style: GoogleFonts.hindSiliguri(fontSize: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
      ],
    ));
  }

  Widget _buildReminderToggleCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(_remindersEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('দৈনিক রিমাইন্ডার', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              Text('প্রতিদিন অনুশীলনের জন্য মনে করিয়ে দেবে', style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
            ],
          ),
        ),
        Switch(value: _remindersEnabled, onChanged: _toggleReminders, activeColor: colorScheme.primary),
      ],
    ));
  }

  Widget _buildTimeCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.access_time_rounded, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('রিমাইন্ডার সময়', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              Text('প্রতিদিন ${_formatTime(_reminderTime)}', style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => _selectTime(colorScheme, isDark),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('পরিবর্তন', style: GoogleFonts.hindSiliguri(color: colorScheme.primary)),
        ),
      ],
    ));
  }

  Widget _buildTestButton(ColorScheme colorScheme) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showTestNotification,
        icon: const Icon(Icons.notifications_active_rounded),
        label: Text('টেস্ট নোটিফিকেশন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text('কেন প্রতিদিন প্র্যাকটিস করবেন?', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'গবেষণায় দেখা গেছে যে প্রতিদিন মাত্র ১৫ মিনিট অনুশীলন করলে এক মাসের মধ্যে টাইপিং গতি ৩০% পর্যন্ত উন্নত হতে পারে। নিয়মিত অনুশীলন মাসল মেমোরি তৈরি করতে এবং নির্ভুলতা বাড়াতে সাহায্য করে।',
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.7)),
        ),
      ],
    ));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    return '$hour:$minute $period';
  }
}

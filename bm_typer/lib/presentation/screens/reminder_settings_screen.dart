import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/services/reminder_service.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
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
      if (time != null) {
        _reminderTime = time;
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() {
      _remindersEnabled = value;
    });
    await ReminderService.toggleReminders(value);
  }

  Future<void> _selectTime() async {
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLegacy,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (timeOfDay != null) {
      setState(() {
        _reminderTime = timeOfDay;
      });
      await ReminderService.setReminderTime(timeOfDay);
    }
  }

  Future<void> _showTestNotification() async {
    await ReminderService.showTestNotification();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Practice Reminders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set a daily reminder to practice typing and maintain your streak.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  _buildReminderSwitch(),
                  const Divider(),
                  if (_remindersEnabled) ...[
                    _buildReminderTimeSelector(),
                    const SizedBox(height: 32),
                    _buildTestButton(),
                  ],
                  const Spacer(),
                  _buildReminderInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildReminderSwitch() {
    return SwitchListTile(
      title: const Text('Enable Daily Reminders'),
      value: _remindersEnabled,
      onChanged: _toggleReminders,
      activeColor: AppColors.primaryLegacy,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildReminderTimeSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Reminder Time'),
      subtitle: Text('Every day at ${_formatTime(_reminderTime)}'),
      trailing: OutlinedButton(
        onPressed: _selectTime,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryLegacy),
        ),
        child: const Text('Change'),
      ),
    );
  }

  Widget _buildTestButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showTestNotification,
        icon: const Icon(Icons.notifications_active),
        label: const Text('Test Notification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLegacy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReminderInfo() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Why Practice Daily?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Studies show that daily practice for just 15 minutes can improve typing speed by up to 30% within a month. Regular practice helps build muscle memory and increases accuracy.',
              style: TextStyle(color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    return '$hour:$minute $period';
  }
}

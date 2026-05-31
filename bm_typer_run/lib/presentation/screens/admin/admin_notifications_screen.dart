import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bm_typer/core/models/notification_model.dart';
import 'package:bm_typer/core/services/notification_firestore_service.dart';

/// Admin screen for managing and sending notifications
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'info';
  String? _actionUrl;
  bool _isSending = false;
  
  final List<Map<String, dynamic>> _notificationTypes = [
    {'value': 'info', 'label': 'তথ্য', 'icon': Icons.info_rounded, 'color': Colors.blue},
    {'value': 'success', 'label': 'সাফল্য', 'icon': Icons.check_circle_rounded, 'color': Colors.green},
    {'value': 'warning', 'label': 'সতর্কতা', 'icon': Icons.warning_rounded, 'color': Colors.orange},
    {'value': 'promo', 'label': 'প্রমো/অফার', 'icon': Icons.local_offer_rounded, 'color': Colors.purple},
    {'value': 'update', 'label': 'আপডেট', 'icon': Icons.system_update_rounded, 'color': Colors.teal},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compose Section
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.send_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'নতুন নোটিফিকেশন পাঠান',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'শিরোনাম',
                      labelStyle: GoogleFonts.hindSiliguri(),
                      hintText: 'নোটিফিকেশন শিরোনাম লিখুন',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Body
                  TextField(
                    controller: _bodyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'বিস্তারিত',
                      labelStyle: GoogleFonts.hindSiliguri(),
                      hintText: 'নোটিফিকেশন বিস্তারিত লিখুন',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Type Selection
                  Text('নোটিফিকেশন টাইপ', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _notificationTypes.map((type) {
                      final isSelected = _selectedType == type['value'];
                      return FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          type['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : type['color'] as Color,
                        ),
                        label: Text(
                          type['label'] as String,
                          style: GoogleFonts.hindSiliguri(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selectedColor: type['color'] as Color,
                        onSelected: (selected) {
                          setState(() => _selectedType = type['value'] as String);
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action URL (optional)
                  TextField(
                    onChanged: (value) => _actionUrl = value.isNotEmpty ? value : null,
                    decoration: InputDecoration(
                      labelText: 'অ্যাকশন URL (ঐচ্ছিক)',
                      labelStyle: GoogleFonts.hindSiliguri(),
                      hintText: '/subscription, /profile',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon: _isSending 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSending ? 'পাঠানো হচ্ছে...' : 'সবাইকে পাঠান',
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Sent Notifications List
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'পাঠানো নোটিফিকেশন',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notifications List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .orderBy('createdAt', descending: true)
                          .limit(20)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'কোনো নোটিফিকেশন নেই',
                                  style: GoogleFonts.hindSiliguri(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification = AppNotification.fromFirestore(docs[index]);
                            final color = NotificationType.getColor(notification.type);
                            
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.1),
                                  child: Icon(
                                    NotificationType.getIcon(notification.type),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      _formatDate(notification.createdAt),
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                                  onPressed: () => _deleteNotification(docs[index].id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('শিরোনাম ও বিস্তারিত দিন', style: GoogleFonts.hindSiliguri()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      await ref.read(notificationFirestoreServiceProvider).sendNotification(
        title: _titleController.text,
        body: _bodyController.text,
        type: _selectedType,
        actionUrl: _actionUrl,
      );
      
      _titleController.clear();
      _bodyController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('নোটিফিকেশন পাঠানো হয়েছে!', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  Future<void> _deleteNotification(String id) async {
    try {
      await ref.read(notificationFirestoreServiceProvider).deleteNotification(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('নোটিফিকেশন মুছে ফেলা হয়েছে', style: GoogleFonts.hindSiliguri()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

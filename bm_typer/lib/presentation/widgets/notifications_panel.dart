import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/models/notification_model.dart';
import 'package:bm_typer/core/services/notification_firestore_service.dart';
import 'package:bm_typer/core/providers/user_provider.dart';

/// Widget to display notifications panel
class NotificationsPanel extends ConsumerWidget {
  final VoidCallback? onClose;
  
  const NotificationsPanel({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    if (user == null) {
      return const Center(child: Text('লগইন করুন'));
    }
    
    final notificationsAsync = ref.watch(userNotificationsProvider(user.id));
    
    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'নোটিফিকেশন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(notificationFirestoreServiceProvider).markAllAsRead(user.id);
                  },
                  child: Text('সব পড়া হয়েছে', style: GoogleFonts.hindSiliguri(fontSize: 12)),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          
          // Notifications List
          Flexible(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
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
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      userId: user.id,
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text('ত্রুটি হয়েছে', style: GoogleFonts.hindSiliguri(color: Colors.red)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final String userId;
  
  const _NotificationTile({
    required this.notification,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = NotificationType.getColor(notification.type);
    final icon = NotificationType.getIcon(notification.type);
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () {
        // Mark as read
        ref.read(notificationFirestoreServiceProvider).markAsRead(userId, notification.id);
        
        // Handle action URL if present
        if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
          Navigator.pushNamed(context, notification.actionUrl!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        color: notification.isRead 
          ? null 
          : colorScheme.primaryContainer.withOpacity(0.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.hindSiliguri(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'এইমাত্র';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘন্টা আগে';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} দিন আগে';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Notification Bell Icon Widget with Badge
class NotificationBell extends ConsumerWidget {
  final VoidCallback? onTap;
  final double size;
  
  const NotificationBell({
    super.key,
    this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return IconButton(
        icon: Icon(Icons.notifications_outlined, size: size),
        onPressed: null,
      );
    }
    
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider(user.id));
    
    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCountAsync.when(
          data: (count) => count > 0,
          loading: () => false,
          error: (_, __) => false,
        ),
        label: unreadCountAsync.when(
          data: (count) => Text(count > 9 ? '9+' : '$count'),
          loading: () => null,
          error: (_, __) => null,
        ),
        child: Icon(Icons.notifications_outlined, size: size),
      ),
      onPressed: onTap ?? () => _showNotificationsPanel(context),
    );
  }
  
  void _showNotificationsPanel(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, right: 16),
          child: Material(
            color: Colors.transparent,
            child: NotificationsPanel(
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }
}

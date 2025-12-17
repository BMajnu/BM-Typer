import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/notification_model.dart';

/// Service for managing in-app notifications via Firestore
class NotificationFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection reference
  CollectionReference get _notificationsRef => _firestore.collection('notifications');
  
  /// Get notifications for a user (including broadcasts)
  Stream<List<AppNotification>> getNotificationsForUser(String userId) {
    return _notificationsRef
        .where(Filter.or(
          Filter('targetUserId', isNull: true), // Broadcasts
          Filter('targetUserId', isEqualTo: userId), // User-specific
        ))
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .where((n) => n.expiresAt == null || n.expiresAt!.isAfter(DateTime.now()))
              .toList();
        });
  }
  
  /// Get unread count for a user
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('read_notifications')
        .snapshots()
        .asyncMap((readSnapshot) async {
          final readIds = readSnapshot.docs.map((d) => d.id).toSet();
          
          final notifSnapshot = await _notificationsRef
              .where(Filter.or(
                Filter('targetUserId', isNull: true),
                Filter('targetUserId', isEqualTo: userId),
              ))
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();
          
          final unread = notifSnapshot.docs.where((doc) {
            final notif = AppNotification.fromFirestore(doc);
            return !readIds.contains(doc.id) && 
                   (notif.expiresAt == null || notif.expiresAt!.isAfter(DateTime.now()));
          }).length;
          
          return unread;
        });
  }
  
  /// Mark a notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('read_notifications')
          .doc(notificationId)
          .set({'readAt': FieldValue.serverTimestamp()});
      
      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _notificationsRef
          .where(Filter.or(
            Filter('targetUserId', isNull: true),
            Filter('targetUserId', isEqualTo: userId),
          ))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        final readRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('read_notifications')
            .doc(doc.id);
        batch.set(readRef, {'readAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
      
      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }
  
  /// Send a notification (Admin only)
  Future<void> sendNotification({
    required String title,
    required String body,
    String type = 'info',
    String? actionUrl,
    String? imageUrl,
    String? targetUserId,
    DateTime? expiresAt,
  }) async {
    try {
      await _notificationsRef.add({
        'title': title,
        'body': body,
        'type': type,
        if (actionUrl != null) 'actionUrl': actionUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (targetUserId != null) 'targetUserId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt),
      });
      
      debugPrint('📨 Notification sent: $title');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      rethrow;
    }
  }
  
  /// Delete a notification (Admin only)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
      debugPrint('🗑️ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      rethrow;
    }
  }
}

/// Provider for notification service
final notificationFirestoreServiceProvider = Provider<NotificationFirestoreService>((ref) {
  return NotificationFirestoreService();
});

/// Provider for user notifications stream
final userNotificationsProvider = StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  final service = ref.watch(notificationFirestoreServiceProvider);
  return service.getNotificationsForUser(userId);
});

/// Provider for unread count
final unreadNotificationCountProvider = StreamProvider.family<int, String>((ref, userId) {
  final service = ref.watch(notificationFirestoreServiceProvider);
  return service.getUnreadCount(userId);
});

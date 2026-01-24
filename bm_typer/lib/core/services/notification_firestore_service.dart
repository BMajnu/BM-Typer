import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/notification_model.dart';

/// Service for managing in-app notifications via Firestore
class NotificationFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Collection reference
  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  CollectionReference get _readNotificationsRef => _firestore.collection('users');

  String _effectiveUserId(String userId) {
    return _auth.currentUser?.uid ?? userId;
  }
  
  /// Get notifications for a user (broadcasts + user-specific merged client-side)
  Stream<List<AppNotification>> getNotificationsForUser(String userId) {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }
    final effectiveUserId = _effectiveUserId(userId);
    final controller = StreamController<List<AppNotification>>();

    QuerySnapshot? latestNotifSnap;
    QuerySnapshot? latestReadSnap;

    void emitIfReady() {
      if (latestNotifSnap == null || latestReadSnap == null) return;

      final readIds = latestReadSnap!.docs.map((d) => d.id).toSet();

      final notifications = latestNotifSnap!.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .where((n) {
            final isForUser =
                n.targetUserId == null ||
                n.targetUserId == effectiveUserId ||
                n.targetUserId == userId;
            final notExpired = n.expiresAt == null || n.expiresAt!.isAfter(DateTime.now());
            return isForUser && notExpired;
          })
          .map((n) => n.copyWith(isRead: readIds.contains(n.id)))
          .toList();

      controller.add(notifications);
    }

    late final StreamSubscription notifSub;
    late final StreamSubscription readSub;

    controller.onListen = () {
      notifSub = _notificationsRef
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen(
        (snapshot) {
          latestNotifSnap = snapshot;
          emitIfReady();
        },
        onError: (e, st) {
          debugPrint('❌ Error fetching notifications: $e');
          controller.addError(e, st);
        },
      );

      readSub = _readNotificationsRef
          .doc(effectiveUserId)
          .collection('read_notifications')
          .snapshots()
          .listen(
        (snapshot) {
          latestReadSnap = snapshot;
          emitIfReady();
        },
        onError: (e, st) {
          debugPrint('❌ Error fetching read notifications: $e');
          controller.addError(e, st);
        },
      );
    };

    controller.onCancel = () async {
      await notifSub.cancel();
      await readSub.cancel();
      await controller.close();
    };

    return controller.stream;
  }
  
  /// Get unread count for a user
  Stream<int> getUnreadCount(String userId) {
    if (_auth.currentUser == null) {
      return Stream.value(0);
    }
    final effectiveUserId = _effectiveUserId(userId);
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('read_notifications')
        .snapshots()
        .asyncMap((readSnapshot) async {
          try {
            final readIds = readSnapshot.docs.map((d) => d.id).toSet();
            
            final notifSnapshot = await _notificationsRef
                .orderBy('createdAt', descending: true)
                .limit(50)
                .get();
            
            final unread = notifSnapshot.docs.where((doc) {
              final notif = AppNotification.fromFirestore(doc);
              final isForUser =
                  notif.targetUserId == null ||
                  notif.targetUserId == effectiveUserId ||
                  notif.targetUserId == userId;
              final notExpired = notif.expiresAt == null || notif.expiresAt!.isAfter(DateTime.now());
              return isForUser && notExpired && !readIds.contains(doc.id);
            }).length;
            
            return unread;
          } catch (e) {
            debugPrint('❌ Error getting unread count: $e');
            return 0;
          }
        });
  }
  
  /// Mark a notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    if (_auth.currentUser == null) return;
    final effectiveUserId = _effectiveUserId(userId);
    try {
      await _firestore
          .collection('users')
          .doc(effectiveUserId)
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
    if (_auth.currentUser == null) return;
    final effectiveUserId = _effectiveUserId(userId);
    try {
      final notifications = await _notificationsRef
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        final notif = AppNotification.fromFirestore(doc);
        // Only mark if it's for this user (broadcast or targeted)
        if (notif.targetUserId == null ||
            notif.targetUserId == effectiveUserId ||
            notif.targetUserId == userId) {
          final readRef = _firestore
              .collection('users')
              .doc(effectiveUserId)
              .collection('read_notifications')
              .doc(doc.id);
          batch.set(readRef, {'readAt': FieldValue.serverTimestamp()});
        }
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

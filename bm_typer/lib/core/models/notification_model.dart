import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model for in-app notifications
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // info, success, warning, error, promo, update
  final String? actionUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isRead;
  final String? targetUserId; // null means broadcast to all
  
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.actionUrl,
    this.imageUrl,
    required this.createdAt,
    this.expiresAt,
    this.isRead = false,
    this.targetUserId,
  });
  
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'info',
      actionUrl: data['actionUrl'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: data['expiresAt'] != null 
        ? (data['expiresAt'] as Timestamp).toDate() 
        : null,
      isRead: data['isRead'] ?? false,
      targetUserId: data['targetUserId'],
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'isRead': isRead,
      if (targetUserId != null) 'targetUserId': targetUserId,
    };
  }
  
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? actionUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isRead,
    String? targetUserId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRead: isRead ?? this.isRead,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}

/// Notification types
class NotificationType {
  static const String info = 'info';
  static const String success = 'success';
  static const String warning = 'warning';
  static const String error = 'error';
  static const String promo = 'promo';
  static const String update = 'update';
  static const String achievement = 'achievement';
  
  static IconData getIcon(String type) {
    switch (type) {
      case info:
        return Icons.info_rounded;
      case success:
        return Icons.check_circle_rounded;
      case warning:
        return Icons.warning_rounded;
      case error:
        return Icons.error_rounded;
      case promo:
        return Icons.local_offer_rounded;
      case update:
        return Icons.system_update_rounded;
      case achievement:
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
  
  static Color getColor(String type) {
    switch (type) {
      case info:
        return Colors.blue;
      case success:
        return Colors.green;
      case warning:
        return Colors.orange;
      case error:
        return Colors.red;
      case promo:
        return Colors.purple;
      case update:
        return Colors.teal;
      case achievement:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

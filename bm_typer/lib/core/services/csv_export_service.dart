import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Service for exporting admin data to CSV
class CsvExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Export all users to CSV
  Future<void> exportUsersToCSV() async {
    try {
      debugPrint('📥 Starting user export...');
      
      final snapshot = await _firestore.collection('users').get();
      
      // CSV Headers
      final headers = [
        'User ID',
        'Name',
        'Email',
        'Phone',
        'Level',
        'XP',
        'Login Streak',
        'Is Premium',
        'Is Banned',
        'Created At',
        'Last Active',
      ];
      
      // Build CSV rows
      final rows = <List<String>>[];
      rows.add(headers);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        
        final row = [
          doc.id,
          (data['name'] ?? profile['name'] ?? '').toString(),
          (data['email'] ?? profile['email'] ?? '').toString(),
          _formatPhoneNumber(data['phone'] ?? profile['phoneNumber'] ?? data['phoneNumber'] ?? ''),
          (stats['level'] ?? data['level'] ?? 1).toString(),
          (stats['xp'] ?? data['xp'] ?? 0).toString(),
          (stats['loginStreak'] ?? data['loginStreak'] ?? 0).toString(),
          (data['isPremium'] ?? false).toString(),
          (data['isBanned'] ?? false).toString(),
          _formatTimestamp(data['createdAt']),
          _formatTimestamp(data['lastActive'] ?? data['lastLoginAt']),
        ];
        rows.add(row);
      }
      
      // Generate CSV string
      final csvContent = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
      
      // Download file
      _downloadCsv(csvContent, 'users_export_${_getTimestamp()}.csv');
      
      debugPrint('✅ User export completed: ${snapshot.docs.length} users');
    } catch (e) {
      debugPrint('❌ Error exporting users: $e');
      rethrow;
    }
  }
  
  /// Export subscriptions to CSV
  Future<void> exportSubscriptionsToCSV() async {
    try {
      debugPrint('📥 Starting subscription export...');
      
      final snapshot = await _firestore.collection('subscriptions').get();
      
      // CSV Headers
      final headers = [
        'Subscription ID',
        'User ID',
        'Plan Type',
        'Status',
        'Start Date',
        'End Date',
        'Amount',
        'Currency',
        'Payment Method',
        'Transaction ID',
      ];
      
      final rows = <List<String>>[];
      rows.add(headers);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        final row = [
          doc.id,
          (data['userId'] ?? '').toString(),
          (data['planType'] ?? data['type'] ?? '').toString(),
          (data['status'] ?? 'active').toString(),
          _formatTimestamp(data['startDate']),
          _formatTimestamp(data['endDate']),
          (data['amount'] ?? 0).toString(),
          (data['currency'] ?? 'BDT').toString(),
          (data['paymentMethod'] ?? '').toString(),
          (data['transactionId'] ?? '').toString(),
        ];
        rows.add(row);
      }
      
      final csvContent = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
      _downloadCsv(csvContent, 'subscriptions_export_${_getTimestamp()}.csv');
      
      debugPrint('✅ Subscription export completed: ${snapshot.docs.length} records');
    } catch (e) {
      debugPrint('❌ Error exporting subscriptions: $e');
      rethrow;
    }
  }
  
  /// Export organization members to CSV
  Future<void> exportOrganizationMembersToCSV(String orgId, String orgName) async {
    try {
      debugPrint('📥 Starting org members export for: $orgId');
      
      final membersSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .get();
      
      // CSV Headers
      final headers = [
        'Member ID',
        'Name',
        'Email',
        'Role',
        'Joined At',
      ];
      
      final rows = <List<String>>[];
      rows.add(headers);
      
      for (final doc in membersSnapshot.docs) {
        final data = doc.data();
        
        // Try to get user details
        String name = '';
        String email = '';
        try {
          final userDoc = await _firestore.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            name = userData?['name'] ?? userData?['profile']?['name'] ?? '';
            email = userData?['email'] ?? userData?['profile']?['email'] ?? '';
          }
        } catch (e) {
          debugPrint('Could not fetch user details for ${doc.id}');
        }
        
        final row = [
          doc.id,
          name,
          email,
          (data['role'] ?? 'member').toString(),
          _formatTimestamp(data['joinedAt'] ?? data['addedAt']),
        ];
        rows.add(row);
      }
      
      final csvContent = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
      final safeOrgName = orgName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      _downloadCsv(csvContent, 'org_${safeOrgName}_members_${_getTimestamp()}.csv');
      
      debugPrint('✅ Org members export completed: ${membersSnapshot.docs.length} members');
    } catch (e) {
      debugPrint('❌ Error exporting org members: $e');
      rethrow;
    }
  }
  
  /// Export typing test results for analytics
  Future<void> exportTypingTestResultsToCSV() async {
    try {
      debugPrint('📥 Starting typing test results export...');
      
      final snapshot = await _firestore
          .collectionGroup('sessions')
          .orderBy('startTime', descending: true)
          .limit(1000)
          .get();
      
      final headers = [
        'Session ID',
        'User ID',
        'WPM',
        'Accuracy',
        'Duration (min)',
        'Characters Typed',
        'Errors',
        'Layout',
        'Date',
      ];
      
      final rows = <List<String>>[];
      rows.add(headers);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Extract user ID from path
        final pathParts = doc.reference.path.split('/');
        final userId = pathParts.length > 1 ? pathParts[1] : '';
        
        final row = [
          doc.id,
          userId,
          (data['wpm'] ?? 0).toString(),
          (data['accuracy'] ?? 0).toString(),
          (data['durationMinutes'] ?? 0).toString(),
          (data['charactersTyped'] ?? data['totalCharacters'] ?? 0).toString(),
          (data['errors'] ?? 0).toString(),
          (data['layout'] ?? 'bijoy').toString(),
          _formatTimestamp(data['startTime'] ?? data['createdAt']),
        ];
        rows.add(row);
      }
      
      final csvContent = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
      _downloadCsv(csvContent, 'typing_results_export_${_getTimestamp()}.csv');
      
      debugPrint('✅ Typing results export completed: ${snapshot.docs.length} sessions');
    } catch (e) {
      debugPrint('❌ Error exporting typing results: $e');
      rethrow;
    }
  }
  
  // --- Helper Methods ---
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp);
    }
    
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }
  
  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }
  
  /// Format phone number to prevent Excel scientific notation
  String _formatPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    
    String phoneStr = phone.toString().trim();
    if (phoneStr.isEmpty) return '';
    
    // Ensure it starts with + for international format
    if (!phoneStr.startsWith('+') && phoneStr.length > 10) {
      phoneStr = '+$phoneStr';
    }
    
    // Return as-is, will be wrapped in quotes by _escapeCsv if needed
    return phoneStr;
  }
  
  String _escapeCsv(String value) {
    // Force phone numbers and long numeric strings to be treated as text
    if (value.startsWith('+') || (value.length > 10 && RegExp(r'^\d+$').hasMatch(value))) {
      return '"$value"';
    }
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
  
  void _downloadCsv(String content, String filename) {
    if (kIsWeb) {
      // Web download using dart:html
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      html.Url.revokeObjectUrl(url);
      debugPrint('📁 Downloaded: $filename');
    } else {
      // For mobile/desktop, you would use path_provider and file.writeAsBytes
      debugPrint('⚠️ Desktop/Mobile CSV download not implemented');
    }
  }
}

/// Provider for CSV Export Service
final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService();
});

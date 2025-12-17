import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/organization_model.dart';

/// Admin service for managing organizations
class AdminOrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all organizations
  Stream<List<OrganizationModel>> getAllOrganizations() {
    return _firestore
        .collection('organizations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrganizationModel.fromFirestore(doc))
            .toList());
  }

  /// Get organization by ID
  Future<OrganizationModel?> getOrganization(String orgId) async {
    try {
      final doc = await _firestore.collection('organizations').doc(orgId).get();
      if (!doc.exists) return null;
      return OrganizationModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error getting organization: $e');
      return null;
    }
  }

  /// Create new organization
  Future<String?> createOrganization({
    required String name,
    required String adminEmail,
    String? adminUserId,
    int maxMembers = 10,
    String subscriptionType = 'team_monthly',
    int durationDays = 30,
  }) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: durationDays));

      final docRef = await _firestore.collection('organizations').add({
        'name': name,
        'adminEmail': adminEmail,
        'adminUserId': adminUserId,
        'memberCount': 0,
        'maxMembers': maxMembers,
        'subscriptionType': subscriptionType,
        'expiryDate': expiryDate.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'isActive': true,
      });

      debugPrint('✅ Organization created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating organization: $e');
      return null;
    }
  }

  /// Update organization
  Future<bool> updateOrganization(String orgId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('organizations').doc(orgId).update(data);
      debugPrint('✅ Organization updated');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating organization: $e');
      return false;
    }
  }

  /// Delete organization
  Future<bool> deleteOrganization(String orgId) async {
    try {
      // First remove all members
      final membersSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .get();

      for (final doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete org
      await _firestore.collection('organizations').doc(orgId).delete();
      debugPrint('✅ Organization deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting organization: $e');
      return false;
    }
  }

  /// Get organization members
  Stream<List<OrgMemberModel>> getMembers(String orgId) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrgMemberModel.fromFirestore(doc))
            .toList());
  }

  /// Add member to organization
  Future<bool> addMember({
    required String orgId,
    required String userId,
    required String email,
    required String name,
    String role = 'member',
  }) async {
    try {
      // Check if org can add more members
      final org = await getOrganization(orgId);
      if (org == null || !org.canAddMembers) {
        debugPrint('❌ Organization full or not found');
        return false;
      }

      final now = DateTime.now();

      // Add member
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .add({
        'userId': userId,
        'email': email,
        'name': name,
        'role': role,
        'joinedAt': now.toIso8601String(),
        'isActive': true,
      });

      // Update member count
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(1),
      });

      // Update user's organizationId
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'organizationId': orgId,
        });
      }

      debugPrint('✅ Member added to organization');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      return false;
    }
  }

  /// Remove member from organization
  Future<bool> removeMember(String orgId, String memberId) async {
    try {
      // Get member email before deletion
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberId)
          .get();

      if (memberDoc.exists) {
        final email = memberDoc.data()?['email'] as String?;

        // Remove organizationId from user
        if (email != null) {
          final userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            await userQuery.docs.first.reference.update({
              'organizationId': null,
            });
          }
        }
      }

      // Delete member
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberId)
          .delete();

      // Update member count
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(-1),
      });

      debugPrint('✅ Member removed from organization');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      return false;
    }
  }

  /// Get organization stats
  Future<Map<String, dynamic>> getOrganizationStats() async {
    try {
      final allOrgs = await _firestore.collection('organizations').get();
      
      int totalMembers = 0;
      int activeOrgs = 0;

      for (final doc in allOrgs.docs) {
        final data = doc.data();
        totalMembers += (data['memberCount'] as int?) ?? 0;
        if (data['isActive'] == true) activeOrgs++;
      }

      return {
        'totalOrganizations': allOrgs.docs.length,
        'activeOrganizations': activeOrgs,
        'totalMembers': totalMembers,
      };
    } catch (e) {
      debugPrint('❌ Error getting stats: $e');
      return {};
    }
  }

  /// Extend organization subscription
  Future<bool> extendSubscription(String orgId, int additionalDays) async {
    try {
      final doc = await _firestore.collection('organizations').doc(orgId).get();
      if (!doc.exists) return false;

      final currentEnd = DateTime.parse(doc.data()?['expiryDate'] as String);
      final newEnd = currentEnd.add(Duration(days: additionalDays));

      await _firestore.collection('organizations').doc(orgId).update({
        'expiryDate': newEnd.toIso8601String(),
        'isActive': true,
      });

      debugPrint('✅ Org subscription extended');
      return true;
    } catch (e) {
      debugPrint('❌ Error extending subscription: $e');
      return false;
    }
  }

  /// Search users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase();
      
      debugPrint('🔍 Fetching users for query: "$query"');
      
      // Fetch users (increased limit)
      final allUsers = await _firestore
          .collection('users')
          .limit(500)
          .get();
          
      debugPrint('🔍 Total users fetched from DB: ${allUsers.docs.length}');

      final List<Map<String, dynamic>> results = [];
      
      for (final doc in allUsers.docs) {
        final data = doc.data();
        
        final profile = data['profile'] as Map<String, dynamic>?;

        // Try multiple field variants including nested profile
        final name = (data['name'] ?? profile?['name'] ?? data['userName'] ?? data['displayName'] ?? data['fullName'] ?? '').toString();
        final email = (data['email'] ?? profile?['email'] ?? data['userEmail'] ?? '').toString();
        final phone = (data['phone'] ?? profile?['phoneNumber'] ?? profile?['phone'] ?? data['phoneNumber'] ?? '').toString();
        final userId = (data['userId'] ?? profile?['customUserId'] ?? doc.id).toString();
        final photoUrl = data['photoUrl'] ?? profile?['photoUrl'] ?? data['photoURL']; // Keep null if missing
        
        final nameLower = name.toLowerCase();
        final emailLower = email.toLowerCase();
        final userIdLower = userId.toLowerCase();
        
        // If query is empty, add everything
        if (query.isEmpty || 
            nameLower.contains(queryLower) || 
            emailLower.contains(queryLower) || 
            userIdLower.contains(queryLower)) {
          results.add({
            'id': doc.id,
            'userId': userId,
            'name': name,
            'email': email,
            'phone': phone,
            'photoUrl': photoUrl,
          });
        }
        
        if (results.length >= 20) break;
      }

      debugPrint('✅ Found ${results.length} matches');
      return results;
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }

  /// Create a new Firebase user and add to organization
  Future<Map<String, dynamic>> createAndAddMember({
    required String orgId,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? customUserId,
  }) async {
    try {
      // Check if org can add more members
      final org = await getOrganization(orgId);
      if (org == null || !org.canAddMembers) {
        return {'success': false, 'error': 'প্রতিষ্ঠানে আর সদস্য যুক্ত করা যাচ্ছে না'};
      }

      // Check if email already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {'success': false, 'error': 'এই ইমেইল দিয়ে ইউজার আগে থেকেই আছে'};
      }

      // Store current user to restore later (if admin is logged in)
      final currentUser = _auth.currentUser;

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'error': 'ইউজার তৈরি করা যায়নি'};
      }

      final now = DateTime.now();
      final generatedUserId = customUserId ?? 'BM${now.millisecondsSinceEpoch.toString().substring(5)}';

      // Create Firestore user document
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'userId': generatedUserId,
        'name': name,
        'email': email,
        'phone': phone,
        'organizationId': orgId,
        'createdAt': now.toIso8601String(),
        'isActive': true,
        'isPremium': true, // Org members get premium
        'subscriptionType': 'organization',
        'level': 1,
        'xp': 0,
        'totalTypingTime': 0,
        'lessonsCompleted': 0,
        'photoUrl': null,
      });

      // Add to organization members
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .add({
        'userId': firebaseUser.uid,
        'email': email,
        'name': name,
        'role': 'member',
        'joinedAt': now.toIso8601String(),
        'isActive': true,
      });

      // Update member count
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(1),
      });

      // Sign out the newly created user and restore admin session if needed
      await _auth.signOut();
      
      debugPrint('✅ New user created and added to organization');
      return {
        'success': true, 
        'userId': generatedUserId,
        'firebaseUid': firebaseUser.uid,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'ইউজার তৈরিতে সমস্যা হয়েছে';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'এই ইমেইল ইতিমধ্যে ব্যবহৃত';
      } else if (e.code == 'weak-password') {
        errorMessage = 'পাসওয়ার্ড দুর্বল (কমপক্ষে ৬ অক্ষর)';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'ইমেইল ফরম্যাট ভুল';
      }
      debugPrint('❌ Firebase Auth Error: ${e.code}');
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      return {'success': false, 'error': 'অজানা ত্রুটি: $e'};
    }
  }

  /// Add existing user to organization by user ID
  Future<bool> addExistingUserToOrg({
    required String orgId,
    required String firestoreUserId,
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      final org = await getOrganization(orgId);
      if (org == null || !org.canAddMembers) {
        debugPrint('❌ Organization full or not found');
        return false;
      }

      final now = DateTime.now();

      // Add to organization members
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .add({
        'userId': firestoreUserId,
        'email': email,
        'name': name,
        'role': 'member',
        'joinedAt': now.toIso8601String(),
        'isActive': true,
      });

      // Update member count
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(1),
      });

      // Update user's organizationId
      await _firestore.collection('users').doc(firestoreUserId).update({
        'organizationId': orgId,
        'isPremium': true,
        'subscriptionType': 'organization',
      });

      debugPrint('✅ Existing user added to organization');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding existing user: $e');
      return false;
    }
  }
}

/// Provider for admin organization service
final adminOrganizationServiceProvider = Provider<AdminOrganizationService>((ref) {
  return AdminOrganizationService();
});

/// Provider for all organizations stream
final allOrganizationsProvider = StreamProvider<List<OrganizationModel>>((ref) {
  final service = ref.watch(adminOrganizationServiceProvider);
  return service.getAllOrganizations();
});

/// Provider for organization stats
final organizationStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(adminOrganizationServiceProvider);
  return service.getOrganizationStats();
});

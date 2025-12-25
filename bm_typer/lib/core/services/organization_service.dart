import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bm_typer/core/models/organization_model.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';

/// Service to manage organizations and teams
class OrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudSyncService _syncService = CloudSyncService();

  /// Create a new organization
  Future<OrganizationModel?> createOrganization({
    required String name,
    required UserModel creator,
    String subscriptionType = 'team_monthly',
  }) async {
    try {
      final orgId = const Uuid().v4();
      final now = DateTime.now();

      final org = OrganizationModel(
        id: orgId,
        name: name,
        adminEmail: creator.email,
        adminUserId: creator.id,
        createdAt: now,
        subscriptionType: subscriptionType,
        expiryDate: now.add(const Duration(days: 30)), // 30 day trial
        memberCount: 1, // Creator is first member
      );

      // 1. Create Org Document
      await _firestore.collection('organizations').doc(orgId).set(org.toJson());

      // 2. Add Creator as Admin Member
      final member = OrgMemberModel(
        id: const Uuid().v4(),
        userId: creator.id,
        email: creator.email,
        name: creator.name,
        role: 'admin',
        joinedAt: now,
      );

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(creator.id)
          .set(member.toJson());

      // 3. Update Creator's User Profile (Role & OrgId)
      await _firestore.collection('users').doc(creator.id).update({
        'profile.organizationId': orgId,
        'profile.role': UserRole.orgAdmin.name, // Update to Enum name
      });

      return org;
    } catch (e) {
      debugPrint('❌ Error creating organization: $e');
      return null;
    }
  }

  /// Get organization by ID
  Future<OrganizationModel?> getOrganization(String orgId) async {
    try {
      final doc = await _firestore.collection('organizations').doc(orgId).get();
      if (doc.exists) {
        return OrganizationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching organization: $e');
      return null;
    }
  }

  /// Add a member to organization
  Future<bool> addMember({
    required String orgId,
    required String email,
  }) async {
    try {
      // 1. Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('profile.email', isEqualTo: email) // Check nested profile first
          .limit(1)
          .get();

      String userId;
      String userName;
      String? currentOrgId;
      Map<String, dynamic> userData;

      if (userQuery.docs.isNotEmpty) {
        userData = userQuery.docs.first.data();
        userId = userQuery.docs.first.id;
        userName = userData['profile']['name'] ?? 'Unknown Member';
        currentOrgId = userData['profile']['organizationId'];
      } else {
        // Fallback: Check root email (legacy structure)
        final rootQuery = await _firestore
           .collection('users')
           .where('email', isEqualTo: email)
           .limit(1)
           .get();
           
        if (rootQuery.docs.isEmpty) {
           throw Exception('User not found with email: $email');
        }
        
        userData = rootQuery.docs.first.data();
        userId = rootQuery.docs.first.id;
        userName = userData['name'] ?? 'Unknown Member';
        currentOrgId = userData['organizationId'];
      }

      if (currentOrgId != null) {
        throw Exception('User already belongs to an organization');
      }

      // 2. Check Org Limits
      final orgDoc = await _firestore.collection('organizations').doc(orgId).get();
      if (!orgDoc.exists) throw Exception('Organization not found');
      
      final org = OrganizationModel.fromFirestore(orgDoc);
      if (!org.canAddMembers) {
         throw Exception('Organization member limit reached');
      }

      // 3. Add to members sub-collection
      final member = OrgMemberModel(
        id: const Uuid().v4(),
        userId: userId,
        email: email,
        name: userName,
        role: 'member',
        joinedAt: DateTime.now(),
        photoUrl: userData['profile'] != null 
            ? userData['profile']['photoUrl'] 
            : userData['photoUrl'], // Handle legacy structure
      );

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(userId)
          .set(member.toJson());

      // 4. Update User Profile
      await _firestore.collection('users').doc(userId).update({
        'profile.organizationId': orgId,
        // Optional: Do we change their role to 'student'? Usually yes.
      });

      // 5. Increment Member Count
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      rethrow; // Pass error up to UI
    }
  }

  /// Get all members of an organization
  Stream<List<OrgMemberModel>> getMembersStream(String orgId) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrgMemberModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Find organization by user email (searches owner first, then members)
  Future<OrganizationModel?> getOrgByUserEmail(String email) async {
    try {
      // 1. Check if user is the Admin/Owner of an organization
      final ownerQuery = await _firestore
          .collection('organizations')
          .where('adminEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (ownerQuery.docs.isNotEmpty) {
        return OrganizationModel.fromFirestore(ownerQuery.docs.first);
      }

      // 2. Fallback: Query all organizations and check their members
      // TODO: This is inefficient for large scale. Should use collection group query if possible 
      // or denormalize member emails array in org doc.
      final orgsSnapshot = await _firestore.collection('organizations').get();
      
      for (final orgDoc in orgsSnapshot.docs) {
        final memberQuery = await _firestore
            .collection('organizations')
            .doc(orgDoc.id)
            .collection('members')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
            
        if (memberQuery.docs.isNotEmpty) {
          return OrganizationModel.fromFirestore(orgDoc);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error finding org by email: $e');
      return null;
    }
  }

  /// Assign a member as Team Lead
  Future<bool> assignTeamLead({
    required String orgId,
    required String memberDocId, // Document ID in members subcollection
    required String userId,     // User's actual Auth ID
    required bool isTeamLead,
  }) async {
    try {
      // 1. Update member document in org
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberDocId)
          .update({
        'isTeamLead': isTeamLead,
        'role': isTeamLead ? 'team_lead' : 'member',
      });

      // 2. Update user's role in users collection
      await _firestore.collection('users').doc(userId).update({
        'profile.role': isTeamLead ? UserRole.teamLead.name : UserRole.student.name,
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error assigning team lead: $e');
      return false;
    }
  }

  /// Block/Unblock a member
  Future<bool> blockMember({
    required String orgId,
    required String memberId,
    required bool block,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberId)
          .update({'isActive': !block});

      return true;
    } catch (e) {
      debugPrint('❌ Error blocking member: $e');
      return false;
    }
  }

  /// Remove member from organization
  Future<bool> removeMember({
    required String orgId,
    required String memberId,
  }) async {
    try {
      // 1. Delete from members subcollection
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberId)
          .delete();

      // 2. Clear organizationId from user
      await _firestore.collection('users').doc(memberId).update({
        'profile.organizationId': null,
        'profile.role': UserRole.student.name,
      });

      // 3. Decrement member count
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      return false;
    }
  }

  /// Get member details with user stats
  Future<Map<String, dynamic>?> getMemberDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      return userDoc.data();
    } catch (e) {
      debugPrint('❌ Error getting member details: $e');
      return null;
    }
  }
}

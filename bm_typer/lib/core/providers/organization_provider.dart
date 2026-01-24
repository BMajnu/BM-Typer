import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/organization_service.dart';
import 'package:bm_typer/core/models/organization_model.dart';
import 'package:bm_typer/core/providers/user_provider.dart';

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService();
});

/// Provider for the current user's organization
/// Uses autoDispose to prevent caching stale data across browser sessions
final currentOrgProvider = FutureProvider.autoDispose<OrganizationModel?>((ref) async {
  // Keep alive only after successful fetch
  final link = ref.keepAlive();
  
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('🔍 currentOrgProvider: User is null, returning null');
    link.close(); // Don't keep alive if no user
    return null;
  }

  final service = ref.watch(organizationServiceProvider);
  
  debugPrint('🔍 currentOrgProvider: User email=${user.email}, orgId=${user.organizationId}, role=${user.role.name}');
  
  // First try by organizationId
  if (user.organizationId != null && user.organizationId!.isNotEmpty) {
    debugPrint('🔍 Fetching org by ID: ${user.organizationId}');
    try {
      final org = await service.getOrganization(user.organizationId!);
      if (org != null) {
        debugPrint('✅ Org found by ID: ${org.name}');
        return org;
      } else {
        debugPrint('⚠️ Org not found by ID: ${user.organizationId}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching org by ID: $e');
    }
  }
  
  // Fallback: Search by user email in members subcollection
  debugPrint('🔍 Searching org for user by email: ${user.email}');
  try {
    final org = await service.getOrgByUserEmail(user.email);
    debugPrint('🔍 Search result: ${org?.name ?? "Not Found"}');
    return org;
  } catch (e) {
    debugPrint('❌ Error searching org by email: $e');
    link.close(); // Don't keep alive on error
    return null;
  }
});

/// Stream of members for the current org
final orgMembersProvider = StreamProvider<List<OrgMemberModel>>((ref) {
  final orgAsync = ref.watch(currentOrgProvider);
  
  return orgAsync.when(
    data: (org) {
      if (org == null) return Stream.value([]);
      final service = ref.watch(organizationServiceProvider);
      return service.getMembersStream(org.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Stream of members specifically for the current Team Lead
final teamMembersProvider = StreamProvider<List<OrgMemberModel>>((ref) {
  final orgAsync = ref.watch(currentOrgProvider);
  final user = ref.watch(currentUserProvider);
  
  return orgAsync.when(
    data: (org) {
      if (org == null) {
        debugPrint('❌ TeamMembersProvider: Org is null');
        return Stream.value([]);
      } 
      if (user == null) {
        debugPrint('❌ TeamMembersProvider: User is null');
        return Stream.value([]);
      }
      
      debugPrint('✅ TeamMembersProvider: Fetching members for org ${org.name}');
      final service = ref.watch(organizationServiceProvider);
      
      return service.getMembersStream(org.id).map((members) {
        // TEMPORARY FIX: Since we don't have logic to assign members to specific team leads yet,
        // we will show ALL organization members to the Team Lead.
        // This ensures they at least see the people in the organization.
        return members; 
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

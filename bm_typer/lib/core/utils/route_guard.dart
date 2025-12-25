import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/admin_auth_service.dart';
import 'package:bm_typer/core/providers/organization_provider.dart';

/// Route guard widget that restricts access based on user role
class RouteGuard extends ConsumerWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final Widget? accessDeniedWidget;

  const RouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.accessDeniedWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final adminAuthService = ref.watch(adminAuthServiceProvider);
    
    // If no user, show access denied
    if (user == null) {
      return accessDeniedWidget ?? const _AccessDeniedScreen();
    }
    
    // Check if user is in legacy admin emails list (Super Admin)
    if (adminAuthService.isAdminEmail(user.email)) {
      return child;
    }
    
    // Super Admin role can access everything
    if (user.role == UserRole.superAdmin) {
      return child;
    }
    
    // Check if user's role is in allowed roles
    if (allowedRoles.contains(user.role)) {
      return child;
    }

    // SPECIAL CASE: Allow Organization Owner to access Org Admin & Team Lead routes
    // regardless of their current role (e.g. if they are technically a 'Team Lead' role but own the org)
    final orgAsync = ref.watch(currentOrgProvider);
    if (orgAsync.hasValue && orgAsync.value != null) {
       final org = orgAsync.value!;
       if (org.adminUserId == user.id) {
          // Owner can access Team Lead and Org Admin routes
          // We can infer the route based on the child? No, RouteGuard doesn't know the route name easily.
          // But allowedRoles usually distinguishes the intent.
          
          // If the route requires OrgAdmin or TeamLead, and user is owner -> Allow
          if (allowedRoles.contains(UserRole.orgAdmin) || allowedRoles.contains(UserRole.teamLead)) {
             return child;
          }
       }
    }
    
    // SPECIAL CASE: Allow member marked as Team Lead in the Org to access Team Lead routes
    // This handles cases where the local user role isn't synced, but they are isTeamLead in the org.
    if (allowedRoles.contains(UserRole.teamLead)) {
       final membersAsync = ref.watch(orgMembersProvider);
       if (membersAsync.hasValue) {
          final members = membersAsync.value ?? [];
          final currentMember = members.where((m) => m.email == user.email).firstOrNull;
          if (currentMember != null && currentMember.isTeamLead) {
             return child; // Member is marked as team lead in org, grant access
          }
       }
    }
    
    // Access denied
    return accessDeniedWidget ?? const _AccessDeniedScreen();
  }
}

/// Default Access Denied Screen
class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'অ্যাক্সেস অস্বীকৃত',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'আপনার এই পেজ দেখার অনুমতি নেই।',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('ফিরে যান'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to check route access
bool canAccessRoute(UserRole? userRole, String route) {
  if (userRole == null) return false;
  
  // Super Admin can access all routes
  if (userRole == UserRole.superAdmin) return true;
  
  switch (route) {
    case '/admin':
      return userRole == UserRole.superAdmin;
    case '/org_admin':
      return userRole == UserRole.orgAdmin || userRole == UserRole.superAdmin;
    case '/team_lead':
      return userRole == UserRole.teamLead || 
             userRole == UserRole.orgAdmin || 
             userRole == UserRole.superAdmin;
    default:
      return true; // Public routes
  }
}

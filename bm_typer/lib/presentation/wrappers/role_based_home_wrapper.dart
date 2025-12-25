import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/presentation/screens/auth_screen.dart';
import 'package:bm_typer/presentation/screens/tutor_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:bm_typer/presentation/screens/team_lead/team_lead_dashboard_screen.dart';
import 'package:bm_typer/presentation/screens/org_admin/org_admin_dashboard_screen.dart';

/// A wrapper widget that routes the user to the appropriate screen based on their role.
class RoleBasedHomeWrapper extends ConsumerWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // 1. Not Authenticated -> Auth Screen
    if (user == null) {
      return const AuthScreen();
    }

    // 2. Authenticated -> Route based on Role
    switch (user.role) {
      case UserRole.student:
        return const TutorScreen();
        
      case UserRole.teamLead:
        return const TeamLeadDashboardScreen();
        
      case UserRole.orgAdmin:
        return const OrgAdminDashboardScreen();
        
      case UserRole.superAdmin:
        return const AdminDashboardScreen();
    }
  }
}

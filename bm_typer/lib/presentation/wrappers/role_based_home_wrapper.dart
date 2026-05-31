import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/presentation/screens/auth_screen.dart';
import 'package:bm_typer/presentation/screens/tutor_screen.dart';

/// A wrapper widget that routes the user to the appropriate screen based on their role.
/// All authenticated users see the TutorScreen (typing dashboard) first.
/// Admin/Team Lead dashboards are accessible via role-based buttons in TutorScreen.
class RoleBasedHomeWrapper extends ConsumerWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // 1. Not Authenticated -> Auth Screen
    if (user == null) {
      return const AuthScreen();
    }

    // 2. Authenticated -> Show TutorScreen (typing dashboard) for ALL users
    // Admin/Team Lead dashboards are accessible via navigation buttons in TutorScreen
    return const TutorScreen();
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_service.dart';

/// Checks if the current user has admin privileges.
/// Returns true if admin, false otherwise.
Future<bool> isUserAdmin(String userId) async {
  final userService = UserService();
  return userService.checkAdminStatus(userId);
}

/// A widget that guards admin-only screens.
/// Redirects to home if the user is not an admin.
class AdminGuard extends StatelessWidget {
  final Widget child;
  final String userId;

  const AdminGuard({super.key, required this.child, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserAdmin(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = snapshot.data ?? false;
        if (!isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin access required'),
              ),
            );
            context.go('/home');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return child;
      },
    );
  }
}

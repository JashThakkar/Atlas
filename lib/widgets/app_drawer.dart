import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    
    return Drawer(
      child: currentUserAsync.when(
        data: (user) => ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? ''),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(user?.displayName[0].toUpperCase() ?? 'A')
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Workouts'),
              onTap: () {
                Navigator.pop(context);
                context.push('/workouts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: const Text('Body Metrics'),
              onTap: () {
                Navigator.pop(context);
                context.push('/body-metrics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('AI Diet Coach'),
              onTap: () {
                Navigator.pop(context);
                context.push('/ai-chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.feed),
              title: const Text('Community Feed'),
              onTap: () {
                Navigator.pop(context);
                context.push('/feed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Challenges'),
              onTap: () {
                Navigator.pop(context);
                context.push('/challenges');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report a Bug'),
              onTap: () {
                Navigator.pop(context);
                context.push('/bug-report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
      ),
    );
  }
}

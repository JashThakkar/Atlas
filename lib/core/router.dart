import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/workouts/workouts_screen.dart';
import '../screens/workouts/workout_detail_screen.dart';
import '../screens/workouts/generate_workout_screen.dart';
import '../screens/workouts/time_constrained_workout_screen.dart';
import '../screens/exercises/exercise_logger_screen.dart';
import '../screens/exercises/exercise_history_screen.dart';
import '../screens/body_metrics/body_metrics_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/social/feed_screen.dart';
import '../screens/social/create_post_screen.dart';
import '../screens/social/post_detail_screen.dart';
import '../screens/social/discover_friends_screen.dart';
import '../screens/social/user_profile_screen.dart';
import '../screens/social/friend_requests_screen.dart';
import '../screens/social/messages_screen.dart';
import '../screens/social/chat_screen.dart';
import '../screens/challenges/challenges_screen.dart';
import '../screens/circles/circles_screen.dart';
import '../screens/circles/join_or_create_circle_screen.dart';
import '../screens/circles/circle_detail_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/create_challenge_screen.dart';
import '../screens/admin/manage_challenges_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/bug_report_screen.dart';
import '../core/admin_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/login',
    // Gracefully handle any route GoRouter cannot match (e.g. after a deep
    // link with an unrecognised path).
    errorBuilder: (context, state) => const HomeScreen(),
    redirect: (context, state) {
      // The Spotify OAuth callback arrives as a custom-scheme deep link
      // (atlasfit://spotify-callback/?code=…).  It is handled by the
      // app_links listener in main.dart; GoRouter must not try to match it
      // as an HTTP path or it will throw GoException.
      if (state.uri.scheme == 'atlasfit' &&
          state.uri.host == 'spotify-callback') {
        return '/home';
      }

      // Handle loading state
      if (authState.isLoading) {
        return null; // Don't redirect while loading
      }
      
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';
      
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/workouts',
        builder: (context, state) => const WorkoutsScreen(),
      ),
      GoRoute(
        path: '/workouts/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WorkoutDetailScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/generate-workout',
        builder: (context, state) => const GenerateWorkoutScreen(),
      ),
      GoRoute(
        path: '/quick-workout',
        builder: (context, state) => const TimeConstrainedWorkoutScreen(),
      ),
      GoRoute(
        path: '/exercise-logger',
        builder: (context, state) => const ExerciseLoggerScreen(),
      ),
      GoRoute(
        path: '/exercise-history',
        builder: (context, state) => const ExerciseHistoryScreen(),
      ),
      GoRoute(
        path: '/body-metrics',
        builder: (context, state) => const BodyMetricsScreen(),
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/discover-friends',
        builder: (context, state) => const DiscoverFriendsScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return UserProfileScreen(
            userId: userId,
            userName: extra?['userName'] as String? ?? 'User',
          );
        },
      ),
      GoRoute(
        path: '/friend-requests',
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            chatId: chatId,
            otherUserId: extra?['otherUserId'] ?? '',
            otherUserName: extra?['otherUserName'] ?? 'Chat',
          );
        },
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: '/circles',
        builder: (context, state) => const CirclesScreen(),
      ),
      GoRoute(
        path: '/circles/join-or-create',
        builder: (context, state) => const JoinOrCreateCircleScreen(),
      ),
      GoRoute(
        path: '/circles/:circleId',
        builder: (context, state) {
          final circleId = state.pathParameters['circleId']!;
          return CircleDetailScreen(circleId: circleId);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          final currentUser = ref.read(authStateProvider).value;
          if (currentUser == null) return const HomeScreen();
          return AdminGuard(
            userId: currentUser.uid,
            child: const AdminDashboardScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/create-challenge',
        builder: (context, state) {
          final currentUser = ref.read(authStateProvider).value;
          if (currentUser == null) return const HomeScreen();
          return AdminGuard(
            userId: currentUser.uid,
            child: const CreateChallengeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/manage-challenges',
        builder: (context, state) {
          final currentUser = ref.read(authStateProvider).value;
          if (currentUser == null) return const HomeScreen();
          return AdminGuard(
            userId: currentUser.uid,
            child: const ManageChallengesScreen(),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/bug-report',
        builder: (context, state) => const BugReportScreen(),
      ),
    ],
  );
});

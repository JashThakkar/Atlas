import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) async* {
      if (user != null) {
        try {
          final authService = ref.read(authServiceProvider);
          final userProfile = await authService.getUserProfile(user.uid);
          yield userProfile;
        } catch (e) {
          print('❌ Error loading user profile: $e');
          
          // For network/unavailable errors, yield null instead of throwing
          // This allows the UI to show a better offline state
          if (e.toString().contains('unavailable') || 
              e.toString().contains('deadline-exceeded') ||
              e.toString().contains('Cannot connect to Firestore')) {
            print('🌐 Network issue detected, yielding null for offline handling');
            yield null;
          } else {
            // For other errors, still throw so they can be handled by error UI
            throw Exception('Failed to load user profile: $e');
          }
        }
      } else {
        yield null;
      }
    },
    loading: () => Stream.value(null),
    error: (error, stackTrace) {
      print('❌ Auth state error: $error');
      throw error;
    },
  );
});

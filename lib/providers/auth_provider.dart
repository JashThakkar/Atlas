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
        final authService = ref.read(authServiceProvider);
        yield await authService.getUserProfile(user.uid);
      } else {
        yield null;
      }
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

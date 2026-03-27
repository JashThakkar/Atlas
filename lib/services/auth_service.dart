import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _logError(String operation, Object error, [StackTrace? stackTrace]) {
    debugPrint('');
    debugPrint('🔥 AuthService Error: $operation');
    debugPrint('❌ Error: $error');
    if (stackTrace != null) {
      debugPrint('📋 Stack: $stackTrace');
    }
    debugPrint('');
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('🔐 Attempting signup for email: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User created successfully: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        debugPrint('👤 Creating user profile in SQLite...');
        await _createUserProfile(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
        );
        debugPrint('✅ User profile created successfully');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'keychain-error') {
        debugPrint('🔑 Keychain error detected - this is common on iOS Simulator');
        throw Exception(
            'Authentication keychain error. Please try resetting the iOS Simulator or use a different device.');
      }
      _logError('signUpWithEmail', e, StackTrace.current);
      rethrow;
    } catch (e, stackTrace) {
      _logError('signUpWithEmail', e, stackTrace);
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting signin for email: $email');

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User signed in successfully: ${result.user?.uid}');

      // Ensure a local profile exists for this user (e.g. first login on
      // a new device or after clearing app data).
      if (result.user != null) {
        await _ensureLocalProfile(result.user!);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'keychain-error') {
        debugPrint('🔑 Keychain error detected - this is common on iOS Simulator');
        throw Exception(
            'Authentication keychain error. Please try resetting the iOS Simulator or use a different device.');
      }
      _logError('signInWithEmail', e, StackTrace.current);
      rethrow;
    } catch (e, stackTrace) {
      _logError('signInWithEmail', e, stackTrace);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out user: ${currentUser?.uid}');
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e, stackTrace) {
      _logError('signOut', e, stackTrace);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Create user profile in SQLite
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      debugPrint('👤 Creating user profile for UID: $uid');

      final userModel = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        bio: 'Welcome to Atlas Fitness! Set your goals and start your fitness journey.',
        badges: ['newcomer'],
        createdAt: DateTime.now(),
      );

      final db = await _db.database;
      await db.insert('users', userModel.toMap());
      _db.notify('users');

      await _createDefaultFitnessData(uid);

      debugPrint('✅ User profile and default data created successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating user profile: $e');
      _logError('_createUserProfile', e, stackTrace);
      rethrow;
    }
  }

  // Create default fitness data for new users
  Future<void> _createDefaultFitnessData(String uid) async {
    try {
      debugPrint('💪 Creating default fitness data for user: $uid');

      final db = await _db.database;
      final now = DateTime.now();

      // Default body metric
      await db.insert('body_metrics', {
        'id': _uuid.v4(),
        'userId': uid,
        'metricType': 'Weight',
        'value': 70.0,
        'unit': 'kg',
        'date': now.millisecondsSinceEpoch,
      });

      // Default user stats
      await db.insert('user_stats', {
        'userId': uid,
        'totalWorkouts': 0,
        'totalMinutes': 0,
        'totalExercises': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'weeklyGoal': 3,
        'favoriteExercise': 'Not set yet',
        'lastUpdated': now.millisecondsSinceEpoch,
      });

      // Default settings
      await db.insert('user_settings', {
        'userId': uid,
        'notificationsEnabled': 1,
        'workoutReminders': 1,
        'reminderTime': '09:00',
        'preferredUnits': 'metric',
        'privateProfile': 0,
        'theme': 'system',
        'createdAt': now.millisecondsSinceEpoch,
      });

      _db.notify('body_metrics');
      _db.notify('user_stats');

      debugPrint('✅ Default fitness data created successfully');
    } catch (e, stackTrace) {
      debugPrint('⚠️ Warning: Could not create default fitness data: $e');
      _logError('_createDefaultFitnessData', e, stackTrace);
    }
  }

  // Get user profile from SQLite
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      debugPrint('📄 Fetching user profile for UID: $uid');

      final db = await _db.database;
      final rows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [uid],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        debugPrint('✅ User profile found in SQLite');
        return UserModel.fromMap(rows.first);
      }

      // Profile not found locally — create one for this auth user.
      debugPrint('⚠️ No local profile found, creating one...');
      final authUser = _auth.currentUser;
      if (authUser != null && authUser.uid == uid) {
        await _createUserProfile(
          uid: uid,
          email: authUser.email ?? '',
          displayName: authUser.displayName ?? 'User',
        );
        final newRows = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [uid],
          limit: 1,
        );
        if (newRows.isNotEmpty) return UserModel.fromMap(newRows.first);
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching user profile: $e');
      _logError('getUserProfile', e, stackTrace);
      return null;
    }
  }

  // Ensure a local SQLite profile exists after sign-in.
  Future<void> _ensureLocalProfile(User user) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [user.uid],
        limit: 1,
      );
      if (rows.isEmpty) {
        await _createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Could not ensure local profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (bio != null) updates['bio'] = bio;

    if (updates.isEmpty) return;

    final db = await _db.database;
    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [uid],
    );
    _db.notify('users');
  }
}

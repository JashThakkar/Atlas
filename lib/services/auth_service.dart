import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
      
      // Create user profile in Firestore
      if (userCredential.user != null) {
        debugPrint('👤 Creating user profile in Firestore...');
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
        debugPrint('💡 Try: Reset iOS Simulator or use a different device');
        // Provide a user-friendly error message
        throw Exception('Authentication keychain error. Please try resetting the iOS Simulator or use a different device.');
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
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'keychain-error') {
        debugPrint('🔑 Keychain error detected - this is common on iOS Simulator');
        debugPrint('💡 Try: Reset iOS Simulator or use a different device');
        // Provide a user-friendly error message
        throw Exception('Authentication keychain error. Please try resetting the iOS Simulator or use a different device.');
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
  
  // Create user profile in Firestore
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
        badges: ['newcomer'], // Give them a welcome badge
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toFirestore());
      
      // Create default fitness data for new user
      await _createDefaultFitnessData(uid);
      
      debugPrint('✅ User profile and default data created successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating user profile: $e');
      _logError('_createUserProfile', e, stackTrace);
      // Re-throw so the signup process knows it failed
      rethrow;
    }
  }
  
  // Create default fitness data for new users
  Future<void> _createDefaultFitnessData(String uid) async {
    try {
      debugPrint('💪 Creating default fitness data for user: $uid');
      
      final now = DateTime.now();
      
      // Create default body metrics
      final defaultMetrics = [
        {
          'userId': uid,
          'metricType': 'Weight',
          'value': 70.0,
          'unit': 'kg',
          'date': Timestamp.fromDate(now),
          'isDefault': true, // Flag to indicate this is placeholder data
        },
      ];
      
      // Add default metrics to Firestore
      for (final metric in defaultMetrics) {
        await _firestore
            .collection(AppConstants.bodyMetricsCollection)
            .add(metric);
      }
      
      // Create user stats document with default values
      await _firestore
          .collection('user_stats')
          .doc(uid)
          .set({
        'totalWorkouts': 0,
        'totalMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'weeklyGoal': 3, // Default goal of 3 workouts per week
        'favoriteExercise': 'Not set yet',
        'createdAt': Timestamp.fromDate(now),
        'lastUpdated': Timestamp.fromDate(now),
      });
      
      // Create default settings
      await _firestore
          .collection('user_settings')
          .doc(uid)
          .set({
        'notificationsEnabled': true,
        'workoutReminders': true,
        'reminderTime': '09:00', // Default reminder at 9 AM
        'preferredUnits': 'metric', // kg, cm
        'privateProfile': false,
        'theme': 'system',
        'createdAt': Timestamp.fromDate(now),
      });
      
      debugPrint('✅ Default fitness data created successfully');
    } catch (e, stackTrace) {
      debugPrint('⚠️ Warning: Could not create default fitness data: $e');
      _logError('_createDefaultFitnessData', e, stackTrace);
      // Don't rethrow - user creation should still succeed even if default data fails
    }
  }
  
  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 1000); // Increased delay
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('📄 Fetching user profile for UID: $uid (attempt ${attempt + 1}/$maxRetries)');
        debugPrint('🗃️ Collection: ${AppConstants.usersCollection}');
        
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();
        
        debugPrint('📋 Document exists: ${doc.exists}');
        if (doc.exists) {
          debugPrint('📊 Document data: ${doc.data()}');
          
          try {
            final userModel = UserModel.fromFirestore(doc);
            debugPrint('✅ User profile parsed successfully');
            return userModel;
          } catch (parseError) {
            debugPrint('❌ Error parsing UserModel: $parseError');
            throw parseError;
          }
        } else {
          debugPrint('⚠️ User profile document does not exist for UID: $uid');
          
          // Only try to create profile if this is not the last attempt
          if (attempt < maxRetries - 1) {
            debugPrint('🎯 Creating profile for existing user...');
            
            try {
              await _createProfileForExistingUser(uid);
              
              // Try fetching again after creating profile
              debugPrint('🔄 Retry fetching after profile creation...');
              final newDoc = await _firestore
                  .collection(AppConstants.usersCollection)
                  .doc(uid)
                  .get();
              
              if (newDoc.exists) {
                debugPrint('✅ User profile created and retrieved');
                debugPrint('📊 New document data: ${newDoc.data()}');
                return UserModel.fromFirestore(newDoc);
              }
            } catch (createError) {
              debugPrint('❌ Failed to create profile: $createError');
              // Continue to retry
            }
          }
        }
      } on FirebaseException catch (e) {
        debugPrint('🔥 FirebaseException: ${e.code} - ${e.message}');
        
        if ((e.code == 'unavailable' || e.code == 'deadline-exceeded') && attempt < maxRetries - 1) {
          // Exponential backoff for retries
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          debugPrint('🔄 Firestore ${e.code}, retrying in ${delayMs}ms (attempt ${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        
        debugPrint('❌ Error fetching user profile: ${e.code} - ${e.message}');
        
        // If it's the final attempt, return null instead of throwing
        if (attempt == maxRetries - 1) {
          debugPrint('⚠️ All retry attempts exhausted, returning null');
          return null;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error fetching user profile: $e');
        
        if (attempt == maxRetries - 1) {
          debugPrint('⚠️ All retry attempts exhausted, returning null');
          return null;
        }
        
        // Wait before retrying for non-Firebase errors
        await Future.delayed(Duration(milliseconds: baseDelay.inMilliseconds * (1 << attempt)));
      }
    }
    
    debugPrint('⚠️ Profile fetch failed after all attempts, returning null');
    return null;
  }

  // Test basic Firestore connectivity
  Future<void> _testFirestoreConnectivity() async {
    try {
      debugPrint('🧪 Testing Firestore connectivity...');
      
      // Try to read a simple test document
      final testDoc = await _firestore
          .collection('test')
          .doc('connectivity')
          .get();
      
      debugPrint('✅ Firestore connectivity test passed');
    } catch (e) {
      debugPrint('❌ Firestore connectivity test failed: $e');
      throw Exception('Cannot connect to Firestore: $e');
    }
  }
  
  // Manual test function - can be called from UI for debugging
  Future<String> testFirestoreManually() async {
    try {
      debugPrint('🧪 Manual Firestore test starting...');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'No authenticated user';
      }
      
      final uid = currentUser.uid;
      debugPrint('👤 Testing with UID: $uid');
      debugPrint('🏗️ Project ID: ${_firestore.app.options.projectId}');
      
      // Test 1: Basic Firestore connection
      debugPrint('🔗 Test 1: Testing basic Firestore connection...');
      try {
        await _firestore.settings;
        debugPrint('✅ Firestore settings accessible');
      } catch (e) {
        debugPrint('❌ Cannot access Firestore settings: $e');
        return 'FAILED: Cannot access Firestore - Check project configuration';
      }
      
      // Test 2: Try to write to a test collection (to check rules)
      debugPrint('✏️ Test 2: Testing write permissions...');
      try {
        await _firestore
            .collection('debug_test')
            .doc(uid)
            .set({
          'test': 'data',
          'timestamp': FieldValue.serverTimestamp(),
          'uid': uid,
        });
        debugPrint('✅ Write test successful');
      } catch (e) {
        debugPrint('❌ Write test failed: $e');
        return 'FAILED: Cannot write to Firestore. Check security rules or database creation. Error: $e';
      }
      
      // Test 3: Try to read the test document
      debugPrint('📖 Test 3: Testing read permissions...');
      try {
        final testDoc = await _firestore
            .collection('debug_test')
            .doc(uid)
            .get();
        
        if (testDoc.exists) {
          debugPrint('✅ Read test successful');
        } else {
          debugPrint('⚠️ Document written but not found on read');
        }
      } catch (e) {
        debugPrint('❌ Read test failed: $e');
        return 'FAILED: Cannot read from Firestore. Check security rules. Error: $e';
      }
      
      // Test 4: Check users collection specifically
      debugPrint('👥 Test 4: Testing users collection access...');
      try {
        // Try to write to users collection
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set({
          'email': currentUser.email ?? 'test@example.com',
          'displayName': currentUser.displayName ?? 'Test User',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('✅ Users collection write successful');
        
        // Try to read from users collection
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();
        
        if (userDoc.exists) {
          debugPrint('✅ Users collection read successful');
          return 'SUCCESS: All tests passed! Firestore is working correctly.';
        } else {
          return 'PARTIAL: Can write to users collection but cannot read back';
        }
        
      } catch (e) {
        debugPrint('❌ Users collection test failed: $e');
        return 'FAILED: Cannot access users collection. Error: $e';
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Manual test failed: $e');
      _logError('testFirestoreManually', e, stackTrace);
      return 'FAILED: Unexpected error: $e';
    }
  }

  // Create profile for existing authenticated user without profile
  Future<void> _createProfileForExistingUser(String uid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        debugPrint('👤 Creating profile for existing user: ${currentUser.email}');
        
        // Create minimal profile first
        final basicProfile = {
          'email': currentUser.email ?? 'user@example.com',
          'displayName': currentUser.displayName ?? 'User',
          'bio': 'Welcome to Atlas Fitness! Set your goals and start your fitness journey.',
          'currentStreak': 0,
          'longestStreak': 0,
          'badges': ['newcomer'],
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'photoUrl': null,
          'lastWorkoutDate': null,
        };
        
        debugPrint('💾 Writing basic profile to Firestore...');
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(basicProfile);
        
        debugPrint('✅ Basic profile created successfully');
        
        // Create default fitness data in background (don't await to prevent blocking)
        _createDefaultFitnessData(uid).catchError((e) {
          debugPrint('⚠️ Background task: Could not create default fitness data: $e');
        });
        
        debugPrint('✅ Profile creation completed');
      } else {
        debugPrint('❌ Current user mismatch or null');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating profile for existing user: $e');
      _logError('_createProfileForExistingUser', e, stackTrace);
      rethrow; // Re-throw so caller knows it failed
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
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
  }
}

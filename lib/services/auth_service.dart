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
    final userModel = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(userModel.toFirestore());
  }
  
  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
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

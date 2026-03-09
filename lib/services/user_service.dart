import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(userData);
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final ref = _storage.ref().child('profile_images/$userId/profile.jpg');
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'photoUrl': downloadUrl});
    return downloadUrl;
  }

  Future<bool> checkAdminStatus(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['isAdmin'] ?? false;
  }

  Future<void> awardBadge(String userId, String badgeId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }

  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}

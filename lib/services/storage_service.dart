import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload profile photo
  Future<String> uploadProfilePhoto(File photoFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage.ref().child('profilePhotos/${user.uid}/profile.jpg');
      final uploadTask = ref.putFile(photoFile);

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  // Upload profile photo with progress tracking
  UploadTask uploadProfilePhotoWithProgress(File photoFile) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final ref = _storage.ref().child('profilePhotos/${user.uid}/profile.jpg');
    return ref.putFile(photoFile);
  }

  // Upload person photo
  Future<String> uploadPersonPhoto(File photoFile, String personId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage
          .ref()
          .child('peoplePhotos/${user.uid}/$personId.jpg');
      final uploadTask = ref.putFile(photoFile);

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload person photo: $e');
    }
  }

  // Upload person photo with progress tracking
  UploadTask uploadPersonPhotoWithProgress(File photoFile, String personId) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final ref = _storage
        .ref()
        .child('peoplePhotos/${user.uid}/$personId.jpg');
    return ref.putFile(photoFile);
  }

  // Delete profile photo
  Future<void> deleteProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage.ref().child('profilePhotos/${user.uid}/profile.jpg');
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (e.toString().contains('No object found')) {
        return;
      }
      throw Exception('Failed to delete profile photo: $e');
    }
  }

  // Delete person photo
  Future<void> deletePersonPhoto(String personId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage
          .ref()
          .child('peoplePhotos/${user.uid}/$personId.jpg');
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (e.toString().contains('No object found')) {
        return;
      }
      throw Exception('Failed to delete person photo: $e');
    }
  }
}

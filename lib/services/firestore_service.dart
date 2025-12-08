import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/person_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user document exists
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // Get user data
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Create user document
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user document
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Get all people for a user
  Stream<List<PersonModel>> getPeople(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('people')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Add a person with transaction to enforce 150 limit
  Future<String> addPerson(String uid, PersonModel person) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Get current user document
        final userRef = _firestore.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document does not exist');
        }

        final userData = userDoc.data()!;
        final currentCount = (userData['peopleCount'] as int?) ?? 0;

        // Check if limit is reached
        if (currentCount >= 150) {
          throw Exception('Maximum limit of 150 people reached');
        }

        // Create person document reference
        final personRef = userRef.collection('people').doc();

        // Increment peopleCount and create person in transaction
        transaction.update(userRef, {
          'peopleCount': currentCount + 1,
        });

        transaction.set(personRef, person.toFirestore());

        return personRef.id;
      });
    } catch (e) {
      throw Exception('Failed to add person: $e');
    }
  }

  // Update a person
  Future<void> updatePerson(String uid, PersonModel person) async {
    try {
      if (person.id == null) {
        throw Exception('Person ID is required for update');
      }
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('people')
          .doc(person.id)
          .update(person.toFirestore());
    } catch (e) {
      throw Exception('Failed to update person: $e');
    }
  }

  // Delete a person with transaction to decrement count
  Future<void> deletePerson(String uid, String personId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get user document
        final userRef = _firestore.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document does not exist');
        }

        final userData = userDoc.data()!;
        final currentCount = (userData['peopleCount'] as int?) ?? 0;

        // Get person document
        final personRef = userRef.collection('people').doc(personId);
        final personDoc = await transaction.get(personRef);

        if (!personDoc.exists) {
          throw Exception('Person document does not exist');
        }

        // Decrement count and delete person in transaction
        transaction.update(userRef, {
          'peopleCount': (currentCount - 1).clamp(0, 150),
        });

        transaction.delete(personRef);
      });
    } catch (e) {
      throw Exception('Failed to delete person: $e');
    }
  }

  // Get user document stream for real-time updates
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, uid);
      }
      return null;
    });
  }
}

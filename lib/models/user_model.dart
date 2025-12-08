import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final DateTime dateOfBirth;
  final String? photoUrl;
  final int peopleCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.dateOfBirth,
    this.photoUrl,
    this.peopleCount = 0,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] as String,
      phone: data['phone'] as String,
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'] as String?,
      peopleCount: (data['peopleCount'] as int?) ?? 0,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'photoUrl': photoUrl,
      'peopleCount': peopleCount,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    String? photoUrl,
    int? peopleCount,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
      peopleCount: peopleCount ?? this.peopleCount,
    );
  }
}

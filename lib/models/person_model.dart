import 'package:cloud_firestore/cloud_firestore.dart';

class PersonModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String? photoUrl;

  PersonModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    this.photoUrl,
  });

  // Convert from Firestore document
  factory PersonModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PersonModel(
      id: id,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'photoUrl': photoUrl,
    };
  }

  // Create a copy with updated fields
  PersonModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? photoUrl,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

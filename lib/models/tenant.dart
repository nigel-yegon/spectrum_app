// lib/models/tenant.dart
class Tenant {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? nationalId;
  final String? emergencyContact;
  final String? notes;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.nationalId,
    this.emergencyContact,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'nationalId': nationalId,
      'emergencyContact': emergencyContact,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'],
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      nationalId: map['nationalId'],
      emergencyContact: map['emergencyContact'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
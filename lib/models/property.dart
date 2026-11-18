import 'unit.dart';

// lib/models/property.dart
class Property {
  final String id;
  final String name;
  final String address;
  final String? description;
  final DateTime createdAt;
  final List<Unit> units;

  Property({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    required this.createdAt,
    this.units = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Property copyWith({List<Unit>? units}) {
    return Property(
      id: id,
      name: name,
      address: address,
      description: description,
      createdAt: createdAt,
      units: units ?? this.units,
    );
  }
}
// lib/models/unit.dart
class Unit {
  final String id;
  final String propertyId;
  final String unitNumber;
  final String? description;
  final double monthlyRent;
  final int paymentDueDay; // day of month (1-31)
  final UnitStatus status;
  final String? tenantId;
  final DateTime createdAt;

  Unit({
    required this.id,
    required this.propertyId,
    required this.unitNumber,
    this.description,
    required this.monthlyRent,
    required this.paymentDueDay,
    this.status = UnitStatus.vacant,
    this.tenantId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'description': description,
      'monthlyRent': monthlyRent,
      'paymentDueDay': paymentDueDay,
      'status': status.name,
      'tenantId': tenantId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      propertyId: map['propertyId'],
      unitNumber: map['unitNumber'],
      description: map['description'],
      monthlyRent: (map['monthlyRent'] as num).toDouble(),
      paymentDueDay: map['paymentDueDay'],
      status: UnitStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UnitStatus.vacant,
      ),
      tenantId: map['tenantId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Unit copyWith({
    String? unitNumber,
    String? description,
    double? monthlyRent,
    int? paymentDueDay,
    UnitStatus? status,
    String? tenantId,
    bool clearTenant = false,
  }) {
    return Unit(
      id: id,
      propertyId: propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      description: description ?? this.description,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      status: status ?? this.status,
      tenantId: clearTenant ? null : (tenantId ?? this.tenantId),
      createdAt: createdAt,
    );
  }
}

enum UnitStatus { vacant, occupied, maintenance }

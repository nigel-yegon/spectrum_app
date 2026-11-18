// lib/services/rent_api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class RentInvoiceDto {
  final int id;
  final String unitId;
  final String unitNumber;
  final String propertyName;
  final String tenantName;
  final String tenantPhone;
  final int amount;
  final String forMonth; // YYYY-MM
  final DateTime dueDate;
  final String status; // PENDING | PAID | OVERDUE | CANCELLED
  final DateTime? paidAt;

  RentInvoiceDto({
    required this.id,
    required this.unitId,
    required this.unitNumber,
    required this.propertyName,
    required this.tenantName,
    required this.tenantPhone,
    required this.amount,
    required this.forMonth,
    required this.dueDate,
    required this.status,
    this.paidAt,
  });

  factory RentInvoiceDto.fromJson(Map<String, dynamic> j) => RentInvoiceDto(
    id: j['id'] as int,
    unitId: j['unitId'] as String,
    unitNumber: j['unitNumber'] as String,
    propertyName: j['propertyName'] as String,
    tenantName: j['tenantName'] as String,
    tenantPhone: j['tenantPhone'] as String,
    amount: j['amount'] as int,
    forMonth: j['forMonth'] as String,
    dueDate: DateTime.parse(j['dueDate'] as String),
    status: j['status'] as String,
    paidAt: j['paidAt'] != null ? DateTime.parse(j['paidAt'] as String) : null,
  );

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'PENDING' && dueDate.isBefore(DateTime.now());
  bool get isDueSoon =>
      status == 'PENDING' && !dueDate.isBefore(DateTime.now());

  /// Month as DateTime (first of month)
  DateTime get month => DateTime(
    int.parse(forMonth.split('-')[0]),
    int.parse(forMonth.split('-')[1]),
  );
}

class RentApiService {
  final http.Client _client;
  final String _baseUrl;

  RentApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.baseUrl;

  /// List invoices for a business, optionally filtered by month.
  Future<List<RentInvoiceDto>> listInvoices({
    required String businessId,
    String? month,
  }) async {
    final qp = {'businessId': businessId};
    if (month != null) qp['month'] = month;
    final uri = Uri.parse('$_baseUrl/api/rent/invoices')
        .replace(queryParameters: qp);
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('List failed (${res.statusCode}): ${res.body}');
    }
    final rows = jsonDecode(res.body) as List<dynamic>;
    return rows
        .map((r) => RentInvoiceDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Push the current units snapshot to the server so cron can invoice them.
  Future<void> syncUnits({
    required String businessId,
    required List<Map<String, dynamic>> units,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$_baseUrl/api/rent/units/sync'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'businessId': businessId, 'units': units}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Sync failed (${res.statusCode}): ${res.body}');
    }
  }
}

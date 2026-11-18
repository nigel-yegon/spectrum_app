// lib/services/mpesa_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class StkPushResult {
  final String checkoutRequestId;
  final int invoiceId;
  final String invoiceNumber;
  final String customerMessage;
  StkPushResult({
    required this.checkoutRequestId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerMessage,
  });
}

class RemotePaymentStatus {
  final String status; // PENDING | SUCCESS | FAILED | TIMEOUT
  final String? receipt;
  final String? resultCode;
  final String? resultDesc;
  final int? amount;
  RemotePaymentStatus({
    required this.status,
    this.receipt,
    this.resultCode,
    this.resultDesc,
    this.amount,
  });

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED' || status == 'TIMEOUT';
}

class MpesaApiService {
  final http.Client _client;
  final String _baseUrl;

  MpesaApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<StkPushResult> requestRent({
    required String phone, // 2547XXXXXXXX
    required int amount,
    required String tenantName,
    required String unitNumber,
    required DateTime forMonth,
  }) async {
    final ym =
        '${forMonth.year}-${forMonth.month.toString().padLeft(2, '0')}';

    final res = await _client
        .post(
      Uri.parse('$_baseUrl${AppConfig.mpesaRentPath}'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'amount': amount,
        'tenantName': tenantName,
        'unitNumber': unitNumber,
        'forMonth': ym,
      }),
    )
        .timeout(const Duration(seconds: 50));

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['checkoutRequestId'] == null) {
      throw Exception(body['error'] ?? 'STK failed (${res.statusCode})');
    }
    return StkPushResult(
      checkoutRequestId: body['checkoutRequestId'] as String,
      invoiceId: body['invoiceId'] as int,
      invoiceNumber: body['invoiceNumber'] as String,
      customerMessage: body['customerMessage'] as String? ?? 'Request sent',
    );
  }

  Future<RemotePaymentStatus> pollStatus(String checkoutRequestId) async {
    try {
      final res = await _client
          .get(Uri.parse(
          '$_baseUrl${AppConfig.mpesaStatusPath}/$checkoutRequestId'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) {
        return RemotePaymentStatus(status: 'PENDING');
      }
      if (res.statusCode != 200) {
        return RemotePaymentStatus(status: 'PENDING');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return RemotePaymentStatus(
        status: (body['status'] as String?) ?? 'PENDING',
        receipt: body['receipt'] as String?,
        resultCode: body['resultCode']?.toString(),
        resultDesc: body['resultDesc'] as String?,
        amount: body['amount'] is int ? body['amount'] as int : null,
      );
    } catch (_) {
      return RemotePaymentStatus(status: 'PENDING');
    }
  }
}
// lib/models/payment.dart
class Payment {
  final String id;
  final String unitId;
  final String tenantId;
  final double amount;
  final DateTime paymentDate;
  final DateTime forMonth;
  final PaymentMethod method;
  final String? reference;
  final String? notes;
  final PaymentStatus status;
  final DateTime createdAt;

  // M-Pesa reconciliation fields
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final int? resultCode;
  final String? failureReason;
  final String? mpesaReceipt;
  final DateTime? paidAt;

  // Server invoice link
  final int? serverInvoiceId;
  final String? serverInvoiceNumber;

  Payment({
    required this.id,
    required this.unitId,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    required this.forMonth,
    required this.method,
    this.reference,
    this.notes,
    this.status = PaymentStatus.confirmed,
    required this.createdAt,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.resultCode,
    this.failureReason,
    this.mpesaReceipt,
    this.paidAt,
    this.serverInvoiceId,
    this.serverInvoiceNumber,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'unitId': unitId,
    'tenantId': tenantId,
    'amount': amount,
    'paymentDate': paymentDate.toIso8601String(),
    'forMonth': forMonth.toIso8601String(),
    'method': method.name,
    'reference': reference,
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'checkoutRequestId': checkoutRequestId,
    'merchantRequestId': merchantRequestId,
    'resultCode': resultCode,
    'failureReason': failureReason,
    'mpesaReceipt': mpesaReceipt,
    'paidAt': paidAt?.toIso8601String(),
    'serverInvoiceId': serverInvoiceId,
    'serverInvoiceNumber': serverInvoiceNumber,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'],
    unitId: map['unitId'],
    tenantId: map['tenantId'],
    amount: (map['amount'] as num).toDouble(),
    paymentDate: DateTime.parse(map['paymentDate']),
    forMonth: DateTime.parse(map['forMonth']),
    method: PaymentMethod.values.firstWhere(
            (e) => e.name == map['method'],
        orElse: () => PaymentMethod.cash),
    reference: map['reference'],
    notes: map['notes'],
    status: PaymentStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => PaymentStatus.confirmed),
    createdAt: DateTime.parse(map['createdAt']),
    checkoutRequestId: map['checkoutRequestId'],
    merchantRequestId: map['merchantRequestId'],
    resultCode: map['resultCode'] is int ? map['resultCode'] : null,
    failureReason: map['failureReason'],
    mpesaReceipt: map['mpesaReceipt'],
    paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
    serverInvoiceId: map['serverInvoiceId'] as int?,
    serverInvoiceNumber: map['serverInvoiceNumber'] as String?,
  );

  Payment copyWith({
    PaymentStatus? status,
    String? reference,
    String? checkoutRequestId,
    String? merchantRequestId,
    int? resultCode,
    String? failureReason,
    String? mpesaReceipt,
    DateTime? paidAt,
    DateTime? paymentDate,
    int? serverInvoiceId,
    String? serverInvoiceNumber,
  }) =>
      Payment(
        id: id,
        unitId: unitId,
        tenantId: tenantId,
        amount: amount,
        paymentDate: paymentDate ?? this.paymentDate,
        forMonth: forMonth,
        method: method,
        reference: reference ?? this.reference,
        notes: notes,
        status: status ?? this.status,
        createdAt: createdAt,
        checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
        merchantRequestId: merchantRequestId ?? this.merchantRequestId,
        resultCode: resultCode ?? this.resultCode,
        failureReason: failureReason ?? this.failureReason,
        mpesaReceipt: mpesaReceipt ?? this.mpesaReceipt,
        paidAt: paidAt ?? this.paidAt,
        serverInvoiceId: serverInvoiceId ?? this.serverInvoiceId,
        serverInvoiceNumber: serverInvoiceNumber ?? this.serverInvoiceNumber,
      );
}

enum PaymentMethod { cash, mpesa, bank, cheque }
enum PaymentStatus { pending, confirmed, rejected }

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/mpesa_api_service.dart';

class AppState extends ChangeNotifier {
  // ─── Dependencies ───────────────────────────────────────

  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();
  final MpesaApiService _mpesa = MpesaApiService();

  // ─── State ──────────────────────────────────────────────

  final Map<String, Timer> _pollers = {};
  final Set<String> _activePolls = {};

  bool _disposed = false;
  bool _isLoading = false;
  bool _hasReconciledOnLaunch = false;

  List<Property> _properties = [];
  List<Unit> _units = [];
  List<Tenant> _tenants = [];
  List<Payment> _payments = [];

  List<Property> get properties => List.unmodifiable(_properties);
  List<Unit> get units => List.unmodifiable(_units);
  List<Tenant> get tenants => List.unmodifiable(_tenants);
  List<Payment> get payments => List.unmodifiable(_payments);

  bool get isLoading => _isLoading;

  // ─── Safe Notifications ─────────────────────────────────

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ─── Initial Loading ────────────────────────────────────

  Future<void> loadAll() async {
    if (_disposed || _isLoading) return;

    _isLoading = true;
    _notify();

    try {
      _properties = await _db.getProperties();
      _units = await _db.getAllUnits();
      _tenants = await _db.getTenants();
      _payments = await _db.getAllPayments();

      if (_disposed) return;

      _isLoading = false;
      _notify();

      // Reconcile only once during the initial application load.
      if (!_hasReconciledOnLaunch) {
        _hasReconciledOnLaunch = true;
        await reconcilePendingOnLaunch();
      }
    } catch (e, stackTrace) {
      _isLoading = false;
      _notify();

      debugPrint('AppState.loadAll error: $e');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  // ─── Properties ─────────────────────────────────────────

  Future<Property> addProperty({
    required String name,
    required String address,
    String? description,
  }) async {
    final property = Property(
      id: _uuid.v4(),
      name: name,
      address: address,
      description: description,
      createdAt: DateTime.now(),
    );

    await _db.insertProperty(property);

    if (_disposed) return property;

    _properties.insert(0, property);
    _notify();

    return property;
  }

  Future<void> deleteProperty(String id) async {
    await _db.deleteProperty(id);

    if (_disposed) return;

    _properties.removeWhere((p) => p.id == id);

    final removedUnitIds = _units
        .where((u) => u.propertyId == id)
        .map((u) => u.id)
        .toSet();

    _units.removeWhere((u) => u.propertyId == id);
    _payments.removeWhere((p) => removedUnitIds.contains(p.unitId));

    _notify();
  }

  // ─── Units ──────────────────────────────────────────────

  Future<Unit> addUnit({
    required String propertyId,
    required String unitNumber,
    required double monthlyRent,
    required int paymentDueDay,
    String? description,
  }) async {
    final propertyExists = _properties.any(
          (p) => p.id == propertyId,
    );

    if (!propertyExists) {
      throw Exception('Property not found.');
    }

    if (monthlyRent <= 0) {
      throw Exception('Monthly rent must be greater than zero.');
    }

    if (paymentDueDay < 1 || paymentDueDay > 31) {
      throw Exception('Payment due day must be between 1 and 31.');
    }

    final unit = Unit(
      id: _uuid.v4(),
      propertyId: propertyId,
      unitNumber: unitNumber.trim(),
      description: description,
      monthlyRent: monthlyRent,
      paymentDueDay: paymentDueDay,
      createdAt: DateTime.now(),
    );

    await _db.insertUnit(unit);

    if (_disposed) return unit;

    _units.add(unit);
    _notify();

    return unit;
  }

  Future<void> updateUnit(Unit unit) async {
    await _db.updateUnit(unit);

    if (_disposed) return;

    final idx = _units.indexWhere((u) => u.id == unit.id);

    if (idx >= 0) {
      _units[idx] = unit;
    }

    _notify();
  }

  Future<void> deleteUnit(String id) async {
    await _db.deleteUnit(id);

    if (_disposed) return;

    _units.removeWhere((u) => u.id == id);
    _payments.removeWhere((p) => p.unitId == id);

    _notify();
  }

  List<Unit> unitsForProperty(String propertyId) {
    return _units
        .where((u) => u.propertyId == propertyId)
        .toList();
  }

  // ─── Tenants ────────────────────────────────────────────

  Future<Tenant> addTenant({
    required String fullName,
    required String phoneNumber,
    String? email,
    String? nationalId,
    String? emergencyContact,
    String? notes,
  }) async {
    if (fullName.trim().isEmpty) {
      throw Exception('Tenant name is required.');
    }

    if (phoneNumber.trim().isEmpty) {
      throw Exception('Tenant phone number is required.');
    }

    final tenant = Tenant(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      email: email,
      nationalId: nationalId,
      emergencyContact: emergencyContact,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertTenant(tenant);

    if (_disposed) return tenant;

    _tenants.add(tenant);
    _notify();

    return tenant;
  }

  Tenant? getTenant(String? id) {
    if (id == null) return null;

    for (final tenant in _tenants) {
      if (tenant.id == id) return tenant;
    }

    return null;
  }

  Future<void> assignTenantToUnit(
      String unitId,
      String tenantId,
      ) async {
    final unitIndex = _units.indexWhere((u) => u.id == unitId);

    if (unitIndex == -1) {
      throw Exception('Unit not found.');
    }

    if (getTenant(tenantId) == null) {
      throw Exception('Tenant not found.');
    }

    final unit = _units[unitIndex];

    final updated = unit.copyWith(
      status: UnitStatus.occupied,
      tenantId: tenantId,
    );

    await updateUnit(updated);
  }

  Future<void> vacateUnit(String unitId) async {
    final unitIndex = _units.indexWhere((u) => u.id == unitId);

    if (unitIndex == -1) {
      throw Exception('Unit not found.');
    }

    final unit = _units[unitIndex];

    final updated = unit.copyWith(
      status: UnitStatus.vacant,
      clearTenant: true,
    );

    await updateUnit(updated);
  }

  // ─── Payments / Invoices ────────────────────────────────

  Future<Payment> addPayment({
    required String unitId,
    required String tenantId,
    required double amount,
    required DateTime paymentDate,
    required DateTime forMonth,
    required PaymentMethod method,
    String? reference,
    String? notes,
    PaymentStatus status = PaymentStatus.confirmed,
  }) async {
    if (!_units.any((u) => u.id == unitId)) {
      throw Exception('Unit not found.');
    }

    if (getTenant(tenantId) == null) {
      throw Exception('Tenant not found.');
    }

    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    final payment = Payment(
      id: _uuid.v4(),
      unitId: unitId,
      tenantId: tenantId,
      amount: amount,
      paymentDate: paymentDate,
      forMonth: forMonth,
      method: method,
      reference: reference,
      notes: notes,
      status: status,
      createdAt: DateTime.now(),
    );

    await _db.insertPayment(payment);

    if (_disposed) return payment;

    _payments.insert(0, payment);
    _notify();

    return payment;
  }

  List<Payment> paymentsForUnit(String unitId) {
    return _payments.where((p) => p.unitId == unitId).toList();
  }

  List<Payment> paymentsForTenant(String tenantId) {
    return _payments.where((p) => p.tenantId == tenantId).toList();
  }

  Future<Payment?> generateInvoice({
    required String unitId,
    required DateTime forMonth,
  }) async {
    final unitIndex = _units.indexWhere((u) => u.id == unitId);

    if (unitIndex == -1) {
      throw Exception('Unit not found.');
    }

    final unit = _units[unitIndex];

    if (unit.tenantId == null) return null;

    final exists = _payments.any(
          (p) =>
      p.unitId == unitId &&
          p.forMonth.year == forMonth.year &&
          p.forMonth.month == forMonth.month &&
          p.status != PaymentStatus.rejected,
    );

    if (exists) return null;

    final payment = Payment(
      id: _uuid.v4(),
      unitId: unitId,
      tenantId: unit.tenantId!,
      amount: unit.monthlyRent,
      paymentDate: DateTime.now(),
      forMonth: DateTime(forMonth.year, forMonth.month),
      method: PaymentMethod.mpesa,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );

    await _db.insertPayment(payment);

    if (_disposed) return payment;

    _payments.insert(0, payment);
    _notify();

    return payment;
  }

  Future<void> generateAllInvoicesForMonth(
      DateTime forMonth,
      ) async {
    final occupiedUnits = _units
        .where((u) => u.status == UnitStatus.occupied)
        .toList();

    for (final unit in occupiedUnits) {
      await generateInvoice(
        unitId: unit.id,
        forMonth: forMonth,
      );
    }
  }

  // ─── M-Pesa Phone Validation ────────────────────────────

  String _normalizeKenyanPhone(String phone) {
    var normalized = phone.replaceAll(
      RegExp(r'[\s-]+'),
      '',
    );

    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }

    if (normalized.startsWith('0')) {
      normalized = '254${normalized.substring(1)}';
    }

    if (!RegExp(r'^254[17]\d{8}$').hasMatch(normalized)) {
      throw Exception(
        'Enter a valid Kenyan mobile number, '
            'e.g. 0712345678 or 254712345678.',
      );
    }

    return normalized;
  }

  // ─── M-Pesa STK Push ────────────────────────────────────

  Future<Payment> requestMpesaPayment({
    required String paymentId,
    required String phone,
  }) async {
    final idx = _payments.indexWhere(
          (p) => p.id == paymentId,
    );

    if (idx == -1) {
      throw Exception('Payment not found.');
    }

    final payment = _payments[idx];

    if (payment.status == PaymentStatus.confirmed) {
      throw Exception('This payment has already been completed.');
    }

    if (payment.status == PaymentStatus.pending &&
        payment.checkoutRequestId != null) {
      throw Exception(
        'An M-Pesa request is already pending for this invoice. '
            'Check its status before trying again.',
      );
    }

    final normalizedPhone = _normalizeKenyanPhone(phone);

    final unitIndex = _units.indexWhere(
          (u) => u.id == payment.unitId,
    );

    if (unitIndex == -1) {
      throw Exception('The payment unit could not be found.');
    }

    final unit = _units[unitIndex];
    final tenant = getTenant(payment.tenantId);

    if (tenant == null) {
      throw Exception('The tenant associated with this payment is missing.');
    }

    if (payment.amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    final push = await _mpesa.requestRent(
      phone: normalizedPhone,
      amount: payment.amount.round(),
      tenantName: tenant.fullName,
      unitNumber: unit.unitNumber,
      forMonth: payment.forMonth,
    );

    if (_disposed) return payment;

    final updated = payment.copyWith(
      status: PaymentStatus.pending,
      checkoutRequestId: push.checkoutRequestId,
      reference: push.checkoutRequestId,
      serverInvoiceId: push.invoiceId,
      serverInvoiceNumber: push.invoiceNumber,
    );

    await _db.updatePayment(updated);

    if (_disposed) return updated;

    final updatedIndex = _payments.indexWhere(
          (p) => p.id == paymentId,
    );

    if (updatedIndex >= 0) {
      _payments[updatedIndex] = updated;
    }

    _notify();

    _startPolling(
      payment.id,
      push.checkoutRequestId,
    );

    return updated;
  }

  // ─── Payment Reconciliation ─────────────────────────────

  Future<void> reconcilePendingOnLaunch() async {
    if (_disposed) return;

    final pendingPayments = _payments
        .where(
          (p) =>
      p.status == PaymentStatus.pending &&
          p.checkoutRequestId != null,
    )
        .toList();

    for (final payment in pendingPayments) {
      if (_disposed) return;

      try {
        final result = await _mpesa.pollStatus(
          payment.checkoutRequestId!,
        );

        if (_disposed) return;

        if (result.isSuccess) {
          await _applyReconciledSuccess(payment, result);
        } else if (result.isFailed) {
          await _applyReconciledFailure(payment, result);
        }
      } catch (e) {
        debugPrint(
          'Payment reconciliation error '
              '(${payment.id}): $e',
        );
      }
    }
  }

  Future<void> _applyReconciledSuccess(
      Payment payment,
      RemotePaymentStatus result,
      ) async {
    if (_disposed) return;

    final idx = _payments.indexWhere(
          (p) => p.id == payment.id,
    );

    if (idx == -1) return;

    final current = _payments[idx];

    if (current.status != PaymentStatus.pending) return;

    final confirmed = current.copyWith(
      status: PaymentStatus.confirmed,
      mpesaReceipt: result.receipt,
      paidAt: DateTime.now(),
      paymentDate: DateTime.now(),
      resultCode: int.tryParse(result.resultCode ?? ''),
    );

    await _db.updatePayment(confirmed);

    if (_disposed) return;

    _payments[idx] = confirmed;
    _notify();
  }

  Future<void> _applyReconciledFailure(
      Payment payment,
      RemotePaymentStatus result,
      ) async {
    if (_disposed) return;

    final idx = _payments.indexWhere(
          (p) => p.id == payment.id,
    );

    if (idx == -1) return;

    final current = _payments[idx];

    if (current.status != PaymentStatus.pending) return;

    final failed = current.copyWith(
      status: PaymentStatus.rejected,
      resultCode: int.tryParse(result.resultCode ?? ''),
      failureReason: result.resultDesc ?? 'Payment failed',
    );

    await _db.updatePayment(failed);

    if (_disposed) return;

    _payments[idx] = failed;
    _notify();
  }

  // ─── Automatic M-Pesa Polling ───────────────────────────

  void _startPolling(
      String paymentId,
      String checkoutRequestId,
      ) {
    _pollers[checkoutRequestId]?.cancel();

    final startedAt = DateTime.now();
    const maxWait = Duration(seconds: 120);

    _pollers[checkoutRequestId] = Timer.periodic(
      const Duration(seconds: 3),
          (timer) async {
        if (_disposed) {
          timer.cancel();
          _pollers.remove(checkoutRequestId);
          return;
        }

        if (!_activePolls.add(checkoutRequestId)) {
          return;
        }

        try {
          final idx = _payments.indexWhere(
                (p) => p.id == paymentId,
          );

          if (idx == -1) {
            timer.cancel();
            _pollers.remove(checkoutRequestId);
            return;
          }

          final payment = _payments[idx];

          if (payment.status != PaymentStatus.pending) {
            timer.cancel();
            _pollers.remove(checkoutRequestId);
            return;
          }

          final result = await _mpesa.pollStatus(
            checkoutRequestId,
          );

          if (_disposed) {
            timer.cancel();
            return;
          }

          if (result.isSuccess) {
            await _applyReconciledSuccess(payment, result);

            timer.cancel();
            _pollers.remove(checkoutRequestId);
          } else if (result.isFailed) {
            await _applyReconciledFailure(payment, result);

            timer.cancel();
            _pollers.remove(checkoutRequestId);
          } else if (
          DateTime.now().difference(startedAt) >= maxWait
          ) {
            // A timeout is not proof of payment failure.
            // Keep the payment pending for later reconciliation.
            timer.cancel();
            _pollers.remove(checkoutRequestId);
            _notify();
          }
        } catch (e, stackTrace) {
          debugPrint('M-Pesa polling error: $e');
          debugPrintStack(stackTrace: stackTrace);
        } finally {
          _activePolls.remove(checkoutRequestId);
        }
      },
    );
  }

  // ─── Manual Payment Refresh ─────────────────────────────

  Future<void> refreshPendingPayment(
      String paymentId,
      ) async {
    if (_disposed) return;

    final idx = _payments.indexWhere(
          (p) => p.id == paymentId,
    );

    if (idx == -1) return;

    final payment = _payments[idx];

    if (payment.status != PaymentStatus.pending ||
        payment.checkoutRequestId == null) {
      return;
    }

    final checkoutId = payment.checkoutRequestId!;

    if (!_activePolls.add(checkoutId)) return;

    try {
      final result = await _mpesa.pollStatus(checkoutId);

      if (_disposed) return;

      if (result.isSuccess) {
        await _applyReconciledSuccess(payment, result);
      } else if (result.isFailed) {
        await _applyReconciledFailure(payment, result);
      }
    } catch (e) {
      debugPrint('Manual M-Pesa refresh error: $e');
      rethrow;
    } finally {
      _activePolls.remove(checkoutId);
    }
  }

  // ─── Statistics ─────────────────────────────────────────

  double get totalMonthlyExpectedRent {
    return _units
        .where((u) => u.status == UnitStatus.occupied)
        .fold(0, (sum, u) => sum + u.monthlyRent);
  }

  double get totalCollectedThisMonth {
    final now = DateTime.now();

    return _payments
        .where(
          (p) =>
      p.status == PaymentStatus.confirmed &&
          p.paymentDate.year == now.year &&
          p.paymentDate.month == now.month,
    )
        .fold(0, (sum, p) => sum + p.amount);
  }

  int get occupiedCount {
    return _units
        .where((u) => u.status == UnitStatus.occupied)
        .length;
  }

  int get vacantCount {
    return _units
        .where((u) => u.status == UnitStatus.vacant)
        .length;
  }

  int get pendingReconciliationCount {
    return _payments
        .where(
          (p) =>
      p.status == PaymentStatus.pending &&
          p.checkoutRequestId != null,
    )
        .length;
  }

  // ─── Backup ─────────────────────────────────────────────

  Future<Map<String, dynamic>> exportBackup() {
    return _db.exportAll();
  }

  Future<void> restoreBackup(
      Map<String, dynamic> data,
      ) async {
    if (_disposed) return;

    // Stop polling before replacing local payment records.
    for (final timer in _pollers.values) {
      timer.cancel();
    }

    _pollers.clear();
    _activePolls.clear();

    await _db.importAll(data);

    if (_disposed) return;

    _hasReconciledOnLaunch = false;

    await loadAll();
  }

  // ─── Disposal ───────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;

    for (final timer in _pollers.values) {
      timer.cancel();
    }

    _pollers.clear();
    _activePolls.clear();

    super.dispose();
  }
}

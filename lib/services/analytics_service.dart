
import 'package:intl/intl.dart';

import '../models/payment.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';

class AnalyticsService {
  final List<Property> properties;
  final List<Unit> units;
  final List<Tenant> tenants;
  final List<Payment> payments;

  AnalyticsService({
    required this.properties,
    required this.units,
    required this.tenants,
    required this.payments,
  });

  List<Payment> get confirmedPayments => payments
      .where((p) => p.status == PaymentStatus.confirmed)
      .toList();

  double get totalCollected => confirmedPayments.fold(
    0,
        (total, payment) => total + payment.amount,
  );

  double get expectedMonthlyRent => units
      .where((u) => u.status == UnitStatus.occupied)
      .fold(0, (total, unit) => total + unit.monthlyRent);

  int get occupiedUnits =>
      units.where((u) => u.status == UnitStatus.occupied).length;

  int get vacantUnits =>
      units.where((u) => u.status == UnitStatus.vacant).length;

  int get maintenanceUnits =>
      units.where((u) => u.status == UnitStatus.maintenance).length;

  double get occupancyRate =>
      units.isEmpty ? 0 : occupiedUnits / units.length * 100;

  double get collectionRate {
    if (expectedMonthlyRent <= 0) return 0;

    final now = DateTime.now();
    final collectedThisMonth = confirmedPayments
        .where((p) =>
    p.paymentDate.year == now.year &&
        p.paymentDate.month == now.month)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return (collectedThisMonth / expectedMonthlyRent * 100)
        .clamp(0, 100);
  }

  double collectedInMonth(DateTime month) {
    return confirmedPayments
        .where((p) =>
    p.paymentDate.year == month.year &&
        p.paymentDate.month == month.month)
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  double expectedForMonth(DateTime month) {
    // Uses the current occupied-unit portfolio as the estimate.
    // Historical occupancy is not stored in the current schema.
    return expectedMonthlyRent;
  }

  List<MonthlyMetric> get monthlyIncome {
    final now = DateTime.now();

    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index), 1);

      return MonthlyMetric(
        month: month,
        income: collectedInMonth(month),
      );
    });
  }

  Map<PaymentMethod, double> get incomeByMethod {
    final result = <PaymentMethod, double>{};

    for (final method in PaymentMethod.values) {
      result[method] = confirmedPayments
          .where((p) => p.method == method)
          .fold<double>(0, (sum, p) => sum + p.amount);
    }

    return result;
  }

  Map<String, double> get incomeByProperty {
    final result = <String, double>{};

    for (final property in properties) {
      final propertyUnitIds = units
          .where((u) => u.propertyId == property.id)
          .map((u) => u.id)
          .toSet();

      result[property.name] = confirmedPayments
          .where((p) => propertyUnitIds.contains(p.unitId))
          .fold<double>(0, (sum, p) => sum + p.amount);
    }

    return result;
  }

  String get currentMonthLabel =>
      DateFormat('MMMM yyyy').format(DateTime.now());
}

class MonthlyMetric {
  final DateTime month;
  final double income;

  const MonthlyMetric({
    required this.month,
    required this.income,
  });

  String get label => DateFormat('MMM').format(month);
}

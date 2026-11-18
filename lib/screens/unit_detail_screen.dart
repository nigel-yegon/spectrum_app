// lib/screens/unit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/payment.dart';
import '../widgets/assign_tenant_sheet.dart';
import '../widgets/invoice_payment_sheet.dart';

class UnitDetailScreen extends StatelessWidget {
  final String unitId;
  const UnitDetailScreen({super.key, required this.unitId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final unit = state.units.firstWhere((u) => u.id == unitId);
    final tenant = state.getTenant(unit.tenantId);
    final allPayments = state.paymentsForUnit(unitId);
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final df = DateFormat('MMM d, yyyy');

    // Separate invoices: pending vs confirmed history
    final pending = allPayments
        .where((p) => p.status == PaymentStatus.pending)
        .toList();
    final history = allPayments
        .where((p) => p.status == PaymentStatus.confirmed)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Unit ${unit.unitNumber}')),
      floatingActionButton: tenant != null
          ? FloatingActionButton.extended(
        onPressed: () => _openCurrentInvoice(context, state),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Request Rent'),
      )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unit details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Monthly Rent', currency.format(unit.monthlyRent)),
                  const Divider(),
                  _row('Payment Due',
                      'Day ${unit.paymentDueDay} each month'),
                  const Divider(),
                  _row('Status', unit.status.name.toUpperCase()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tenant card
          const Text('Tenant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: tenant == null
                ? ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('No tenant assigned'),
              trailing: FilledButton.tonal(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => AssignTenantSheet(unitId: unitId),
                ),
                child: const Text('Assign'),
              ),
            )
                : ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.person, color: Colors.green),
              ),
              title: Text(tenant.fullName,
                  style:
                  const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${tenant.phoneNumber}'
                  '${tenant.email != null ? '\n${tenant.email}' : ''}'),
              isThreeLine: tenant.email != null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'vacate') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Vacate unit?'),
                        content: const Text(
                            'Tenant will be unlinked from this unit.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Vacate')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await state.vacateUnit(unitId);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'vacate', child: Text('Vacate Unit')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pending invoices (awaiting payment)
          if (pending.isNotEmpty) ...[
            const Text('Pending Invoices',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...pending.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: const Icon(Icons.hourglass_bottom,
                      color: Colors.orange),
                ),
                title: Text(currency.format(p.amount),
                    style:
                    const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'For ${DateFormat('MMMM yyyy').format(p.forMonth)}'
                        '${p.checkoutRequestId != null ? ' • Awaiting M-Pesa' : ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => InvoicePaymentSheet(
                      unitId: unitId, payment: p),
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Payment history
          const Text('Payment History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No confirmed payments yet',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
            )
          else
            ...history.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child:
                  const Icon(Icons.check, color: Colors.green),
                ),
                title: Text(currency.format(p.amount),
                    style:
                    const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Paid ${df.format(p.paymentDate)} • For ${DateFormat('MMMM yyyy').format(p.forMonth)}'),
                trailing: Chip(
                  label: Text(p.method.name.toUpperCase(),
                      style: const TextStyle(fontSize: 11)),
                ),
              ),
            )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Opens (or creates) the invoice for the current month, then shows
  /// the STK Push sheet for it.
  Future<void> _openCurrentInvoice(
      BuildContext context, AppState state) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    // Look for existing invoice for this month
    Payment? invoice;
    for (final p in state.payments) {
      if (p.unitId == unitId &&
          p.forMonth.year == month.year &&
          p.forMonth.month == month.month &&
          p.status != PaymentStatus.rejected) {
        invoice = p;
        break;
      }
    }

    // Otherwise generate one
    invoice ??= await state.generateInvoice(unitId: unitId, forMonth: month);

    if (invoice == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('Cannot generate invoice — assign a tenant first')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          InvoicePaymentSheet(unitId: unitId, payment: invoice!),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
// lib/screens/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final payments = state.payments;
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final df = DateFormat('MMM d, yyyy');
    final total = payments.fold<double>(0, (s, p) => s + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Collected',
                      style: TextStyle(
                          fontSize: 13, color: Colors.green.shade800)),
                  const SizedBox(height: 4),
                  Text(currency.format(total),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade900)),
                  const SizedBox(height: 4),
                  Text('${payments.length} payment(s)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recent Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No payments yet',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
            )
          else
            ...payments.map((p) {
              final tenant = state.getTenant(p.tenantId);
              final unit = state.units.firstWhere((u) => u.id == p.unitId,
                  orElse: () => state.units.first);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(currency.format(p.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${tenant?.fullName ?? 'Unknown'} • Unit ${unit.unitNumber}\n'
                          '${df.format(p.paymentDate)} • ${p.method.name.toUpperCase()}'
                          '${p.reference != null ? ' • ${p.reference}' : ''}'),
                  isThreeLine: true,
                  trailing: Text(DateFormat('MMM yyyy').format(p.forMonth),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
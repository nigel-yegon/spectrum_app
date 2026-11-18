// lib/screens/tenants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';


class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTenant(context),
        child: const Icon(Icons.add),
      ),
      body: state.tenants.isEmpty
          ? Center(
          child: Text('No tenants yet',
              style: TextStyle(color: Colors.grey.shade600)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tenants.length,
        itemBuilder: (context, i) {
          final t = state.tenants[i];
          final payments = state.paymentsForTenant(t.id);
          final totalPaid =
          payments.fold<double>(0, (s, p) => s + p.amount);
          final currency =
          NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: Text(
                  t.fullName.isNotEmpty
                      ? t.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.indigo, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(t.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(t.phoneNumber),
                  if (payments.isNotEmpty)
                    Text('Lifetime paid: ${currency.format(totalPaid)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700)),
                ],
              ),
              isThreeLine: payments.isNotEmpty,
            ),
          );
        },
      ),
    );
  }

  void _showAddTenant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddTenantSheet(),
    );
  }
}

class _AddTenantSheet extends StatefulWidget {
  const _AddTenantSheet();

  @override
  State<_AddTenantSheet> createState() => _AddTenantSheetState();
}

class _AddTenantSheetState extends State<_AddTenantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _ecCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _ecCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Tenant',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+254...',
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idCtrl,
                decoration: const InputDecoration(
                    labelText: 'National ID (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ecCtrl,
                decoration: const InputDecoration(
                    labelText: 'Emergency Contact (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await context.read<AppState>().addTenant(
                      fullName: _nameCtrl.text.trim(),
                      phoneNumber: _phoneCtrl.text.trim(),
                      email: _emailCtrl.text.trim().isEmpty
                          ? null
                          : _emailCtrl.text.trim(),
                      nationalId: _idCtrl.text.trim().isEmpty
                          ? null
                          : _idCtrl.text.trim(),
                      emergencyContact: _ecCtrl.text.trim().isEmpty
                          ? null
                          : _ecCtrl.text.trim(),
                      notes: _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save Tenant'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
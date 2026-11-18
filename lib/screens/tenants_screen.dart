// lib/screens/tenants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';

const Color _primaryGreen = Color(0xFF1E3A2F);
const Color _bgCream = Color(0xFFF9F9F6);

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(title: const Text('Tenants')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTenant(context),
        child: const Icon(Icons.add),
      ),
      body: state.tenants.isEmpty
          ? Center(
        child: Text(
          'No tenants yet',
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
      )
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

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    t.fullName.isNotEmpty
                        ? t.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: _primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              title: Text(
                t.fullName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    t.phoneNumber,
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (payments.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lifetime paid: ${currency.format(totalPaid)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF2E7D5E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
    return Container(
      color: _bgCream,
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
              Text(
                'Add Tenant',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _buildTextField(_nameCtrl, 'Full Name', required: true),
              const SizedBox(height: 12),
              _buildTextField(_phoneCtrl, 'Phone Number',
                  hint: '0712 345 678',
                  keyboard: TextInputType.phone,
                  required: true),
              const SizedBox(height: 12),
              _buildTextField(_emailCtrl, 'Email (optional)',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(_idCtrl, 'National ID (optional)'),
              const SizedBox(height: 12),
              _buildTextField(_ecCtrl, 'Emergency Contact (optional)'),
              const SizedBox(height: 12),
              _buildTextField(_notesCtrl, 'Notes (optional)', maxLines: 2),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
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
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(
                  'Save Tenant',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool required = false,
        String? hint,
        TextInputType? keyboard,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }
}
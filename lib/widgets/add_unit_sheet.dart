// lib/widgets/add_unit_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class AddUnitSheet extends StatefulWidget {
  final String propertyId;
  const AddUnitSheet({super.key, required this.propertyId});

  @override
  State<AddUnitSheet> createState() => _AddUnitSheetState();
}

class _AddUnitSheetState extends State<AddUnitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _dueDay = 5;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _rentCtrl.dispose();
    _descCtrl.dispose();
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
              const Text(
                'Add Unit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Rent',
                  prefixText: 'KSh ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration: const InputDecoration(
                  labelText: 'Rent Due Day',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(28, (i) => i + 1)
                    .map(
                      (d) => DropdownMenuItem(value: d, child: Text('Day $d')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _dueDay = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await context.read<AppState>().addUnit(
                      propertyId: widget.propertyId,
                      unitNumber: _numberCtrl.text.trim(),
                      monthlyRent: double.parse(_rentCtrl.text),
                      paymentDueDay: _dueDay,
                      description: _descCtrl.text.trim().isEmpty
                          ? null
                          : _descCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save Unit'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

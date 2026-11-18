// lib/widgets/assign_tenant_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class AssignTenantSheet extends StatelessWidget {
  final String unitId;
  const AssignTenantSheet({super.key, required this.unitId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Assign Tenant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            if (state.tenants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No tenants yet. Add one in the Tenants tab.'),
                ),
              )
            else
              ...state.tenants.map((t) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(t.fullName),
                    subtitle: Text(t.phoneNumber),
                    onTap: () async {
                      await state.assignTenantToUnit(unitId, t.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

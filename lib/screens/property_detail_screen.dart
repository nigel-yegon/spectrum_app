// lib/screens/property_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../widgets/add_unit_sheet.dart';
import 'unit_detail_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final units = state.unitsForProperty(property.id);
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Property?'),
                  content: const Text('This will remove all units too.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await state.deleteProperty(property.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => AddUnitSheet(propertyId: property.id),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(property.address)),
                    ],
                  ),
                  if (property.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      property.description!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(label: Text('${units.length} Units')),
                      Chip(
                        label: Text(
                          '${units.where((u) => u.status == UnitStatus.occupied).length} Occupied',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Units',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No units yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...units.map((u) {
              final tenant = state.getTenant(u.tenantId);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(u.status)
                        .withValues(alpha: 0.1),
                    child: Icon(
                      Icons.meeting_room,
                      color: _statusColor(u.status),
                    ),
                  ),
                  title: Text(
                    'Unit ${u.unitNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Rent: ${currency.format(u.monthlyRent)} • Due: ${u.paymentDueDay}${_suffix(u.paymentDueDay)}',
                      ),
                      if (tenant != null)
                        Text('Tenant: ${tenant.fullName}')
                      else
                        Text(
                          'Vacant',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnitDetailScreen(unitId: u.id),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _statusColor(UnitStatus s) {
    switch (s) {
      case UnitStatus.occupied:
        return Colors.green;
      case UnitStatus.vacant:
        return Colors.orange;
      case UnitStatus.maintenance:
        return Colors.red;
    }
  }

  String _suffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

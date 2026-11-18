// lib/screens/properties_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'property_detail_screen.dart';
import '../widgets/add_property_sheet.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const AddPropertySheet(),
        ),
        child: const Icon(Icons.add),
      ),
      body: state.properties.isEmpty
          ? Center(
        child: Text('No properties yet',
            style: TextStyle(color: Colors.grey.shade600)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.properties.length,
        itemBuilder: (context, i) {
          final p = state.properties[i];
          final units = state.unitsForProperty(p.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: const Icon(Icons.apartment, color: Colors.indigo),
              ),
              title: Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.address}\n${units.length} units'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(property: p))),
            ),
          );
        },
      ),
    );
  }
}
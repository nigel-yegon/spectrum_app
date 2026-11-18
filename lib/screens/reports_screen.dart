
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payment.dart';
import '../providers/app_state.dart';
import '../services/report_service.dart';

const _reportGreen = Color(0xFF1E3A2F);
const _reportCream = Color(0xFFF9F9F6);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();

  PaymentStatus? _status;
  String _sort = 'Newest first';
  DateTimeRange? _dateRange;
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(num amount) =>
      NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2)
          .format(amount);

  Future<void> _chooseDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: _dateRange,
    );

    if (selected != null) {
      setState(() => _dateRange = selected);
    }
  }

  Future<void> _export(AppState state, List<Payment> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no records to export.')),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      await ReportService.exportPayments(
        payments: records,
        properties: state.properties,
        units: state.units,
        tenants: state.tenants,
        title: 'Payment Transactions Report',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create report: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  List<Payment> _filter(AppState state) {
    final query = _searchController.text.trim().toLowerCase();

    final records = state.payments.where((payment) {
      if (_status != null && payment.status != _status) return false;

      if (_dateRange != null) {
        final date = payment.paymentDate;
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );

        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      if (query.isEmpty) return true;

      final tenant = state.getTenant(payment.tenantId);
      final unit = state.units.where((u) => u.id == payment.unitId);
      final unitNumber = unit.isEmpty ? '' : unit.first.unitNumber;
      final property = unit.isEmpty
          ? null
          : state.properties.where((p) => p.id == unit.first.propertyId);
      final propertyName =
      property == null || property.isEmpty ? '' : property.first.name;

      final searchable = [
        tenant?.fullName ?? '',
        tenant?.phoneNumber ?? '',
        unitNumber,
        propertyName,
        payment.reference ?? '',
        payment.mpesaReceipt ?? '',
        payment.method.name,
        payment.status.name,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();

    switch (_sort) {
      case 'Oldest first':
        records.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
        break;
      case 'Highest amount':
        records.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest amount':
        records.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        records.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    }

    return records;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = _filter(state);
    final confirmedTotal = records
        .where((p) => p.status == PaymentStatus.confirmed)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: _reportCream,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: _reportCream,
        foregroundColor: _reportGreen,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Export filtered report to PDF',
            onPressed: _exporting ? null : () => _export(state, records),
            icon: _exporting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _reportGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment report',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  _money(confirmedTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${records.length} matching records • confirmed income only',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search tenant, property, unit or reference',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PaymentStatus?>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<PaymentStatus?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    DropdownMenuItem(
                      value: PaymentStatus.confirmed,
                      child: Text('Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: PaymentStatus.pending,
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: PaymentStatus.rejected,
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sort,
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Newest first',
                      child: Text('Newest first'),
                    ),
                    DropdownMenuItem(
                      value: 'Oldest first',
                      child: Text('Oldest first'),
                    ),
                    DropdownMenuItem(
                      value: 'Highest amount',
                      child: Text('Highest amount'),
                    ),
                    DropdownMenuItem(
                      value: 'Lowest amount',
                      child: Text('Lowest amount'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _chooseDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              _dateRange == null
                  ? 'Filter by date range'
                  : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)}'
                  ' – ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
            ),
          ),
          if (_dateRange != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _dateRange = null),
                child: const Text('Clear date filter'),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _reportGreen,
                ),
              ),
              Text(
                '${records.length} records',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.description_outlined,
                      size: 42, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No matching transactions'),
                  SizedBox(height: 4),
                  Text(
                    'Try changing your search or filters.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...records.map((payment) {
              final tenant = state.getTenant(payment.tenantId);
              final unit = state.units.where((u) => u.id == payment.unitId);
              final unitLabel =
              unit.isEmpty ? 'Unknown unit' : 'Unit ${unit.first.unitNumber}';

              final statusColor = switch (payment.status) {
                PaymentStatus.confirmed => Colors.green,
                PaymentStatus.pending => Colors.orange,
                PaymentStatus.rejected => Colors.red,
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    tenant?.fullName ?? 'Unknown tenant',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '$unitLabel • ${DateFormat('dd MMM yyyy').format(payment.paymentDate)}'
                        '\n${payment.method.name.toUpperCase()}'
                        ' • ${payment.status.name.toUpperCase()}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(payment.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _reportGreen,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment.status.name,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _exporting ? null : () => _export(state, records),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(
              _exporting ? 'Preparing PDF...' : 'Export filtered results to PDF',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _reportGreen,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

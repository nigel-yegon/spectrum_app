import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_state.dart';
import '../models/payment.dart';

const Color _primaryGreen = Color(0xFF1E3A2F);
const Color _bgCream = Color(0xFFF9F9F6);
const Color _textGrey = Color(0xFF7A7A7A);

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _searchQuery = '';
  PaymentStatus? _filterStatus;
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final df = DateFormat('MMM d, yyyy • HH:mm');

    // Filter and Search Logic
    final filteredPayments = state.payments.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.reference?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (p.mpesaReceipt?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesFilter = _filterStatus == null || p.status == _filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();

    final totalCollected = filteredPayments
        .where((p) => p.status == PaymentStatus.confirmed)
        .fold<double>(0, (s, p) => s + p.amount);

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        title: const Text('Payments'),
      ),
      body: Column(
        children: [
          // ─── Summary & Search Header ──────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: _bgCream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Collected (Filtered)',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(totalCollected),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by receipt, ref, or ID...',
                    hintStyle: GoogleFonts.inter(color: _textGrey),
                    prefixIcon: const Icon(Icons.search, color: _textGrey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Confirmed', PaymentStatus.confirmed),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', PaymentStatus.pending),
                      const SizedBox(width: 8),
                      _buildFilterChip('Failed', PaymentStatus.rejected),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Payment List ─────────────────────────────────────
          Expanded(
            child: filteredPayments.isEmpty
                ? Center(
              child: Text(
                'No payments found',
                style: GoogleFonts.inter(color: _textGrey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filteredPayments.length,
              itemBuilder: (context, i) {
                final p = filteredPayments[i];
                final unit = state.units.firstWhere((u) => u.id == p.unitId,
                    orElse: () => state.units.first);
                final tenant = state.getTenant(p.tenantId);
                final isExpanded = _expandedIds.contains(p.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Collapsed Header (Always visible)
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedIds.remove(p.id);
                            } else {
                              _expandedIds.add(p.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: p.status == PaymentStatus.confirmed
                                      ? const Color(0xFFE8F0EA)
                                      : p.status == PaymentStatus.pending
                                      ? Colors.orange.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  p.status == PaymentStatus.confirmed
                                      ? Icons.check_rounded
                                      : p.status == PaymentStatus.pending
                                      ? Icons.hourglass_bottom_rounded
                                      : Icons.close_rounded,
                                  color: p.status == PaymentStatus.confirmed
                                      ? const Color(0xFF2E7D5E)
                                      : p.status == PaymentStatus.pending
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currency.format(p.amount),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tenant?.fullName ?? 'Unknown'} • Unit ${unit.unitNumber}',
                                      style: GoogleFonts.inter(
                                        color: _textGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: _textGrey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded Details
                      if (isExpanded)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              // M-Pesa Receipt (Highlighted if exists)
                              if (p.mpesaReceipt != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.receipt_long,
                                          color: Color(0xFF2E7D5E), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'M-Pesa Receipt',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: _textGrey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SelectableText(
                                              p.mpesaReceipt!,
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _primaryGreen,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              _buildDetailRow('For Month', DateFormat('MMMM yyyy').format(p.forMonth)),
                              _buildDetailRow('Method', p.method.name.toUpperCase()),
                              if (p.reference != null)
                                _buildDetailRow('Reference', p.reference!),
                              if (p.paidAt != null)
                                _buildDetailRow('Paid At', df.format(p.paidAt!)),
                              if (p.failureReason != null)
                                _buildDetailRow('Failure', p.failureReason!, isError: true),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PaymentStatus? status) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : _primaryGreen,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = status),
      backgroundColor: Colors.white,
      selectedColor: _primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _primaryGreen : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: _textGrey),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isError ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
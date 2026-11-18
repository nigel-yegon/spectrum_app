// lib/widgets/invoice_payment_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/payment.dart';

class InvoicePaymentSheet extends StatefulWidget {
  final String unitId;
  final Payment payment;
  const InvoicePaymentSheet({
    super.key,
    required this.unitId,
    required this.payment,
  });

  @override
  State<InvoicePaymentSheet> createState() => _InvoicePaymentSheetState();
}

class _InvoicePaymentSheetState extends State<InvoicePaymentSheet> {
  late Payment _current;
  bool _sending = false;
  String? _error;
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _current = widget.payment;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Re-read from state so polling updates rebuild this sheet.
    final live = state.payments.firstWhere(
          (p) => p.id == _current.id,
      orElse: () => _current,
    );
    _current = live;

    final tenant = state.getTenant(_current.tenantId);
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final df = DateFormat('MMM d, yyyy HH:mm');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Rent Invoice',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              _statusChip(_current.status),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Tenant', tenant?.fullName ?? '—'),
                  _kv('Phone', tenant?.phoneNumber ?? '—'),
                  _kv('Period',
                      DateFormat('MMMM yyyy').format(_current.forMonth)),
                  _kv('Amount', currency.format(_current.amount)),
                  if (_current.mpesaReceipt != null)
                    _kv('Receipt', _current.mpesaReceipt!),
                  if (_current.paidAt != null)
                    _kv('Paid at', df.format(_current.paidAt!)),
                  if (_current.failureReason != null)
                    _kv('Reason', _current.failureReason!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_current.status == PaymentStatus.pending) ...[
            if (_current.checkoutRequestId == null) ...[
              // No STK sent yet — collect phone and send
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Tenant phone (M-Pesa)',
                  hintText: tenant?.phoneNumber ?? '2547XXXXXXXX',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Sending…' : 'Send STK Push'),
              ),
            ] else ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Waiting for payment confirmation. Ask the tenant to check their phone.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => state.refreshPendingPayment(_current.id),
                icon: const Icon(Icons.refresh),
                label: const Text('Check status now'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ],
          ] else if (_current.status == PaymentStatus.confirmed) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Center(child: Text('Payment confirmed')),
          ] else ...[
            const Icon(Icons.cancel, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Center(child: Text('Payment rejected')),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final phone = _phoneCtrl.text.trim().isEmpty
        ? (context.read<AppState>().getTenant(_current.tenantId)?.phoneNumber ??
        '')
        : _phoneCtrl.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context
          .read<AppState>()
          .requestMpesaPayment(paymentId: _current.id, phone: phone);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _statusChip(PaymentStatus s) {
    final (label, color) = switch (s) {
      PaymentStatus.pending => ('PENDING', Colors.orange),
      PaymentStatus.confirmed => ('PAID', Colors.green),
      PaymentStatus.rejected => ('FAILED', Colors.red),
    };
    return Chip(
      label: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(color: Colors.grey.shade600)),
        Flexible(
            child: Text(v,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right)),
      ],
    ),
  );
}
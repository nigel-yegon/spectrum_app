
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/payment.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';

class ReportService {
  static Future<void> exportPayments({
    required List<Payment> payments,
    required List<Property> properties,
    required List<Unit> units,
    required List<Tenant> tenants,
    required String title,
  }) async {
    final pdf = pw.Document();
    final currency =
    NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    final unitMap = {for (final unit in units) unit.id: unit};
    final tenantMap = {for (final tenant in tenants) tenant.id: tenant};
    final propertyMap = {for (final property in properties) property.id: property};

    final confirmed = payments
        .where((p) => p.status == PaymentStatus.confirmed)
        .fold<double>(0, (sum, p) => sum + p.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'SPECTRUM',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A2F'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(title, style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColor.fromHex('#E8F0EA'),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Records: ${payments.length}'),
                pw.Text('Confirmed income: ${currency.format(confirmed)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Tenant',
              'Property',
              'Unit',
              'For month',
              'Method',
              'Status',
              'Amount',
              'Reference',
            ],
            data: payments.map((p) {
              final unit = unitMap[p.unitId];
              final tenant = tenantMap[p.tenantId];
              final property = unit == null
                  ? null
                  : propertyMap[unit.propertyId];

              return [
                dateFormat.format(p.paymentDate),
                tenant?.fullName ?? 'Unknown',
                property?.name ?? 'Unknown',
                unit?.unitNumber ?? 'Unknown',
                DateFormat('MMM yyyy').format(p.forMonth),
                p.method.name.toUpperCase(),
                p.status.name.toUpperCase(),
                currency.format(p.amount),
                p.mpesaReceipt ?? p.reference ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1E3A2F'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.4,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Confirmed income: ${currency.format(confirmed)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This report includes payment records matching the selected filters. '
                'Only confirmed payments are included in confirmed income.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'spectrum-payment-report.pdf',
    );
  }
}

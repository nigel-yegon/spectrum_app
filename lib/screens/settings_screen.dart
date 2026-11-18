import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../providers/app_state.dart';
import '../services/backup_service.dart' show BackupService;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Summary ──────────────────────────────────

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _kv('Properties', '${state.properties.length}'),
                  _kv('Units', '${state.units.length}'),
                  _kv('Tenants', '${state.tenants.length}'),
                  _kv('Payments', '${state.payments.length}'),
                  _kv(
                    'Total Rent Expected / Mo',
                    currency.format(state.totalMonthlyExpectedRent),
                  ),
                  _kv(
                    'Pending M-Pesa Reconciliation',
                    '${state.pendingReconciliationCount}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Backup and Restore ────────────────────────
          const Text(
            'Backup & Restore',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Upload Backup to VPS'),
                  subtitle: const Text(
                    'Push the local database to craft.co.ke',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _uploadToVps(context, state),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Restore from VPS'),
                  subtitle: const Text(
                    'Download the latest backup from craft.co.ke',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _downloadFromVps(context, state),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Export Local Backup File'),
                  subtitle: const Text('Save a JSON copy to your device'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportLocalFile(context, state),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('M-Pesa PayBill Integration'),
                  subtitle: Text('Connected · craft.co.ke'),
                  enabled: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Version ──────────────────────────────────
          Center(
            child: Text(
              'Spectrum v1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Row ───────────────────────────────────────

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── SnackBar Helper ───────────────────────────────────

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ─── Upload Backup to VPS ──────────────────────────────

  Future<void> _uploadToVps(BuildContext context, AppState state) async {
    try {
      _showMessage(context, 'Preparing backup...');

      final data = await state.exportBackup();

      final backupService = BackupService();

      // Save a local copy before uploading.
      await backupService.saveLocalCopy(data);

      final storedAt = await backupService.uploadBackup(data);

      if (!context.mounted) return;

      final formattedDate = DateFormat('MMM d, yyyy HH:mm').format(storedAt);

      _showMessage(
        context,
        'Backup uploaded successfully. Server time: $formattedDate',
      );
    } catch (e, stackTrace) {
      debugPrint('VPS backup upload failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(context, 'Upload failed: $e', isError: true);
    }
  }

  // ─── Download and Restore from VPS ─────────────────────

  Future<void> _downloadFromVps(BuildContext context, AppState state) async {
    try {
      _showMessage(context, 'Downloading latest backup...');

      final backupService = BackupService();

      final data = await backupService.downloadLatest();

      if (!context.mounted) return;

      final exportedAt = data['exportedAt']?.toString() ?? 'unknown time';

      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Restore from VPS backup?'),
            content: Text(
              'This will replace ALL local data with the backup '
              'stored at $exportedAt.\n\n'
              'This operation cannot be undone. '
              'Consider exporting your current data first.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );

      if (!context.mounted || confirm != true) return;

      await state.restoreBackup(data);

      if (!context.mounted) return;

      _showMessage(context, 'Backup restored successfully.');
    } catch (e, stackTrace) {
      debugPrint('VPS backup restore failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(context, 'Restore failed: $e', isError: true);
    }
  }

  // ─── Export Local Backup ───────────────────────────────

  Future<void> _exportLocalFile(BuildContext context, AppState state) async {
    try {
      _showMessage(context, 'Creating local backup...');

      final data = await state.exportBackup();

      final backupService = BackupService();

      final file = await backupService.saveLocalCopy(data);

      if (!context.mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Spectrum property management backup',
        subject: 'Spectrum Backup',
      );

      if (!context.mounted) return;

      _showMessage(context, 'Backup file is ready to share or save.');
    } catch (e, stackTrace) {
      debugPrint('Local backup export failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(context, 'Export failed: $e', isError: true);
    }
  }
}

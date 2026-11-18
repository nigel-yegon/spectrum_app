// lib/config.dart
class AppConfig {
  static const String baseUrl = 'https://craft.co.ke';
  static const String businessId = 'spectrum-001';
  static const String apiKey = 'YOUR_SHARED_SECRET';

  // M-Pesa
  static const String mpesaRentPath = '/api/mpesa/rent';
  static const String mpesaStatusPath = '/api/mpesa/status';

  // Backup — matches craft.co.ke/app/api/backups/*
  static const String backupsPath = '/api/backups';

  // Rent
  static const String rentInvoicesPath = '/api/rent/invoices';
  static const String rentSyncPath = '/api/rent/units/sync';
}
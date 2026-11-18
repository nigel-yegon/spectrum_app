// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config.dart';

class BackupService {
  final http.Client _client;

  BackupService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'X-API-Key': AppConfig.apiKey,
  };

  /// Uploads a full JSON backup to craft.co.ke/api/backups.
  /// Returns the timestamp the server assigned to this backup.
  Future<DateTime> uploadBackup(Map<String, dynamic> data,
      {String label = 'manual'}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.backupsPath}');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['businessId'] = AppConfig.businessId
      ..fields['label'] = label
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        utf8.encode(jsonEncode(data)),
        filename:
        'spectrum_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      ));

    final streamed =
    await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Backup upload failed (${response.statusCode}): ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DateTime.parse(body['createdAt'] as String);
  }

  /// Downloads the latest backup JSON from craft.co.ke.
  /// Lists backups, picks the newest, fetches it.
  Future<Map<String, dynamic>> downloadLatest() async {
    // 1. List backups for this business
    final listUri = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.backupsPath}'
          '?businessId=${AppConfig.businessId}',
    );
    final listRes = await _client
        .get(listUri, headers: _headers)
        .timeout(const Duration(seconds: 30));

    if (listRes.statusCode != 200) {
      throw Exception(
          'List failed (${listRes.statusCode}): ${listRes.body}');
    }
    final list = jsonDecode(listRes.body) as List<dynamic>;
    if (list.isEmpty) throw Exception('No backups on server');

    final newest = list.first as Map<String, dynamic>;
    final downloadPath = newest['downloadUrl'] as String;

    // 2. Download the newest backup
    final dlUri = Uri.parse('${AppConfig.baseUrl}$downloadPath');
    final dlRes = await _client
        .get(dlUri, headers: _headers)
        .timeout(const Duration(seconds: 60));

    if (dlRes.statusCode != 200) {
      throw Exception(
          'Download failed (${dlRes.statusCode}): ${dlRes.body}');
    }
    return jsonDecode(dlRes.body) as Map<String, dynamic>;
  }

  /// Saves a local copy — used by the "Export Local Backup File" option
  /// and as a fallback in case the network upload fails.
  Future<File> saveLocalCopy(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/spectrum_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }
}
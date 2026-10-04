/// sync_client.dart — HTTP client for employees to sync with Owner's server
///
/// - POST /sync with new data (invoices + activity log)
/// - GET /config to fetch store configuration
/// - Error handling: timeout, connection refused, auth error
///
/// Paper Ledger design.
library;

import 'dart:convert';
import 'dart:async';
import 'dart:io';

/// Configuration for connecting to the Owner's sync server.
class SyncServerConfig {
  final String host;
  final int port;
  final String authToken;
  final String storeId;

  const SyncServerConfig({
    required this.host,
    required this.port,
    required this.authToken,
    required this.storeId,
  });

  /// Build from QR payload (JSON string).
  factory SyncServerConfig.fromQrPayload(String payload) {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    return SyncServerConfig(
      host: data['host'] as String,
      port: data['port'] as int,
      authToken: data['token'] as String,
      storeId: data['storeId'] as String,
    );
  }

  /// Encode to QR payload JSON string.
  String toQrPayload() => jsonEncode({
        'host': host,
        'port': port,
        'token': authToken,
        'storeId': storeId,
      });

  /// Base URL for HTTP requests.
  String get baseUrl => 'http://$host:$port';

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'token': authToken,
        'storeId': storeId,
      };

  factory SyncServerConfig.fromJson(Map<String, dynamic> json) {
    return SyncServerConfig(
      host: json['host'] as String,
      port: json['port'] as int,
      authToken: json['token'] as String,
      storeId: json['storeId'] as String,
    );
  }
}

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final String message;
  final int? itemsSynced;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    required this.message,
    this.itemsSynced,
    required this.timestamp,
  });

  factory SyncResult.success({int? itemsSynced}) => SyncResult(
        success: true,
        message: 'تمت المزامنة بنجاح',
        itemsSynced: itemsSynced,
        timestamp: DateTime.now(),
      );

  factory SyncResult.failure(String message) => SyncResult(
        success: false,
        message: message,
        timestamp: DateTime.now(),
      );
}

/// Sync client — connects to the Owner's local HTTP server.
///
/// Usage:
///   final client = SyncClient(config);
///   final result = await client.pushSync(payload);
class SyncClient {
  SyncClient(this._config);

  final SyncServerConfig _config;
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  SyncServerConfig get config => _config;

  /// Check if the server is reachable.
  Future<bool> checkConnection() async {
    try {
      final request = await _httpClient.getUrl(
        Uri.parse('${_config.baseUrl}/health'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /sync — push invoices + activity log to the Owner's server.
  Future<SyncResult> pushSync({
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> activityLog,
    String? deviceName,
  }) async {
    final payload = {
      'storeId': _config.storeId,
      'deviceName': deviceName ?? 'unknown',
      'invoices': invoices,
      'activityLog': activityLog,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final request = await _httpClient.postUrl(
        Uri.parse('${_config.baseUrl}/sync'),
      );

      // Auth header.
      request.headers.set('authorization', 'Bearer ${_config.authToken}');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final synced = data['itemsSynced'] as int?;
        return SyncResult.success(itemsSynced: synced);
      } else if (response.statusCode == 401) {
        return SyncResult.failure('رمز المصادقة غير صحيح');
      } else {
        final error = (jsonDecode(body) as Map<String, dynamic>)['error'] ??
            'خطأ غير معروف';
        return SyncResult.failure(error.toString());
      }
    } on SocketException catch (e) {
      if (e.message.contains('Connection refused') ||
          e.message.contains('Network is unreachable')) {
        return SyncResult.failure('تعذر الاتصال بالخادم — تأكد من Wi-Fi');
      }
      return SyncResult.failure('خطأ في الشبكة: ${e.message}');
    } on TimeoutException {
      return SyncResult.failure('انتهت مهلة الاتصال — حاول مرة أخرى');
    } on HandshakeException {
      return SyncResult.failure('خطأ في الاتصال الآمن');
    } catch (e) {
      return SyncResult.failure('خطأ غير متوقع: $e');
    }
  }

  /// GET /config — fetch store configuration from the Owner.
  Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final request = await _httpClient.getUrl(
        Uri.parse('${_config.baseUrl}/config'),
      );

      request.headers.set('authorization', 'Bearer ${_config.authToken}');

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Dispose — close the HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
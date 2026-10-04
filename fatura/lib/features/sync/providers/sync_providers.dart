/// sync_providers.dart — Riverpod providers for the sync module
///
/// - SyncConfigNotifier — save/read connection config (persisted in settings table)
/// - SyncStatusNotifier — sync state (idle/syncing/error/last_sync_time)
/// - PendingChangesNotifier — count of unsynced changes
///
/// Paper Ledger design.
library;

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/services/sync_client.dart';
import '../../../../core/services/sync_server.dart';

// ─── Sync Settings Keys ───

const _kSyncRole = 'sync_role'; // 'owner' | 'employee' | null
const _kSyncConfig = 'sync_config'; // JSON-encoded SyncServerConfig (for employee)
const _kSyncAuthToken = 'sync_auth_token'; // Owner's generated token
const _kSyncPort = 'sync_port'; // Owner's server port
const _kSyncDeviceId = 'sync_device_id';
const _kSyncDeviceName = 'sync_device_name';

// ─── DAO Providers ───

final appDatabaseProvider = Provider<db.AppDatabase>((ref) => db.AppDatabase());

final syncMetadataDaoProvider = Provider<db.SyncMetadataDao>((ref) {
  return db.SyncMetadataDao(ref.watch(appDatabaseProvider));
});

final invoicesDaoForSyncProvider = Provider<db.InvoicesDao>((ref) {
  return db.InvoicesDao(ref.watch(appDatabaseProvider));
});

final activityLogDaoForSyncProvider = Provider<db.ActivityLogDao>((ref) {
  return db.ActivityLogDao(ref.watch(appDatabaseProvider));
});

final settingsDaoForSyncProvider = Provider<db.SettingsDao>((ref) {
  return db.SettingsDao(ref.watch(appDatabaseProvider));
});

// ─── Sync Config Notifier ───

/// Holds the sync role (owner / employee / none) and connection config.
class SyncConfig {
  final String? role; // 'owner', 'employee', or null (not set up)
  final SyncServerConfig? serverConfig; // only for employee
  final String? authToken; // only for owner
  final int? port; // only for owner
  final String deviceId;
  final String? deviceName;

  const SyncConfig({
    this.role,
    this.serverConfig,
    this.authToken,
    this.port,
    required this.deviceId,
    this.deviceName,
  });

  bool get isOwner => role == 'owner';
  bool get isEmployee => role == 'employee';
  bool get isConfigured => role != null;

  SyncConfig copyWith({
    String? role,
    SyncServerConfig? serverConfig,
    String? authToken,
    int? port,
    String? deviceId,
    String? deviceName,
  }) {
    return SyncConfig(
      role: role ?? this.role,
      serverConfig: serverConfig ?? this.serverConfig,
      authToken: authToken ?? this.authToken,
      port: port ?? this.port,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}

class SyncConfigNotifier extends StateNotifier<SyncConfig> {
  final db.SettingsDao _settingsDao;

  SyncConfigNotifier(this._settingsDao)
      : super(const SyncConfig(deviceId: ''));

  /// Load config from persisted settings.
  Future<void> load() async {
    final role = await _settingsDao.getValue(_kSyncRole);
    final configJson = await _settingsDao.getValue(_kSyncConfig);
    final token = await _settingsDao.getValue(_kSyncAuthToken);
    final portStr = await _settingsDao.getValue(_kSyncPort);
    final deviceId = await _settingsDao.getValue(_kSyncDeviceId) ?? _generateDeviceId();
    final deviceName = await _settingsDao.getValue(_kSyncDeviceName);

    SyncServerConfig? serverConfig;
    if (configJson != null && configJson.isNotEmpty) {
      try {
        serverConfig = SyncServerConfig.fromJson(
            jsonDecode(configJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    state = SyncConfig(
      role: role,
      serverConfig: serverConfig,
      authToken: token,
      port: portStr != null ? int.tryParse(portStr) : null,
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }

  /// Set up as Owner with a generated token.
  Future<void> configureOwner({
    required String authToken,
    int port = 8080,
    required String deviceName,
  }) async {
    final deviceId = state.deviceId.isEmpty ? _generateDeviceId() : state.deviceId;
    await _settingsDao.upsertSetting(_kSyncRole, 'owner');
    await _settingsDao.upsertSetting(_kSyncAuthToken, authToken);
    await _settingsDao.upsertSetting(_kSyncPort, port.toString());
    await _settingsDao.upsertSetting(_kSyncDeviceId, deviceId);
    await _settingsDao.upsertSetting(_kSyncDeviceName, deviceName);

    state = SyncConfig(
      role: 'owner',
      authToken: authToken,
      port: port,
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }

  /// Set up as Employee with scanned QR config.
  Future<void> configureEmployee({
    required SyncServerConfig serverConfig,
    required String deviceName,
  }) async {
    final deviceId = state.deviceId.isEmpty ? _generateDeviceId() : state.deviceId;
    await _settingsDao.upsertSetting(_kSyncRole, 'employee');
    await _settingsDao.upsertSetting(
        _kSyncConfig, jsonEncode(serverConfig.toJson()));
    await _settingsDao.upsertSetting(_kSyncDeviceId, deviceId);
    await _settingsDao.upsertSetting(_kSyncDeviceName, deviceName);

    state = SyncConfig(
      role: 'employee',
      serverConfig: serverConfig,
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }

  /// Clear all sync config (reset).
  Future<void> clear() async {
    await _settingsDao.deleteSetting(_kSyncRole);
    await _settingsDao.deleteSetting(_kSyncConfig);
    await _settingsDao.deleteSetting(_kSyncAuthToken);
    await _settingsDao.deleteSetting(_kSyncPort);

    state = SyncConfig(deviceId: state.deviceId);
  }

  String _generateDeviceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'dev_$ts';
  }
}

final syncConfigProvider =
    StateNotifierProvider<SyncConfigNotifier, SyncConfig>((ref) {
  final notifier = SyncConfigNotifier(ref.watch(settingsDaoForSyncProvider));
  // Auto-load on first access.
  notifier.load();
  return notifier;
});

// ─── Sync Status Notifier ───

enum SyncStatus { idle, syncing, error, success }

class SyncState {
  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final int? lastSyncedCount;

  const SyncState({
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.lastSyncTime,
    this.lastSyncedCount,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncTime,
    int? lastSyncedCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncState> {
  final db.SyncMetadataDao _syncMetaDao;
  final db.InvoicesDao _invoicesDao;
  final db.ActivityLogDao _activityLogDao;
  final SyncConfigNotifier _configNotifier;
  final String _deviceId;

  SyncClient? _client;
  SyncServer? _server;

  SyncStatusNotifier(
    this._syncMetaDao,
    this._invoicesDao,
    this._activityLogDao,
    this._configNotifier,
    this._deviceId,
  ) : super(const SyncState());

  /// Perform a sync (employee → owner push).
  Future<SyncResult> performSync() async {
    final config = _configNotifier.state;

    if (!config.isEmployee || config.serverConfig == null) {
      return SyncResult.failure('الجهاز غير مهيأ كموظف');
    }

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    _client ??= SyncClient(config.serverConfig!);

    try {
      // Gather pending invoices.
      final pendingInvoices = await _invoicesDao.getPendingInvoices();
      final invoiceMaps = pendingInvoices.map((inv) => {
            'id': inv.id,
            'invoiceNumber': inv.invoiceNumber,
            'storeId': inv.storeId,
            'userId': inv.userId,
            'customerName': inv.customerName,
            'customerPhone': inv.customerPhone,
            'subtotal': inv.subtotal,
            'tax': inv.tax,
            'discount': inv.discount,
            'total': inv.total,
            'paymentMethod': inv.paymentMethod,
            'amountPaid': inv.amountPaid,
            'change': inv.change,
            'status': inv.status,
            'createdAt': inv.createdAt.toIso8601String(),
          }).toList();

      // Gather recent activity logs (last 100).
      final logs = await _activityLogDao.getAllLogs();
      final logMaps = logs.take(100).map((log) => {
            'id': log.id,
            'userId': log.userId,
            'action': log.action,
            'entityType': log.entityType,
            'entityId': log.entityId,
            'details': log.details,
            'createdAt': log.createdAt.toIso8601String(),
          }).toList();

      final result = await _client!.pushSync(
        invoices: invoiceMaps,
        activityLog: logMaps,
        deviceName: config.deviceName ?? 'unknown',
      );

      if (result.success) {
        // Mark invoices as synced.
        final ids = pendingInvoices.map((e) => e.id).toList();
        await _invoicesDao.markAllInvoicesSynced(ids);

        // Update sync metadata.
        await _syncMetaDao.updateLastSync(_deviceId, DateTime.now());

        state = SyncState(
          status: SyncStatus.success,
          lastSyncTime: DateTime.now(),
          lastSyncedCount: result.itemsSynced,
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: result.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return SyncResult.failure(e.toString());
    }
  }

  /// Start the Owner's local sync server.
  Future<String?> startOwnerServer({
    required ConfigCallback onConfigRequest,
  }) async {
    final config = _configNotifier.state;

    if (!config.isOwner || config.authToken == null) {
      return null;
    }

    final port = config.port ?? 8080;

    _server = SyncServer(
      authToken: config.authToken!,
      port: port,
      onSyncData: _handleOwnerSyncData,
      onConfigRequest: onConfigRequest,
    );

    final ip = await _server!.start();
    return ip;
  }

  /// Stop the Owner's server.
  Future<void> stopOwnerServer() async {
    await _server?.stop();
    _server = null;
  }

  /// Handle incoming sync data on the Owner's side.
  Future<Map<String, dynamic>> _handleOwnerSyncData(
      Map<String, dynamic> data) async {
    int itemsSynced = 0;

    // Insert invoices.
    final invoices = data['invoices'] as List? ?? [];
    for (final invData in invoices) {
      final inv = invData as Map<String, dynamic>;
      final existing = await _invoicesDao.getInvoiceByNumber(
          inv['invoiceNumber'] as String);
      if (existing == null) {
        await _invoicesDao.insertInvoice(db.InvoicesCompanion(
          invoiceNumber: drift.Value(inv['invoiceNumber'] as String),
          storeId: drift.Value(inv['storeId'] as int?),
          userId: drift.Value(inv['userId'] as int?),
          customerName: drift.Value(inv['customerName'] as String?),
          customerPhone: drift.Value(inv['customerPhone'] as String?),
          subtotal: drift.Value(inv['subtotal'] as double),
          tax: drift.Value((inv['tax'] as num?)?.toDouble() ?? 0),
          discount: drift.Value((inv['discount'] as num?)?.toDouble() ?? 0),
          total: drift.Value(inv['total'] as double),
          paymentMethod: drift.Value(inv['paymentMethod'] as String?),
          amountPaid: drift.Value((inv['amountPaid'] as num?)?.toDouble()),
          change: drift.Value((inv['change'] as num?)?.toDouble()),
          status: drift.Value(inv['status'] as String? ?? 'completed'),
          syncStatus: drift.Value('synced'),
          createdAt: drift.Value(
              DateTime.parse(inv['createdAt'] as String)),
        ));
        itemsSynced++;
      }
    }

    // Insert activity logs.
    final logs = data['activityLog'] as List? ?? [];
    for (final logData in logs) {
      final log = logData as Map<String, dynamic>;
      await _activityLogDao.insertLog(db.ActivityLogCompanion(
        userId: drift.Value(log['userId'] as int?),
        action: drift.Value(log['action'] as String),
        entityType: drift.Value(log['entityType'] as String?),
        entityId: drift.Value(log['entityId'] as int?),
        details: drift.Value(log['details'] as String?),
        createdAt: drift.Value(
            DateTime.parse(log['createdAt'] as String)),
      ));
    }

    return {
      'success': true,
      'itemsSynced': itemsSynced,
      'message': 'تم استلام البيانات بنجاح',
    };
  }

  /// Load last sync state from DB.
  Future<void> loadFromDb() async {
    final meta = await _syncMetaDao.getMetadataByDevice(_deviceId);
    if (meta != null) {
      state = SyncState(
        status: SyncStatus.idle,
        lastSyncTime: meta.lastSyncAt,
      );
    }
  }

  /// Check if the Owner's server is running.
  bool get isServerRunning => _server?.isRunning ?? false;

  @override
  void dispose() {
    _client?.dispose();
    _server?.stop();
    super.dispose();
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncState>((ref) {
  final configNotifier = ref.watch(syncConfigProvider.notifier);
  final deviceId = ref.watch(syncConfigProvider).deviceId;
  final notifier = SyncStatusNotifier(
    ref.watch(syncMetadataDaoProvider),
    ref.watch(invoicesDaoForSyncProvider),
    ref.watch(activityLogDaoForSyncProvider),
    configNotifier,
    deviceId,
  );
  // Auto-load from DB.
  if (deviceId.isNotEmpty) {
    notifier.loadFromDb();
  }
  return notifier;
});

// ─── Pending Changes Notifier ───

class PendingChangesNotifier extends StateNotifier<int> {
  final db.InvoicesDao _invoicesDao;

  PendingChangesNotifier(this._invoicesDao) : super(0);

  Future<void> refresh() async {
    state = await _invoicesDao.getPendingInvoicesCount();
  }
}

final pendingChangesProvider =
    StateNotifierProvider<PendingChangesNotifier, int>((ref) {
  final notifier =
      PendingChangesNotifier(ref.watch(invoicesDaoForSyncProvider));
  notifier.refresh();
  return notifier;
});

// ─── Sync Server Status (Owner) ───

/// Whether the Owner's sync server is currently running.
final syncServerRunningProvider = StateProvider<bool>((ref) => false);

// ─── Sync History ───

/// Sync history entry (in-memory, last 10 syncs).
class SyncHistoryEntry {
  final DateTime time;
  final bool success;
  final String message;
  final int? itemsSynced;

  const SyncHistoryEntry({
    required this.time,
    required this.success,
    required this.message,
    this.itemsSynced,
  });
}

final syncHistoryProvider =
    StateNotifierProvider<SyncHistoryNotifier, List<SyncHistoryEntry>>((ref) {
  return SyncHistoryNotifier();
});

class SyncHistoryNotifier extends StateNotifier<List<SyncHistoryEntry>> {
  SyncHistoryNotifier() : super([]);

  void addEntry(SyncHistoryEntry entry) {
    state = [entry, ...state].take(10).toList();
  }
}
/// backup_provider.dart — Local backup & restore provider
///
/// US-016 (modified): Local backup = default (not Google Drive).
/// Export DB file to a user-chosen path, import from file.
/// Uses path_provider + file I/O. No internet dependency.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/database.dart';
import '../../../features/inventory/providers/inventory_providers.dart';

// ─── Backup State ───

enum BackupStatus { idle, exporting, importing, success, error }

class BackupState {
  final BackupStatus status;
  final String? message;
  final String? filePath;

  const BackupState({
    this.status = BackupStatus.idle,
    this.message,
    this.filePath,
  });

  BackupState copyWith({
    BackupStatus? status,
    String? message,
    String? filePath,
  }) {
    return BackupState(
      status: status ?? this.status,
      message: message ?? this.message,
      filePath: filePath ?? this.filePath,
    );
  }
}

// ─── Backup Notifier ───

class BackupNotifier extends StateNotifier<BackupState> {
  final AppDatabase _db;

  BackupNotifier(this._db) : super(const BackupState());

  /// Get the DB file path.
  Future<File> _getDbFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'fatura.db'));
  }

  /// Get backup directory (external storage if available, else documents).
  Future<Directory> _getBackupDir() async {
    // Try external storage first (more accessible to user)
    Directory? backupDir;
    try {
      backupDir = await getExternalStorageDirectory();
    } catch (_) {
      // Not available on all platforms
    }
    backupDir ??= await getApplicationDocumentsDirectory();
    final faturaBackupDir = Directory(p.join(backupDir.path, 'FaturaBackups'));
    if (!await faturaBackupDir.exists()) {
      await faturaBackupDir.create(recursive: true);
    }
    return faturaBackupDir;
  }

  /// Export DB to a timestamped local file.
  Future<void> exportBackup() async {
    state = const BackupState(status: BackupStatus.exporting);
    try {
      final dbFile = await _getDbFile();
      if (!await dbFile.exists()) {
        state = const BackupState(
          status: BackupStatus.error,
          message: 'قاعدة البيانات غير موجودة',
        );
        return;
      }

      final backupDir = await _getBackupDir();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'fatura_backup_$timestamp.db';
      final backupPath = p.join(backupDir.path, backupFileName);

      // Copy the DB file
      await dbFile.copy(backupPath);

      state = BackupState(
        status: BackupStatus.success,
        message: 'تم إنشاء نسخة احتياطية بنجاح',
        filePath: backupPath,
      );
    } catch (e) {
      state = BackupState(
        status: BackupStatus.error,
        message: 'فشل التصدير: $e',
      );
    }
  }

  /// Import DB from a backup file path.
  Future<void> importBackup(String backupFilePath) async {
    state = const BackupState(status: BackupStatus.importing);
    try {
      final sourceFile = File(backupFilePath);
      if (!await sourceFile.exists()) {
        state = const BackupState(
          status: BackupStatus.error,
          message: 'ملف النسخة الاحتياطية غير موجود',
        );
        return;
      }

      // Close current DB connection
      await _db.close();

      // Replace DB file
      final dbFile = await _getDbFile();
      await sourceFile.copy(dbFile.path);

      state = const BackupState(
        status: BackupStatus.success,
        message: 'تم استعادة النسخة الاحتياطية بنجاح. أعد تشغيل التطبيق.',
      );
    } catch (e) {
      state = BackupState(
        status: BackupStatus.error,
        message: 'فشل الاستيراد: $e',
      );
    }
  }

  /// Share the latest backup file via system share sheet.
  Future<void> shareBackup() async {
    if (state.filePath == null) return;
    final file = XFile(state.filePath!);
    await Share.shareXFiles([file], text: 'نسخة احتياطية - فاتورة');
  }

  /// List existing backup files in backup directory.
  Future<List<File>> listBackups() async {
    try {
      final backupDir = await _getBackupDir();
      final files = await backupDir
          .list()
          .where((f) => f is File && f.path.endsWith('.db'))
          .cast<File>()
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path)); // newest first
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Reset to idle.
  void reset() {
    state = const BackupState();
  }
}

// ─── Provider ───

final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupNotifier(db);
});
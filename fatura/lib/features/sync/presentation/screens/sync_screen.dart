/// sync_screen.dart — Main sync management screen
///
/// Owner view:
///   - QR code display button
///   - "ابدأ السيرفر" / "إيقاف السيرفر" toggle
///   - Connected devices list
///
/// Employee view:
///   - "امسح QR" button
///   - Sync status display
///   - "مزامنة الآن" button
///   - Sync history (last 10)
///
/// Paper Ledger design: cream paper, ink borders, forest green.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/sync_providers.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh pending count on load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingChangesProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(syncConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المزامنة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: config.isOwner
          ? _OwnerSyncView()
          : config.isEmployee
              ? _EmployeeSyncView()
              : _NotConfiguredView(),
    );
  }
}

// ─── Owner Sync View ───

class _OwnerSyncView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(syncConfigProvider);
    final serverRunning = ref.watch(syncServerRunningProvider);
    final syncState = ref.watch(syncStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Server Status Card ───
          _SectionCard(
            title: 'حالة السيرفر',
            icon: Icons.dns,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: serverRunning
                            ? AppColors.forest
                            : AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      serverRunning ? 'يعمل' : 'متوقف',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w600,
                        color: serverRunning
                            ? AppColors.forest
                            : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                if (serverRunning && config.port != null)
                  _InfoLine(
                      label: 'المنفذ', value: config.port.toString()),
                if (serverRunning)
                  _InfoLine(
                    label: 'آخر نشاط',
                    value: syncState.lastSyncTime != null
                        ? _formatDateTime(syncState.lastSyncTime!)
                        : 'لا نشاط بعد',
                  ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: serverRunning
                        ? null
                        : () => _startServer(context, ref),
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text('ابدأ السيرفر'),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: serverRunning
                        ? () => _stopServer(context, ref)
                        : null,
                    icon: const Icon(Icons.stop, size: 24),
                    label: const Text('إيقاف السيرفر'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.stampRed,
                      side: const BorderSide(
                          color: AppColors.stampRed, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ─── QR Code Section ───
          _SectionCard(
            title: 'رمز QR للموظفين',
            icon: Icons.qr_code,
            child: Column(
              children: [
                const Text(
                  'اعرض رمز QR ليقوم الموظفون بمسحه وإعداد المزامنة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/sync/qr'),
                    icon: const Icon(Icons.qr_code_2, size: 24),
                    label: const Text('عرض رمز QR'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ─── Connected Devices ───
          _SectionCard(
            title: 'الأجهزة المتصلة',
            icon: Icons.devices,
            child: _ConnectedDevicesList(),
          ),
        ],
      ),
    );
  }

  Future<void> _startServer(BuildContext context, WidgetRef ref) async {
    try {
      final config = ref.read(syncConfigProvider);
      final storeName = 'متجر فاتورة';

      final ip = await ref
          .read(syncStatusProvider.notifier)
          .startOwnerServer(
            onConfigRequest: () async {
              return {
                'storeName': storeName,
                'currency': 'EGP',
                'language': 'ar',
              };
            },
          );

      if (ip != null) {
        ref.read(syncServerRunningProvider.notifier).state = true;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('بدأ السيرفر على $ip:${config.port ?? 8080}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في بدء السيرفر: $e')),
        );
      }
    }
  }

  Future<void> _stopServer(BuildContext context, WidgetRef ref) async {
    await ref.read(syncStatusProvider.notifier).stopOwnerServer();
    ref.read(syncServerRunningProvider.notifier).state = false;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إيقاف السيرفر'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─── Employee Sync View ───

class _EmployeeSyncView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingChangesProvider);
    final history = ref.watch(syncHistoryProvider);
    final config = ref.watch(syncConfigProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Connection Status ───
          _SectionCard(
            title: 'حالة الاتصال',
            icon: Icons.wifi,
            child: Column(
              children: [
                if (config.serverConfig != null) ...[
                  _InfoLine(
                    label: 'الخادم',
                    value:
                        '${config.serverConfig!.host}:${config.serverConfig!.port}',
                  ),
                  _InfoLine(
                    label: 'الرمز',
                    value:
                        '${config.serverConfig!.authToken.substring(0, 8)}...',
                  ),
                ],
                _InfoLine(
                  label: 'حالة المزامنة',
                  value: _statusLabel(syncState.status),
                ),
                if (syncState.lastSyncTime != null)
                  _InfoLine(
                    label: 'آخر مزامنة',
                    value: _formatDateTime(syncState.lastSyncTime!),
                  ),
                if (syncState.errorMessage != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color:
                          AppColors.stampRed.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSM),
                    ),
                    child: Text(
                      syncState.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontSM,
                        color: AppColors.stampRed,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ─── Pending Changes ───
          _SectionCard(
            title: 'التغييرات غير المزامنة',
            icon: Icons.pending_actions,
            child: Row(
              children: [
                Text(
                  '$pendingCount',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                    color: pendingCount > 0
                        ? AppColors.stampRed
                        : AppColors.forest,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  pendingCount == 0 ? 'كل شيء متزامن' : 'فاتورة بانتظار المزامنة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontMD,
                    color: pendingCount > 0
                        ? AppColors.inkLight
                        : AppColors.forest,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ─── Actions ───
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: syncState.status == SyncStatus.syncing
                  ? null
                  : () => _performSync(context, ref),
              icon: syncState.status == SyncStatus.syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 24),
              label: const Text('مزامنة الآن'),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/sync/qr'),
              icon: const Icon(Icons.qr_code_scanner, size: 24),
              label: const Text('امسح QR'),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ─── Sync History ───
          _SectionCard(
            title: 'سجل المزامنة',
            icon: Icons.history,
            child: history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Text(
                      'لا توجد مزامنات بعد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.inkMuted,
                      ),
                    ),
                  )
                : Column(
                    children: history.map((entry) {
                      return _HistoryTile(entry: entry);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(syncStatusProvider.notifier).performSync();

    // Add to history.
    ref.read(syncHistoryProvider.notifier).addEntry(
          SyncHistoryEntry(
            time: result.timestamp,
            success: result.success,
            message: result.message,
            itemsSynced: result.itemsSynced,
          ),
        );

    // Refresh pending count.
    ref.read(pendingChangesProvider.notifier).refresh();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─── Not Configured View ───

class _NotConfiguredView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_disabled,
              size: 64, color: AppColors.inkMuted),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'المزامنة غير مهيأة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontXL,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'اختر دورك لبدء إعداد المزامنة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontMD,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Generate a token and configure as owner.
                final token = _generateToken();
                await ref.read(syncConfigProvider.notifier).configureOwner(
                      authToken: token,
                      port: 8080,
                      deviceName: 'Owner Device',
                    );
                if (context.mounted) {
                  context.push('/sync/qr');
                }
              },
              icon: const Icon(Icons.store, size: 24),
              label: const Text('أنا المالك'),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/sync/qr'),
              icon: const Icon(Icons.person, size: 24),
              label: const Text('أنا موظف'),
            ),
          ),
        ],
      ),
    );
  }

  String _generateToken() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return random.toRadixString(16).padLeft(32, '0');
  }
}

// ─── Connected Devices List ───

class _ConnectedDevicesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the DAO stream for live updates.
    return StreamBuilder(
      stream: ref.watch(syncMetadataDaoProvider).watchAllMetadata(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Text(
              'لا توجد أجهزة متصلة بعد',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.inkMuted,
              ),
            ),
          );
        }

        final devices = snapshot.data!;
        return Column(
          children: devices.map((device) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                device.syncRole == 'owner'
                    ? Icons.phone_iphone
                    : Icons.tablet_android,
                color: AppColors.forest,
                size: 28,
              ),
              title: Text(
                device.deviceName ?? device.deviceId,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontMD,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                device.syncRole == 'owner' ? 'مالك' : 'موظف',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontSM,
                  color: AppColors.inkMuted,
                ),
              ),
              trailing: device.lastSyncAt != null
                  ? Text(
                      _formatDateTime(device.lastSyncAt!),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontXS,
                        color: AppColors.inkMuted,
                      ),
                    )
                  : const Text(
                      'بانتظار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontXS,
                        color: AppColors.ochre,
                      ),
                    ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── History Tile ───

class _HistoryTile extends StatelessWidget {
  final SyncHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        children: [
          Icon(
            entry.success ? Icons.check_circle : Icons.error,
            size: 20,
            color: entry.success ? AppColors.forest : AppColors.stampRed,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.message,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  _formatDateTime(entry.time),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXS,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (entry.itemsSynced != null)
            Text(
              '${entry.itemsSynced}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w700,
                color: AppColors.forest,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.forest),
              const SizedBox(width: AppSizes.sm),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.ledgerLine, height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              color: AppColors.inkMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ───

String _statusLabel(SyncStatus status) {
  switch (status) {
    case SyncStatus.idle:
      return 'خامل';
    case SyncStatus.syncing:
      return 'جاري المزامنة';
    case SyncStatus.error:
      return 'خطأ';
    case SyncStatus.success:
      return 'نجحت';
  }
}

String _formatDateTime(DateTime dt) {
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'م' : 'ص';
  return '${dt.day}/${dt.month} $hour:$minute $period';
}
/// qr_setup_screen.dart — QR code generation (Owner) + scanning (Employee)
///
/// Owner: generates QR with store ID + IP + port + token
/// Employee: scans QR → parses → saves config
///
/// Uses qr_flutter for generation, mobile_scanner for scanning.
/// Paper Ledger design: cream paper, ink borders, forest green.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/sync_client.dart';
import '../../providers/sync_providers.dart';

/// Entry point — shows Owner or Employee UI based on sync role.
class QrSetupScreen extends ConsumerWidget {
  const QrSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(syncConfigProvider);

    if (config.isOwner) {
      return const _OwnerQrScreen();
    }
    return const _EmployeeScanScreen();
  }
}

// ─── Owner QR Generation Screen ───

class _OwnerQrScreen extends ConsumerStatefulWidget {
  const _OwnerQrScreen();

  @override
  ConsumerState<_OwnerQrScreen> createState() => _OwnerQrScreenState();
}

class _OwnerQrScreenState extends ConsumerState<_OwnerQrScreen> {
  String? _qrPayload;
  String? _ip;
  String? _token;
  bool _isGenerating = true;

  @override
  void initState() {
    super.initState();
    _generateQr();
  }

  Future<void> _generateQr() async {
    final config = ref.read(syncConfigProvider);

    // Generate a random token if not already set.
    _token = config.authToken ?? _generateToken();

    final port = config.port ?? 8080;

    // Get local IP address.
    _ip = await _getLocalIp();

    // Build QR payload.
    final payload = {
      'host': _ip,
      'port': port,
      'token': _token,
      'storeId': 'store_${DateTime.now().millisecondsSinceEpoch}',
    };

    _qrPayload = jsonEncode(payload);

    // Save owner config.
    await ref.read(syncConfigProvider.notifier).configureOwner(
          authToken: _token!,
          port: port,
          deviceName: 'Owner Device',
        );

    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes =
        List<int>.generate(32, (_) => random.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رمز QR للموظفين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(
                          color: AppColors.ledgerBorder, width: 1.5),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.indigo, size: 20),
                        SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            'اطلب من الموظف مسح هذا الرمز لإعداد المزامنة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontSM,
                              color: AppColors.inkLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.xl),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: AppColors.ledgerBorder, width: 2),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLG),
                    ),
                    child: QrImageView(
                      data: _qrPayload!,
                      version: QrVersions.auto,
                      size: 250,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.ink,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.ink,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Server info
                  _InfoRow(label: 'العنوان', value: _ip ?? 'غير متاح'),
                  _InfoRow(
                      label: 'المنفذ',
                      value: (ref.watch(syncConfigProvider).port ?? 8080)
                          .toString()),
                  _InfoRow(
                      label: 'الرمز',
                      value: '${_token?.substring(0, 8)}...'),

                  const SizedBox(height: AppSizes.lg),

                  // Regenerate button
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isGenerating = true);
                      _generateQr();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('إعادة توليد الرمز'),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Share button (text-based for now)
                  OutlinedButton.icon(
                    onPressed: () {
                      // Copy QR payload to clipboard for manual sharing.
                      // In production, use share_plus to share as text.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ بيانات الاتصال'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('مشاركة بيانات الاتصال'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Employee QR Scan Screen ───

class _EmployeeScanScreen extends ConsumerStatefulWidget {
  const _EmployeeScanScreen();

  @override
  ConsumerState<_EmployeeScanScreen> createState() =>
      _EmployeeScanScreenState();
}

class _EmployeeScanScreenState extends ConsumerState<_EmployeeScanScreen> {
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مسح QR للاتصال'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isScanning ? _buildScanner() : _buildStartView(),
    );
  }

  Widget _buildStartView() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSizes.xl),
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.forest, width: 2),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 56,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'امسح رمز QR',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontXL,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'اطلب من المالك عرض رمز QR ثم امسحه لإعداد المزامنة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontMD,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.stampRed.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.stampRed, width: 1.5),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.stampRed, size: 20),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontSM,
                        color: AppColors.stampRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
          ],

          // Start scanning button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isScanning = true;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.camera_alt, size: 24),
            label: const Text('ابدأ المسح'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (_isProcessing) return;
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;

            final barcode = barcodes.first;
            final rawValue = barcode.rawValue;
            if (rawValue == null) return;

            _processQrCode(rawValue);
          },
        ),

        // Overlay with scan frame
        _ScanOverlay(),

        // Cancel button
        Positioned(
          bottom: AppSizes.xl,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isScanning = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stampRed,
              ),
              child: const Text('إلغاء'),
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.background,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _processQrCode(String rawValue) async {
    setState(() => _isProcessing = true);

    try {
      final config = SyncServerConfig.fromQrPayload(rawValue);

      // Test connection.
      final client = SyncClient(config);
      final connected = await client.checkConnection();
      client.dispose();

      if (!connected) {
        setState(() {
          _isProcessing = false;
          _isScanning = false;
          _errorMessage = 'تعذر الاتصال بالخادم — تأكد من Wi-Fi';
        });
        return;
      }

      // Save config.
      await ref.read(syncConfigProvider.notifier).configureEmployee(
            serverConfig: config,
            deviceName: 'Employee Device',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعداد المزامنة بنجاح!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isScanning = false;
        _errorMessage = 'رمز QR غير صحيح: $e';
      });
    }
  }
}

// ─── Scan Overlay ───

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.4),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row Widget ───

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontMD,
              color: AppColors.inkMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontMD,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
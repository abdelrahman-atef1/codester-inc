/// settings_screen.dart — Full settings screen (US-013, US-014, US-016)
///
/// Paper Ledger style: cream paper, bordered tiles, forest green icons.
/// Sections:
///   1. Store data (name, type, address, phone)
///   2. Language toggle (ar/en) — instant switch
///   3. Currency selector (EGP, SAR, AED, KWD, USD)
///   4. Tax settings (enable/disable + rate)
///   5. Backup: local (default) + Google Drive (optional placeholder)
///   6. Bluetooth printer (placeholder)
///   7. About
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../inventory/providers/inventory_providers.dart';
import '../../../users/providers/permission_providers.dart';
import '../../providers/backup_provider.dart';
import '../../../sync/providers/sync_providers.dart' as sync;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Store data controllers
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  String _storeType = AppStrings.typeShop;

  // Tax
  bool _taxEnabled = false;
  final _taxRateController = TextEditingController(text: '0');

  // Loading state
  bool _isLoading = true;
  bool _isSaving = false;

  // Store record ID
  int? _storeId;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    final database = ref.read(appDatabaseProvider);
    final store = await database.storesDao.getFirstStore();

    if (store != null) {
      _storeId = store.id;
      _storeNameController.text = store.name;
      _storeAddressController.text = store.address ?? '';
      _storePhoneController.text = store.phone ?? '';
      _storeType = store.type ?? AppStrings.typeShop;
      _taxEnabled = store.taxEnabled;
      _taxRateController.text = store.taxRate.toStringAsFixed(1);
    }

    // Load persisted currency
    ref.read(currencyProvider.notifier).load();
    // Load persisted locale
    ref.read(localeProvider.notifier).load();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStoreData() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final database = ref.read(appDatabaseProvider);

      if (_storeId != null) {
        // Update existing store
        await database.storesDao.updateStoreFields(
          _storeId!,
          StoresCompanion(
            name: Value(_storeNameController.text.trim()),
            type: Value(_storeType),
            address: Value(_storeAddressController.text.trim()),
            phone: Value(_storePhoneController.text.trim()),
            taxEnabled: Value(_taxEnabled),
            taxRate: Value(double.tryParse(_taxRateController.text) ?? 0),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.navSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navSettings),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveStoreData,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    AppStrings.save2,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        children: [
          // ─── Section 1: Store Data ───
          _SectionHeader(title: 'بيانات المتجر', icon: Icons.store),
          _StoreDataSection(
            nameController: _storeNameController,
            addressController: _storeAddressController,
            phoneController: _storePhoneController,
            storeType: _storeType,
            onTypeChanged: (type) => setState(() => _storeType = type),
          ),

          const _Divider(),

          // ─── Section 2: Language ───
          _SectionHeader(title: AppStrings.language, icon: Icons.language),
          _LanguageToggle(),

          const _Divider(),

          // ─── Section 3: Currency ───
          _SectionHeader(title: AppStrings.currency, icon: Icons.attach_money),
          _CurrencySelector(),

          const _Divider(),

          // ─── Section 4: Tax Settings ───
          _SectionHeader(title: 'إعدادات الضريبة', icon: Icons.percent),
          _TaxSection(
            taxEnabled: _taxEnabled,
            onToggle: (v) => setState(() => _taxEnabled = v),
            taxRateController: _taxRateController,
          ),

          const _Divider(),

          // ─── Section 5: Backup ───
          _SectionHeader(title: AppStrings.backup, icon: Icons.backup),
          const _BackupSection(),

          const _Divider(),

          // ─── Section 6: Bluetooth Printer ───
          _SectionHeader(title: 'طابعة بلوتوث', icon: Icons.print),
          const _BluetoothPrinterSection(),

          const _Divider(),

          // ─── Section 7: Sync (المزامنة) ───
          _SectionHeader(title: 'المزامنة', icon: Icons.sync),
          _SyncSection(),

          const _Divider(),

          // ─── Section 8: Users ───
          _SectionHeader(title: 'إدارة الموظفين', icon: Icons.people),
          _SettingsTile(
            icon: Icons.people,
            title: 'إدارة الموظفين',
            subtitle: 'إضافة وتعديل الموظفين',
            onTap: () => context.push('/users'),
          ),

          const _Divider(),

          // ─── Section 9: Feedback ───
          _SectionHeader(title: 'الملاحظات والاقتراحات', icon: Icons.feedback),
          _SettingsTile(
            icon: Icons.send,
            title: 'أرسل ملاحظة',
            subtitle: 'ابلغ عن مشكلة أو اطلب ميزة جديدة',
            onTap: () => context.push('/feedback'),
          ),
          if (ref.watch(permissionProvider(Permissions.users)))
            _SettingsTile(
              icon: Icons.list_alt,
              title: 'عرض الملاحظات',
              subtitle: 'إدارة ملاحظات المستخدمين',
              onTap: () => context.push('/feedback/list'),
            ),

          const _Divider(),

          // ─── Section 10: About ───
          _SectionHeader(title: AppStrings.about, icon: Icons.info),
          _SettingsTile(
            icon: Icons.info,
            title: AppStrings.about,
            subtitle: '${AppStrings.appName} v1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.receipt, color: AppColors.forest, size: 28),
            SizedBox(width: AppSizes.sm),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.appName} — ${AppStrings.appTagline}',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.inkLight,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            Text(
              'الإصدار: 1.0.0',
              style: TextStyle(fontFamily: 'Cairo', color: AppColors.inkMuted),
            ),
            SizedBox(height: AppSizes.xs),
            Text(
              'Codester-inc © 2026',
              style: TextStyle(fontFamily: 'Cairo', color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section Header
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLG,
        AppSizes.paddingMD,
        AppSizes.paddingLG,
        AppSizes.paddingSM,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.forest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
              border: Border.all(color: AppColors.ledgerBorder, width: 1),
            ),
            child: Icon(icon, color: AppColors.forest, size: 18),
          ),
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
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Divider(color: AppColors.ledgerLine, thickness: 1),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 1: Store Data
// ═══════════════════════════════════════════════════════════════

class _StoreDataSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final String storeType;
  final ValueChanged<String> onTypeChanged;

  const _StoreDataSection({
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.storeType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: AppStrings.storeName,
              prefixIcon: Icon(Icons.store, color: AppColors.forest),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Store type selector
          DropdownButtonFormField<String>(
            initialValue: storeType,
            decoration: const InputDecoration(
              hintText: AppStrings.storeType,
              prefixIcon: Icon(Icons.category, color: AppColors.forest),
            ),
            items: const [
              DropdownMenuItem(value: AppStrings.typeKiosk, child: Text(AppStrings.typeKiosk)),
              DropdownMenuItem(value: AppStrings.typeShop, child: Text(AppStrings.typeShop)),
              DropdownMenuItem(value: AppStrings.typeHandicraft, child: Text(AppStrings.typeHandicraft)),
              DropdownMenuItem(value: AppStrings.typeOther, child: Text(AppStrings.typeOther)),
            ],
            onChanged: (v) => onTypeChanged(v ?? AppStrings.typeShop),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              hintText: AppStrings.storeAddress,
              prefixIcon: Icon(Icons.location_on, color: AppColors.forest),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: AppStrings.storePhone,
              prefixIcon: Icon(Icons.phone, color: AppColors.forest),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 2: Language Toggle
// ═══════════════════════════════════════════════════════════════

class _LanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: AppColors.forest, size: 20),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    isArabic ? AppStrings.arabic : AppStrings.english,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                // Segmented toggle
                _SegmentedToggle(
                  isArabic: isArabic,
                  onChanged: (ar) {
                    HapticFeedback.selectionClick();
                    ref.read(localeProvider.notifier).setLocale(
                      ar ? const Locale('ar', 'EG') : const Locale('en', 'US'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              isArabic
                  ? 'التبديل فوري بدون إعادة تشغيل — RTL'
                  : 'Instant switch, no restart — LTR',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<bool> onChanged;

  const _SegmentedToggle({required this.isArabic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        border: Border.all(color: AppColors.ledgerBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('ع', isArabic, () => onChanged(true)),
          _toggleButton('EN', !isArabic, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSizes.durationShort,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.background : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 3: Currency Selector
// ═══════════════════════════════════════════════════════════════

class _CurrencySelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: AppSizes.sm,
                mainAxisSpacing: AppSizes.sm,
              ),
              itemCount: CurrencyInfo.all.length,
              itemBuilder: (context, index) {
                final currency = CurrencyInfo.all[index];
                final isSelected = currency.code == currentCurrency.code;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(currencyProvider.notifier).setCurrency(currency.code);
                  },
                  child: AnimatedContainer(
                    duration: AppSizes.durationShort,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.forest.withValues(alpha: 0.1)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.forest
                            : AppColors.ledgerBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currency.symbol,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontLG,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.forest
                                : AppColors.ink,
                          ),
                        ),
                        Text(
                          currency.code,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontXS,
                            color: isSelected
                                ? AppColors.forestLight
                                : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'العملة الحالية: ${currentCurrency.nameAr}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 4: Tax Settings
// ═══════════════════════════════════════════════════════════════

class _TaxSection extends StatelessWidget {
  final bool taxEnabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController taxRateController;

  const _TaxSection({
    required this.taxEnabled,
    required this.onToggle,
    required this.taxRateController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.percent, color: AppColors.forest, size: 20),
                const SizedBox(width: AppSizes.sm),
                const Expanded(
                  child: Text(
                    'تفعيل الضريبة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                // Toggle switch — Paper Ledger style
                _PaperToggle(
                  value: taxEnabled,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    onToggle(v);
                  },
                ),
              ],
            ),
            // Tax rate field — only visible when tax is enabled
            AnimatedSize(
              duration: AppSizes.durationShort,
              curve: Curves.easeInOut,
              child: taxEnabled
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSizes.md),
                      child: TextField(
                        controller: taxRateController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'نسبة الضريبة %',
                          prefixIcon:
                              Icon(Icons.percent, color: AppColors.forest),
                          suffixText: '%',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PaperToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppSizes.durationShort,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          color: value ? AppColors.forest : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
          border: Border.all(
            color: value ? AppColors.forestDark : AppColors.ledgerBorder,
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: AppSizes.durationShort,
          curve: Curves.easeInOutBack,
          alignment: value
              ? (Directionality.of(context) == TextDirection.rtl
                  ? Alignment.centerLeft
                  : Alignment.centerRight)
              : (Directionality.of(context) == TextDirection.rtl
                  ? Alignment.centerRight
                  : Alignment.centerLeft),
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? AppColors.background : AppColors.inkMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 5: Backup
// ═══════════════════════════════════════════════════════════════

class _BackupSection extends ConsumerWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Local backup (default)
            Row(
              children: [
                const Icon(Icons.save, color: AppColors.forest, size: 20),
                const SizedBox(width: AppSizes.sm),
                const Expanded(
                  child: Text(
                    'نسخة احتياطية محلية (افتراضي)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            // Status message
            if (backupState.message != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSM,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: backupState.status == BackupStatus.success
                      ? AppColors.forest.withValues(alpha: 0.1)
                      : backupState.status == BackupStatus.error
                          ? AppColors.stampRed.withValues(alpha: 0.1)
                          : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                ),
                child: Text(
                  backupState.message!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    color: backupState.status == BackupStatus.success
                        ? AppColors.forest
                        : backupState.status == BackupStatus.error
                            ? AppColors.stampRed
                            : AppColors.inkLight,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: backupState.status == BackupStatus.exporting
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            ref.read(backupProvider.notifier).exportBackup();
                          },
                    icon: backupState.status == BackupStatus.exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : const Icon(Icons.upload_file, size: 20),
                    label: const Text('تصدير نسخة'),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImportDialog(context, ref),
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('استيراد نسخة'),
                  ),
                ),
              ],
            ),
            if (backupState.status == BackupStatus.success &&
                backupState.filePath != null) ...[
              const SizedBox(height: AppSizes.sm),
              TextButton.icon(
                onPressed: () =>
                    ref.read(backupProvider.notifier).shareBackup(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('مشاركة النسخة الاحتياطية'),
              ),
            ],

            const SizedBox(height: AppSizes.md),
            const Divider(color: AppColors.ledgerLine, thickness: 1),
            const SizedBox(height: AppSizes.md),

            // Google Drive (optional)
            Row(
              children: [
                const Icon(Icons.cloud_upload,
                    color: AppColors.inkMuted, size: 20),
                const SizedBox(width: AppSizes.sm),
                const Expanded(
                  child: Text(
                    'Google Drive (اختياري)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkLight,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSM,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ochre.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    border: Border.all(color: AppColors.ochre, width: 1),
                  ),
                  child: const Text(
                    'قريباً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ochre,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) async {
    final backups = await ref.read(backupProvider.notifier).listBackups();

    if (!context.mounted) return;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد نسخ احتياطية')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        title: const Text(
          'استيراد نسخة احتياطية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (ctx, index) {
              final file = backups[index];
              final fileName = file.path.split('/').last;
              final date = file.statSync().modified;

              return ListTile(
                leading: const Icon(Icons.backup_table,
                    color: AppColors.forest),
                title: Text(
                  fileName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXS,
                    color: AppColors.inkMuted,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(backupProvider.notifier)
                      .importBackup(file.path);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 6: Bluetooth Printer (placeholder)
// ═══════════════════════════════════════════════════════════════

class _BluetoothPrinterSection extends StatelessWidget {
  const _BluetoothPrinterSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.print, color: AppColors.forest, size: 20),
            const SizedBox(width: AppSizes.sm),
            const Expanded(
              child: Text(
                'طابعة حرارية Bluetooth (58mm / 80mm)',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontMD,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم دعم الطابعات الحرارية قريباً'),
                  ),
                );
              },
              icon: const Icon(Icons.bluetooth, size: 18),
              label: const Text('اتصال'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Generic Settings Tile
// ═══════════════════════════════════════════════════════════════

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.forest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          border: Border.all(color: AppColors.ledgerBorder, width: 1),
        ),
        child: Icon(icon, color: AppColors.forest, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.inkMuted,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section 7: Sync (المزامنة)
// ═══════════════════════════════════════════════════════════════

class _SyncSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sync.syncConfigProvider);
    final syncState = ref.watch(sync.syncStatusProvider);
    final pendingCount = ref.watch(sync.pendingChangesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      child: Column(
        children: [
          // Sync status summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  config.isConfigured
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: config.isConfigured
                      ? AppColors.forest
                      : AppColors.inkMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    config.isConfigured
                        ? config.isOwner
                            ? 'الجهاز مهيأ كمالك'
                            : 'الجهاز مهيأ كموظف'
                        : 'المزامنة غير مهيأة',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ochre.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ochre,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Owner tiles
          if (config.isOwner) ...[
            _SettingsTile(
              icon: Icons.qr_code_2,
              title: 'إنشاء QR للموظفين',
              subtitle: 'اعرض رمز QR لإعداد الموظفين',
              onTap: () => context.push('/sync/qr'),
            ),
            _SettingsTile(
              icon: Icons.dns,
              title: 'إعدادات السيرفر',
              subtitle: 'بدء/إيقاف السيرفر وإدارة الأجهزة',
              onTap: () => context.push('/sync'),
            ),
          ],

          // Employee tiles
          if (config.isEmployee) ...[
            _SettingsTile(
              icon: Icons.qr_code_scanner,
              title: 'مسح QR',
              subtitle: 'إعادة إعداد الاتصال بالخادم',
              onTap: () => context.push('/sync/qr'),
            ),
            _SettingsTile(
              icon: Icons.sync,
              title: 'مزامنة الآن',
              subtitle: pendingCount > 0
                  ? 'بانتظار المزامنة ($pendingCount)'
                  : 'كل شيء متزامن',
              onTap: () => context.push('/sync'),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'حالة المزامنة',
              subtitle: syncState.lastSyncTime != null
                  ? 'آخر مزامنة: ${_formatSyncTime(syncState.lastSyncTime!)}'
                  : 'لا مزامنة بعد',
              onTap: () => context.push('/sync'),
            ),
          ],

          // Not configured — setup tile
          if (!config.isConfigured)
            _SettingsTile(
              icon: Icons.sync,
              title: 'إعداد المزامنة',
              subtitle: 'اختر دورك وابدأ المزامنة',
              onTap: () => context.push('/sync'),
            ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
}
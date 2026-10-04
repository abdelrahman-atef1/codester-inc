import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/database.dart' as db;
import '../../domain/entities/product.dart';
import '../../providers/inventory_providers.dart';
import 'add_edit_product_screen.dart';

/// T-009: Product Detail Screen — Paper Ledger style
/// Bordered cards, ink text, forest green / stamp red accents.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final activityLogAsync = ref.watch(productActivityLogProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'تفاصيل المنتج',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.forest, size: 22),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) => _buildContent(product, activityLogAsync),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
        error: (err, _) => Center(
          child: Text(
            'خطأ: $err',
            style: const TextStyle(color: AppColors.stampRed),
          ),
        ),
      ),
    );
  }

  // ─── Main Content ───

  Widget _buildContent(
    Product product,
    AsyncValue<List<db.ActivityLogData>> activityLogAsync,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Product Header Card ───
        _buildHeaderCard(product),
        const SizedBox(height: 20),

        // ─── Details Section ───
        _buildDetailsSection(product),
        const SizedBox(height: 20),

        // ─── Activity Log ───
        _buildActivityLog(activityLogAsync),
        const SizedBox(height: 20),

        // ─── Action Buttons ───
        _buildActionButtons(product),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Header Card ───

  Widget _buildHeaderCard(Product product) {
    final status = product.stockStatus;
    final (statusColor, statusBg) = switch (status) {
      ProductStockStatus.inStock =>
        (AppColors.forest, AppColors.forest.withValues(alpha: 0.12)),
      ProductStockStatus.lowStock =>
        (AppColors.ochre, AppColors.ochre.withValues(alpha: 0.12)),
      ProductStockStatus.outOfStock =>
        (AppColors.stampRed, AppColors.stampRed.withValues(alpha: 0.12)),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        children: [
          // ─── Product Icon ───
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.forest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ledgerBorder, width: 1),
            ),
            child: const Icon(
              Icons.inventory_2,
              size: 32,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 16),

          // ─── Product Name ───
          Text(
            product.name,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ─── Status Badge ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Details Section ───

  Widget _buildDetailsSection(Product product) {
    final details = <_DetailItem>[
      _DetailItem(
        icon: Icons.attach_money,
        label: 'السعر',
        value: '${product.price.toStringAsFixed(2)} ج.م',
        color: AppColors.forest,
      ),
      _DetailItem(
        icon: Icons.inventory,
        label: 'الكمية المتاحة',
        value: '${product.quantity} ${product.unit}',
        color: AppColors.ink,
      ),
      _DetailItem(
        icon: Icons.warning_amber,
        label: 'الحد الأدنى',
        value: '${product.minQuantity} ${product.unit}',
        color: AppColors.ochre,
      ),
      if (product.barcode != null && product.barcode!.isNotEmpty)
        _DetailItem(
          icon: Icons.qr_code,
          label: 'الباركود',
          value: product.barcode!,
          color: AppColors.sepia,
        ),
      if (product.category != null && product.category!.isNotEmpty)
        _DetailItem(
          icon: Icons.category_outlined,
          label: 'الفئة',
          value: product.category!,
          color: AppColors.ink,
        ),
      _DetailItem(
        icon: Icons.straighten,
        label: 'وحدة القياس',
        value: product.unit,
        color: AppColors.ink,
      ),
      if (product.cost != null)
        _DetailItem(
          icon: Icons.trending_down,
          label: 'التكلفة',
          value: '${product.cost!.toStringAsFixed(2)} ج.م',
          color: AppColors.inkLight,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بيانات المنتج',
            style: TextStyle(
              color: AppColors.inkLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...details.map((d) => _buildDetailRow(d)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(width: 12),
          Text(
            item.label,
            style: const TextStyle(
              color: AppColors.inkLight,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              color: item.color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Activity Log ───

  Widget _buildActivityLog(AsyncValue<List<db.ActivityLogData>> activityLogAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.sepia, size: 20),
              const SizedBox(width: 8),
              const Text(
                'سجل النشاط',
                style: TextStyle(
                  color: AppColors.inkLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              activityLogAsync.whenOrNull(
                data: (logs) => Text(
                  '${logs.length} حدث',
                  style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                ),
              ) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          activityLogAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return _buildEmptyActivityLog();
              }
              return Column(
                children: logs.map((log) => _buildActivityLogItem(log)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.sepia, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Text(
              'تعذّر تحميل السجل',
              style: TextStyle(color: AppColors.stampRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityLog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off, color: AppColors.inkMuted, size: 32),
            const SizedBox(height: 8),
            const Text(
              'لا يوجد نشاط بعد',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogItem(db.ActivityLogData log) {
    final (icon, color) = _activityIcon(log.action);
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.details ?? log.action,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeFormat.format(log.createdAt),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _activityIcon(String action) {
    return switch (action) {
      'add_product' => (Icons.add_circle_outline, AppColors.forest),
      'edit_product' => (Icons.edit_outlined, AppColors.forest),
      'delete_product' => (Icons.delete_outline, AppColors.stampRed),
      'sale' => (Icons.point_of_sale_outlined, AppColors.sepia),
      _ => (Icons.info_outline, AppColors.inkLight),
    };
  }

  // ─── Action Buttons ───

  Widget _buildActionButtons(Product product) {
    return Row(
      children: [
        // ─── Edit Button ───
        Expanded(
          child: _buildActionButton(
            label: 'تعديل',
            icon: Icons.edit,
            color: AppColors.forest,
            onTap: () => _navigateToEdit(),
          ),
        ),
        const SizedBox(width: 12),
        // ─── Delete Button ───
        Expanded(
          child: _buildActionButton(
            label: _isDeleting ? 'جارٍ الحذف...' : 'حذف',
            icon: Icons.delete_outline,
            color: AppColors.stampRed,
            isLoading: _isDeleting,
            onTap: _isDeleting ? null : () => _confirmDelete(product),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Navigation / Actions ───

  void _navigateToEdit() async {
    final product = ref.read(productByIdProvider(widget.productId)).valueOrNull;
    if (product == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(product: product),
      ),
    );

    if (result == true) {
      ref.invalidate(productByIdProvider(widget.productId));
      ref.invalidate(productActivityLogProvider(widget.productId));
    }
  }

  Future<void> _confirmDelete(Product product) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(color: AppColors.ink, fontSize: 18),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${product.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(color: AppColors.inkLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.inkLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.stampRed),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(deleteProductUseCaseProvider).call(product.id);

      // Log activity
      final dao = ref.read(activityLogDaoProvider);
      await dao.insertLog(
        db.ActivityLogCompanion(
          action: const drift.Value('delete_product'),
          entityType: const drift.Value('product'),
          entityId: drift.Value(product.id),
          details: drift.Value('تم حذف المنتج: ${product.name}'),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المنتج'),
            backgroundColor: AppColors.ink,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.stampRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}

// ─── Helper ───

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
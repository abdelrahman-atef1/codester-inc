import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/database.dart' as db;
import '../../domain/entities/product.dart';
import '../../providers/inventory_providers.dart';

/// T-008: Add/Edit Product Screen — Paper Ledger style
/// Underline inputs, bordered chips, flat forest green save button.
class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product; // null = add mode, non-null = edit mode

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _categoryController;

  String _selectedUnit = 'قطعة';
  bool _isSaving = false;
  bool _isScannerActive = false;

  static const List<String> _unitOptions = ['قطعة', 'كيلو', 'علبة', 'كرتونة', 'لتر', 'متر'];

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _quantityController = TextEditingController(text: p != null ? p.quantity.toString() : '');
    _minQuantityController = TextEditingController(text: p != null ? p.minQuantity.toString() : '5');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _selectedUnit = p?.unit ?? 'قطعة';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditMode ? 'تعديل منتج' : 'إضافة منتج',
          style: const TextStyle(
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
      ),
      body: Stack(
        children: [
          _buildForm(),
          if (_isScannerActive) _buildBarcodeScanner(),
        ],
      ),
    );
  }

  // ─── Form ───

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Name ───
          _buildLabel('اسم المنتج'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'مثال: ماء معدني 0.5 لتر',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'اسم المنتج مطلوب';
              if (v.trim().length < 2) return 'الاسم قصير جداً';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ─── Barcode ───
          _buildLabel('الباركود'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _barcodeController,
                  hint: 'أدخل الباركود يدوًا',
                  keyboardType: TextInputType.number,
                  validator: null, // barcode is optional
                ),
              ),
              const SizedBox(width: 12),
              _buildScanButton(),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Price ───
          _buildLabel('السعر (ج.م)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _priceController,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'السعر مطلوب';
              final price = double.tryParse(v.trim());
              if (price == null) return 'رقم غير صحيح';
              if (price < 0) return 'السعر لا يمكن أن يكون سالب';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ─── Quantity + Min Quantity ───
          Row(
            children: [
              Expanded(child: _buildQuantityField('الكمية', _quantityController, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                final qty = int.tryParse(v.trim());
                if (qty == null) return 'رقم غير صحيح';
                if (qty < 0) return 'لا يمكن أن يكون سالب';
                return null;
              })),
              const SizedBox(width: 16),
              Expanded(child: _buildQuantityField('الحد الأدنى', _minQuantityController, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                final qty = int.tryParse(v.trim());
                if (qty == null) return 'رقم غير صحيح';
                if (qty < 0) return 'لا يمكن أن يكون سالب';
                return null;
              })),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Category ───
          _buildLabel('الفئة'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _categoryController,
            hint: 'مثال: مشروبات، طعام، منظفات...',
            validator: null, // optional
          ),
          const SizedBox(height: 20),

          // ─── Unit Chips ───
          _buildLabel('وحدة القياس'),
          const SizedBox(height: 8),
          _buildUnitChips(),
          const SizedBox(height: 36),

          // ─── Save Button ───
          _buildSaveButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Label ───

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.inkLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Text Field — underline style ───

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.stampRed, width: 1),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.stampRed, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.stampRed, fontSize: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildQuantityField(
    String label,
    TextEditingController controller, {
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        _buildTextField(
          controller: controller,
          hint: '0',
          keyboardType: TextInputType.number,
          validator: validator,
        ),
      ],
    );
  }

  // ─── Unit Chips ───

  Widget _buildUnitChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: _unitOptions.map((unit) {
        final isSelected = _selectedUnit == unit;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedUnit = unit);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.forest.withValues(alpha: 0.1) : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.forest : AppColors.ledgerBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              unit,
              style: TextStyle(
                color: isSelected ? AppColors.forest : AppColors.inkLight,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Barcode Scan Button ───

  Widget _buildScanButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sepia.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sepia.withValues(alpha: 0.4), width: 1),
      ),
      child: IconButton(
        icon: const Icon(Icons.qr_code_scanner, color: AppColors.sepia, size: 26),
        onPressed: () {
          HapticFeedback.lightImpact();
          setState(() => _isScannerActive = true);
        },
      ),
    );
  }

  // ─── Barcode Scanner Overlay ───

  Widget _buildBarcodeScanner() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final value = barcodes.first.rawValue;
                if (value != null) {
                  _barcodeController.text = value;
                  HapticFeedback.mediumImpact();
                  setState(() => _isScannerActive = false);
                }
              }
            },
          ),
          // ─── Scan Frame Overlay ───
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.forest, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // ─── Close Button ───
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surface,
              onPressed: () => setState(() => _isScannerActive = false),
              child: const Icon(Icons.close, color: AppColors.ink),
            ),
          ),
          // ─── Hint ───
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'وجّه الكاميرا نحو الباركود',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Save Button — flat forest green with border (stamp style) ───

  Widget _buildSaveButton() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return GestureDetector(
          onTapDown: (_) => setLocalState(() {}),
          onTapUp: (_) => setLocalState(() {}),
          onTapCancel: () => setLocalState(() {}),
          onTap: _isSaving ? null : () => _saveProduct(),
          child: AnimatedScale(
            scale: _isSaving ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.forestDark, width: 1),
              ),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.background,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditMode ? Icons.check : Icons.add,
                            color: AppColors.background,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditMode ? 'حفظ التعديلات' : 'إضافة المنتج',
                            style: const TextStyle(
                              color: AppColors.background,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Save Logic ───

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        final updated = Product(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          cost: widget.product!.cost,
          quantity: int.parse(_quantityController.text.trim()),
          minQuantity: int.parse(_minQuantityController.text.trim()),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          unit: _selectedUnit,
          imagePath: widget.product!.imagePath,
          createdAt: widget.product!.createdAt,
          updatedAt: DateTime.now(),
        );

        await ref.read(editProductUseCaseProvider).call(updated);

        // Log activity
        final dao = ref.read(activityLogDaoProvider);
        await dao.insertLog(
          db.ActivityLogCompanion(
            action: const drift.Value('edit_product'),
            entityType: const drift.Value('product'),
            entityId: drift.Value(widget.product!.id),
            details: drift.Value('تم تعديل المنتج: ${updated.name}'),
          ),
        );

        if (mounted) Navigator.of(context).pop(true);
      } else {
        final now = DateTime.now();
        final product = Product(
          id: 0, // auto-increment
          name: _nameController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          cost: null,
          quantity: int.parse(_quantityController.text.trim()),
          minQuantity: int.parse(_minQuantityController.text.trim()),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          unit: _selectedUnit,
          imagePath: null,
          createdAt: now,
          updatedAt: now,
        );

        final newId = await ref.read(addProductUseCaseProvider).call(product);

        // Log activity
        final dao = ref.read(activityLogDaoProvider);
        await dao.insertLog(
          db.ActivityLogCompanion(
            action: const drift.Value('add_product'),
            entityType: const drift.Value('product'),
            entityId: drift.Value(newId),
            details: drift.Value('تم إضافة منتج جديد: ${product.name}'),
          ),
        );

        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: AppColors.stampRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
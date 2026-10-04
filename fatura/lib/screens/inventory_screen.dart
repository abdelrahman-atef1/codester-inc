/// inventory_screen.dart — Bold Executive Inventory Screen
///
/// Replicates stitch-designs/03-inventory.html:
///   Dark slate app bar "المخزون" + stats, search bar, category chips,
///   product cards with stock badges, FAB "إضافة منتج", bottom nav.
///
/// Colors: #E63946 (red), #2A9D8F (teal), #F1F5F9 (bg), #1E293B (dark)
/// Font: Cairo (bold weights for headers)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/bold_colors.dart';
import '../../widgets/bold_search_bar.dart';
import '../../widgets/bold_filter_chips.dart';
import '../../widgets/bold_bottom_nav.dart';

/// Converts Latin digits in [input] to Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩),
/// the decimal separator to the Arabic decimal mark (٫), and thousands
/// separators to the Arabic thousands separator (٬).
String toArabicDigits(String input) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var result = input;
  for (var i = 0; i < western.length; i++) {
    result = result.replaceAll(western[i], arabic[i]);
  }
  return result.replaceAll('.', '٫').replaceAll(',', '٬');
}

/// Product model for UI display (from HTML design)
class InventoryProduct {
  final String name;
  final String category;
  final String barcode;
  final double price;
  final int stock;
  final int minStock;
  final IconData icon;
  final bool isLowStock;
  final bool isOutOfStock;

  const InventoryProduct({
    required this.name,
    required this.category,
    required this.barcode,
    required this.price,
    required this.stock,
    this.minStock = 0,
    this.icon = Icons.inventory_2,
    this.isLowStock = false,
    this.isOutOfStock = false,
  });
}

/// Category filter model
class CategoryChip {
  final String label;
  final bool isActive;
  final bool isAlert;
  final int? alertCount;

  const CategoryChip({
    required this.label,
    this.isActive = false,
    this.isAlert = false,
    this.alertCount,
  });
}

/// Main Inventory Screen
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';

  // Sample products matching HTML design
  final List<InventoryProduct> _products = [
    const InventoryProduct(
      name: 'حليب جهينة ١ لتر',
      category: 'ألبان',
      barcode: '٦٢٢١٠١٢٣٤٥',
      price: 35.00,
      stock: 48,
      minStock: 10,
      icon: Icons.local_drink,
    ),
    const InventoryProduct(
      name: 'أرز الضحى ١ كجم',
      category: 'معلبات وجاف',
      barcode: '٦٢٢٣٠٠١٩٨٧',
      price: 32.50,
      stock: 3,
      minStock: 5,
      isLowStock: true,
    ),
    const InventoryProduct(
      name: 'شاي العروسة ٢٥٠ جم',
      category: 'مشروبات',
      barcode: '٦٢٢٤٠٠٥٦١٢',
      price: 45.00,
      stock: 95,
      minStock: 10,
      icon: Icons.inventory_2,
    ),
    const InventoryProduct(
      name: 'زيت كريستال ذرة ١ لتر',
      category: 'زيوت',
      barcode: '٦٢٢١١٨٩٠٤١',
      price: 65.00,
      stock: 4,
      minStock: 5,
      isLowStock: true,
    ),
    const InventoryProduct(
      name: 'بيبسي كانز ٣٣٠ مل',
      category: 'مشروبات',
      barcode: '٦٢٢١٠٥٦٧٨٩',
      price: 12.00,
      stock: 120,
      minStock: 20,
      icon: Icons.local_drink,
    ),
    const InventoryProduct(
      name: 'صابون لوكس ٨٥ جم',
      category: 'منظفات',
      barcode: '٦٢٢٩٨١٤٣٢١',
      price: 18.00,
      stock: 0,
      minStock: 10,
      isOutOfStock: true,
    ),
  ];

  List<InventoryProduct> get _filteredProducts {
    if (_selectedCategory == 'الكل') return _products;
    if (_selectedCategory == 'منخفض المخزون') {
      return _products.where((p) => p.isLowStock || p.isOutOfStock).toList();
    }
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  List<CategoryChip> get _categories {
    final lowStockCount = _products.where((p) => p.isLowStock || p.isOutOfStock).length;
    return [
      const CategoryChip(label: 'الكل', isActive: true),
      CategoryChip(
        label: 'منخفض المخزون',
        isAlert: true,
        alertCount: lowStockCount,
      ),
      const CategoryChip(label: 'مشروبات'),
      const CategoryChip(label: 'ألبان'),
      const CategoryChip(label: 'معلبات'),
      const CategoryChip(label: 'منظفات'),
      const CategoryChip(label: 'مخبوزات'),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _products.where((p) => p.isLowStock || p.isOutOfStock).length;
    final totalProducts = _products.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BoldColors.bg,
        body: Column(
          children: [
            // ─── Dark App Bar ───
            _buildAppBar(totalProducts, lowStockCount),
            // ─── Search & Filter Bar ───
            _buildSearchAndFilters(),
            // ─── Product List ───
            Expanded(
              child: _buildProductList(),
            ),
          ],
        ),
        // ─── Floating Action Button ───
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        // ─── Bottom Navigation ───
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildAppBar(int totalProducts, int lowStockCount) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: BoldColors.dark,
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Inventory icon box
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: BoldColors.textFaint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'المخزون',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${toArabicDigits('$totalProducts')} منتج',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: BoldColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              // Low stock indicator
              Text(
                '${toArabicDigits('$lowStockCount')} منخفض المخزون',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BoldColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              // Filter button
              _AppBarIconButton(
                icon: Icons.tune,
                onTap: () {
                  // TODO: Filter & sort dialog
                },
              ),
              const SizedBox(width: 4),
              // Barcode scanner button
              _AppBarIconButton(
                icon: Icons.barcode_reader,
                onTap: () {
                  // TODO: Open barcode scanner
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      decoration: const BoxDecoration(
        color: BoldColors.bg,
        border: Border(
          bottom: BorderSide(color: BoldColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BoldSearchBar(
              controller: _searchController,
              hint: 'ابحث بالاسم أو الباركود...',
              onChanged: (value) {
                setState(() {});
              },
              onScanTap: () {
                // TODO: Camera barcode scan
              },
            ),
          ),
          const SizedBox(height: 10),
          // Category chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BoldFilterChips(
              chips: _categories.map((cat) => FilterChipData(
                label: cat.label,
                isActive: cat.isActive || _selectedCategory == cat.label,
                isAlert: cat.isAlert,
                alertCount: cat.alertCount,
              )).toList(),
              onChipTap: (label) {
                setState(() {
                  _selectedCategory = label;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final products = _filteredProducts.where((p) {
      if (_searchController.text.isEmpty) return true;
      final query = _searchController.text.toLowerCase();
      return p.name.contains(query) || p.barcode.contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(InventoryProduct product) {
    final isLow = product.isLowStock;
    final isOut = product.isOutOfStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOut
              ? BoldColors.redBorder
              : isLow
                  ? BoldColors.amberBorder
                  : BoldColors.border,
          width: 1,
        ),
        boxShadow: isOut || isLow
            ? [
                BoxShadow(
                  color: (isOut ? BoldColors.redBorder : BoldColors.amberBorder).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOut
                  ? BoldColors.redBg
                  : isLow
                      ? BoldColors.amberBg
                      : BoldColors.chipGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOut
                    ? BoldColors.redBorder
                    : isLow
                        ? BoldColors.amberBorder
                        : BoldColors.border,
                width: 1,
              ),
            ),
            child: Icon(
              product.icon,
              color: isOut
                  ? BoldColors.redText
                  : isLow
                      ? BoldColors.amberIcon
                      : BoldColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLow) ...[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: BoldColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BoldColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.category} · باركود ${product.barcode}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: BoldColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      toArabicDigits(product.price.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BoldColors.text,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ج.م',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BoldColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stock status + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Stock badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOut
                      ? BoldColors.redBg
                      : isLow
                          ? BoldColors.amberBg
                          : BoldColors.tealBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOut
                        ? BoldColors.redBorder
                        : isLow
                            ? BoldColors.amberBorder
                            : BoldColors.tealBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  isOut
                      ? 'نفذ المخزون (${toArabicDigits('${product.stock}')})'
                      : isLow
                          ? 'منخفض: ${toArabicDigits('${product.stock}')} متبقي'
                          : 'المخزون: ${toArabicDigits('${product.stock}')}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOut
                        ? BoldColors.redText
                        : isLow
                            ? BoldColors.amberText
                            : BoldColors.tealText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Action button
              GestureDetector(
                onTap: () {
                  // TODO: Edit product or request supply
                },
                child: Text(
                  isOut
                      ? 'إعادة تعبئة'
                      : isLow
                          ? 'طلب توريد'
                          : 'تعديل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isLow || isOut ? FontWeight.w700 : FontWeight.w500,
                    color: isLow || isOut ? BoldColors.primary : BoldColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 88),
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Add product screen
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('إضافة منتج'),
        style: ElevatedButton.styleFrom(
          backgroundColor: BoldColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BoldBottomNav(
      items: const [
        BoldNavItem(icon: Icons.point_of_sale, label: 'نقطة البيع'),
        BoldNavItem(icon: Icons.receipt_long, label: 'الفواتير'),
        BoldNavItem(icon: Icons.inventory_2, label: 'المخزون', isActive: true),
        BoldNavItem(icon: Icons.bar_chart, label: 'التقارير'),
      ],
      onTap: (index) {
        // TODO: Navigate to other screens
      },
    );
  }
}

/// App bar icon button helper
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: BoldColors.textFaint,
          size: 22,
        ),
      ),
    );
  }
}

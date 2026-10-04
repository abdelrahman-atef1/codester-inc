import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../providers/inventory_providers.dart';
import 'add_edit_product_screen.dart';
import 'product_detail_screen.dart';

/// T-007: Product List Screen — Paper Ledger style
/// Bordered cards (no shadows), ink text on cream, forest green accents.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'المخزون',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          _buildSearchBar(),
          // ─── Product List ───
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildProductList(products);
              },
              loading: () => _buildLoadingState(),
              error: (err, stack) => _buildErrorState(err),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── Search Bar ───

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.background,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم أو الباركود...',
          hintStyle: const TextStyle(color: AppColors.inkMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.forest, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.inkLight, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(productSearchProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : null,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
          ),
          focusedBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.forest, width: 2),
          ),
        ),
        onChanged: (value) {
          ref.read(productSearchProvider.notifier).state = value;
          setState(() {});
        },
      ),
    );
  }

  // ─── Product List ───

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _navigateToDetail(product.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
          ),
          child: Row(
            children: [
              // ─── Product Icon ───
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ledgerBorder, width: 1),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.forest,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // ─── Product Info ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الكمية: ${product.quantity} ${product.unit}',
                          style: TextStyle(
                            color: AppColors.inkLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // ─── Stock Status Badge ───
              _buildStockBadge(product.stockStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(ProductStockStatus status) {
    final (color, bg) = switch (status) {
      ProductStockStatus.inStock => (AppColors.forest, AppColors.forest.withValues(alpha: 0.12)),
      ProductStockStatus.lowStock => (AppColors.ochre, AppColors.ochre.withValues(alpha: 0.12)),
      ProductStockStatus.outOfStock => (AppColors.stampRed, AppColors.stampRed.withValues(alpha: 0.12)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Empty State ───

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد منتجات',
            style: TextStyle(
              color: AppColors.inkLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف أول منتج',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('إضافة منتج'),
          ),
        ],
      ),
    );
  }

  // ─── Loading ───

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.forest),
    );
  }

  // ─── Error ───

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.stampRed),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ: $err',
            style: const TextStyle(color: AppColors.inkLight, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.invalidate(productListProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // ─── FAB ───

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _navigateToAdd(),
      backgroundColor: AppColors.forest,
      foregroundColor: AppColors.background,
      elevation: 2,
      child: const Icon(Icons.add, size: 28),
    );
  }

  // ─── Navigation ───

  void _navigateToAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
    ref.invalidate(productListProvider);
  }

  void _navigateToDetail(int productId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
    ref.invalidate(productListProvider);
  }
}
/// pos_screen.dart — Full Point of Sale screen
///
/// Phase 2: T-011 (Product search + add), T-012 (Cart + totals), T-013 (Payment + checkout)
///
/// Layout: Two-panel (product grid | cart) on tablet, stacked on mobile.
/// Features:
/// - Search bar for products (T-011)
/// - Barcode scan button (mobile_scanner) (T-011)
/// - Cart: add/remove/quantity (T-012)
/// - Subtotal + tax + total with count-up animation (T-012)
/// - Payment method: cash/card/wallet (T-013)
/// - Change calculation (T-013)
/// - Checkout → Drift transaction + success animation
/// - RTL throughout
///
/// Paper Ledger: cream paper, ink borders, stamp red POS accents, forest green totals.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../domain/payment_method.dart';
import '../../providers/pos_providers.dart';
import '../../../inventory/providers/inventory_providers.dart'
    show productsDaoProvider;
import '../widgets/animated_total.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/payment_selector.dart';
import '../widgets/success_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  bool _isScannerOpen = false;

  @override
  void initState() {
    super.initState();
    // Load store settings → update tax
    ref.listenManual(currentStoreProvider, (previous, asyncValue) {
      asyncValue.whenData((store) {
        if (store != null) {
          ref.read(cartProvider.notifier).updateTaxSettings(
                enabled: store.taxEnabled,
                rate: store.taxRate,
              );
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Open barcode scanner overlay
  void _openScanner() {
    if (_isScannerOpen) return;
    _isScannerOpen = true;

    Navigator.of(context)
        .push<BarcodeCapture>(
      MaterialPageRoute(
        builder: (context) => const _BarcodeScannerScreen(),
        fullscreenDialog: true,
      ),
    )
        .then((capture) {
      _isScannerOpen = false;
      if (capture != null) {
        final barcode = capture.barcodes.firstOrNull?.rawValue;
        if (barcode != null && barcode.isNotEmpty) {
          _handleBarcode(barcode);
        }
      }
    });
  }

  /// Handle scanned barcode — find product and add to cart
  void _handleBarcode(String barcode) async {
    final productsDao = ref.read(productsDaoProvider);
    final product = await productsDao.getProductByBarcode(barcode);

    if (product != null) {
      _addToCart(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة: ${product.name}'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.productNotFound),
            action: SnackBarAction(
              label: 'إضافة',
              onPressed: () {
                // Navigate to add product with barcode pre-filled
                // TODO: implement when inventory add screen accepts initial barcode
              },
            ),
          ),
        );
      }
    }
  }

  /// Add product to cart with haptic feedback
  void _addToCart(db.Product product) {
    HapticFeedback.lightImpact();
    ref.read(cartProvider.notifier).addProduct(product);
  }

  /// Execute checkout
  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    final payment = ref.read(paymentProvider);
    final storeAsync = ref.read(currentStoreProvider);

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة')),
      );
      return;
    }

    if (!payment.isMethodSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر طريقة الدفع')),
      );
      return;
    }

    // For cash, verify amount paid
    if (payment.method == PaymentMethod.cash &&
        payment.amountPaid > 0 &&
        payment.amountPaid < cart.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ المدفوع غير كافٍ')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final store = storeAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );

    final result = await ref.read(invoiceCreationProvider.notifier).checkout(
          cart: cart,
          payment: payment,
          storeId: store?.id,
        );

    if (result.success && mounted) {
      // Show success animation
      SuccessDialog.show(
        context,
        invoiceNumber: result.invoiceNumber!,
        total: result.total!,
        change: result.change ?? 0,
        onNewSale: () {
          Navigator.of(context).pop();
          ref.read(cartProvider.notifier).clear();
          ref.read(paymentProvider.notifier).reset();
        },
      );
    } else if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'فشل إتمام البيع')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final payment = ref.watch(paymentProvider);
    final productsAsync = ref.watch(posProductsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= AppSizes.tabletBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.quickSale),
        centerTitle: false,
        actions: [
          // Cart badge
          if (cart.itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.paddingSM),
              child: Center(
                child: _CartBadge(count: cart.itemCount),
              ),
            ),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(productsAsync, cart, payment)
          : _buildMobileLayout(productsAsync, cart, payment),
    );
  }

  // ─── Tablet: side-by-side ───
  Widget _buildTabletLayout(
    AsyncValue<List<db.Product>> productsAsync,
    CartState cart,
    PaymentState payment,
  ) {
    return Row(
      children: [
        // Left: products
        Expanded(
          flex: 3,
          child: _ProductPanel(
            productsAsync: productsAsync,
            searchController: _searchController,
            onSearch: (query) =>
                ref.read(posSearchProvider.notifier).state = query,
            onScan: _openScanner,
            onProductTap: _addToCart,
          ),
        ),
        // Right: cart + checkout
        Expanded(
          flex: 2,
          child: _CartPanel(
            cart: cart,
            payment: payment,
            onIncrement: (id) =>
                ref.read(cartProvider.notifier).incrementQuantity(id),
            onDecrement: (id) =>
                ref.read(cartProvider.notifier).decrementQuantity(id),
            onRemove: (id) =>
                ref.read(cartProvider.notifier).removeItem(id),
            onMethodSelected: (method) =>
                ref.read(paymentProvider.notifier).selectMethod(method),
            onAmountPaidChanged: (amount) =>
                ref.read(paymentProvider.notifier).setAmountPaid(amount),
            onCheckout: _checkout,
          ),
        ),
      ],
    );
  }

  // ─── Mobile: stacked with cart as bottom sheet ───
  Widget _buildMobileLayout(
    AsyncValue<List<db.Product>> productsAsync,
    CartState cart,
    PaymentState payment,
  ) {
    return Column(
      children: [
        // Search bar
        _SearchBar(
          controller: _searchController,
          onChanged: (query) =>
              ref.read(posSearchProvider.notifier).state = query,
          onScan: _openScanner,
        ),

        // Product grid
        Expanded(
          child: _ProductPanel(
            productsAsync: productsAsync,
            searchController: _searchController,
            onSearch: (query) =>
                ref.read(posSearchProvider.notifier).state = query,
            onScan: _openScanner,
            onProductTap: _addToCart,
            isMobile: true,
          ),
        ),

        // Cart button (floating bar at bottom)
        if (cart.itemCount > 0)
          _CartBar(
            itemCount: cart.itemCount,
            total: cart.total,
            onTap: () => _showCartSheet(cart, payment),
          ),
      ],
    );
  }

  /// Show cart as bottom sheet on mobile
  void _showCartSheet(CartState cart, PaymentState payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLG),
        ),
        side: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CartSheetContent(
          cart: cart,
          payment: payment,
          scrollController: scrollController,
          onIncrement: (id) =>
              ref.read(cartProvider.notifier).incrementQuantity(id),
          onDecrement: (id) =>
              ref.read(cartProvider.notifier).decrementQuantity(id),
          onRemove: (id) =>
              ref.read(cartProvider.notifier).removeItem(id),
          onMethodSelected: (method) =>
              ref.read(paymentProvider.notifier).selectMethod(method),
          onAmountPaidChanged: (amount) =>
              ref.read(paymentProvider.notifier).setAmountPaid(amount),
          onCheckout: () {
            Navigator.of(context).pop();
            _checkout();
          },
        ),
      ),
    );
  }
}

// ─── Product Panel ───

class _ProductPanel extends StatelessWidget {
  final AsyncValue<List<db.Product>> productsAsync;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onScan;
  final ValueChanged<db.Product> onProductTap;
  final bool isMobile;

  const _ProductPanel({
    required this.productsAsync,
    required this.searchController,
    required this.onSearch,
    required this.onScan,
    required this.onProductTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isMobile) const SizedBox.shrink() else _SearchBar(
          controller: searchController,
          onChanged: onSearch,
          onScan: onScan,
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.stampRed),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    err.toString(),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'لا توجد منتجات'
                            '${searchController.text.isNotEmpty
                                ? ' لبحثك "${searchController.text}"'
                                : ''}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontLG,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingSM),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: AppSizes.sm,
                  mainAxisSpacing: AppSizes.sm,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductCard(
                    product: product,
                    onTap: () => onProductTap(product),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final db.Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stockStatus = product.quantity <= 0
        ? 'نفد'
        : product.quantity <= product.minQuantity
            ? 'منخفض'
            : 'متاح';

    final stockColor = product.quantity <= 0
        ? AppColors.stampRed
        : product.quantity <= product.minQuantity
            ? AppColors.ochre
            : AppColors.forest;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingSM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Product icon placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    border: Border.all(
                        color: AppColors.ledgerBorder, width: 1),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.inkMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                // Product name
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                // Price
                Text(
                  '${product.price.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                // Stock badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    border:
                        Border.all(color: stockColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$stockStatus (${product.quantity})',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.paddingSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: AppStrings.search,
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.inkMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.inkMuted,
                  size: 20,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSM,
                  vertical: AppSizes.paddingSM,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: const BorderSide(
                      color: AppColors.ledgerBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: const BorderSide(
                      color: AppColors.ledgerBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: const BorderSide(
                      color: AppColors.forest, width: 2),
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Barcode scan button
          GestureDetector(
            onTap: onScan,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                border: Border.all(color: AppColors.forestDark, width: 1.5),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.background,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart Badge (animated count bump) ───

class _CartBadge extends StatefulWidget {
  final int count;

  const _CartBadge({required this.count});

  @override
  State<_CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends State<_CartBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_CartBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.stampRed,
          borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
          border: Border.all(color: AppColors.stampRedDark, width: 1),
        ),
        child: Text(
          '${widget.count}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontXS,
            fontWeight: FontWeight.w700,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }
}

// ─── Cart Bar (mobile floating bar) ───

class _CartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const _CartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.paddingSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.forest,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(color: AppColors.forestDark, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shopping_cart,
                  color: AppColors.background,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  '$itemCount صنف',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
            AnimatedTotal(
              value: total,
              isLarge: false,
              valueStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontLG,
                fontWeight: FontWeight.w800,
                color: AppColors.background,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_up,
              color: AppColors.background,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart Panel (tablet side panel) ───

class _CartPanel extends StatelessWidget {
  final CartState cart;
  final PaymentState payment;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onRemove;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final ValueChanged<double> onAmountPaidChanged;
  final VoidCallback onCheckout;

  const _CartPanel({
    required this.cart,
    required this.payment,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onMethodSelected,
    required this.onAmountPaidChanged,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.ledgerBorder, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: AppColors.forest, size: 20),
                SizedBox(width: AppSizes.sm),
                Text(
                  AppStrings.cart,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.paddingSM),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemCard(
                        cartItem: item,
                        onIncrement: () => onIncrement(item.product.id),
                        onDecrement: () => onDecrement(item.product.id),
                        onRemove: () => onRemove(item.product.id),
                      );
                    },
                  ),
          ),

          // Totals + Payment + Checkout
          if (!cart.isEmpty) _buildCheckoutSection(cart, payment),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.inkMuted),
          SizedBox(height: AppSizes.md),
          Text(
            AppStrings.emptyCart,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontLG,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CartState cart, PaymentState payment) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtotal
          _TotalRow(
            label: AppStrings.subtotal,
            value: cart.subtotal,
          ),
          const SizedBox(height: 4),

          // Tax (if enabled)
          if (cart.taxEnabled && cart.taxAmount > 0) ...[
            _TotalRow(
              label: '${AppStrings.tax} (${cart.taxRate.toStringAsFixed(0)}%)',
              value: cart.taxAmount,
              color: AppColors.ochre,
            ),
            const SizedBox(height: 4),
          ],

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.xs),
            child: Divider(color: AppColors.ledgerLine, thickness: 1),
          ),

          // Total (animated)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.total,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              AnimatedTotal(
                value: cart.total,
                isLarge: true,
              ),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // Payment selector
          PaymentSelector(
            selectedMethod: payment.method,
            amountPaid: payment.amountPaid,
            total: cart.total,
            onMethodSelected: onMethodSelected,
            onAmountPaidChanged: onAmountPaidChanged,
          ),

          const SizedBox(height: AppSizes.md),

          // Checkout button
          SizedBox(
            height: AppSizes.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(AppStrings.checkout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stampRed,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  side: const BorderSide(
                      color: AppColors.stampRedDark, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _TotalRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            color: AppColors.inkLight,
          ),
        ),
        AnimatedTotal(
          value: value,
          isLarge: false,
          valueStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── Cart Sheet Content (mobile bottom sheet) ───

class _CartSheetContent extends StatelessWidget {
  final CartState cart;
  final PaymentState payment;
  final ScrollController scrollController;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onRemove;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final ValueChanged<double> onAmountPaidChanged;
  final VoidCallback onCheckout;

  const _CartSheetContent({
    required this.cart,
    required this.payment,
    required this.scrollController,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onMethodSelected,
    required this.onAmountPaidChanged,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLG),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSizes.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.ledgerBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.cart,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${cart.uniqueCount} أصناف · ${cart.itemCount} قطع',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXS,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),

          // Cart items list
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      AppStrings.emptyCart,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontLG,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMD),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemCard(
                        cartItem: item,
                        onIncrement: () => onIncrement(item.product.id),
                        onDecrement: () => onDecrement(item.product.id),
                        onRemove: () => onRemove(item.product.id),
                      );
                    },
                  ),
          ),

          // Checkout section
          if (!cart.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TotalRow(label: AppStrings.subtotal, value: cart.subtotal),
                    if (cart.taxEnabled && cart.taxAmount > 0) ...[
                      const SizedBox(height: 4),
                      _TotalRow(
                        label:
                            '${AppStrings.tax} (${cart.taxRate.toStringAsFixed(0)}%)',
                        value: cart.taxAmount,
                        color: AppColors.ochre,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSizes.xs),
                      child:
                          Divider(color: AppColors.ledgerLine, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.total,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontLG,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        AnimatedTotal(value: cart.total, isLarge: true),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    PaymentSelector(
                      selectedMethod: payment.method,
                      amountPaid: payment.amountPaid,
                      total: cart.total,
                      onMethodSelected: onMethodSelected,
                      onAmountPaidChanged: onAmountPaidChanged,
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: onCheckout,
                        icon:
                            const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(AppStrings.checkout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.stampRed,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.buttonRadius),
                            side: const BorderSide(
                                color: AppColors.stampRedDark, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Barcode Scanner Screen ───

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: const Text(AppStrings.scanBarcode),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.background),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(capture);
              }
            },
          ),

          // Scan overlay
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.forest,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              ),
            ),
          ),

          // Scan line animation
          const _ScanLineAnimation(),

          // Instructions
          Positioned(
            bottom: AppSizes.xl,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'وجّه الكاميرا نحو الباركود',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontMD,
                  color: AppColors.background.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated scan line (top→bottom→top loop)
class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation();

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 280,
            height: 180,
            child: Stack(
              children: [
                Positioned(
                  top: _controller.value * 170,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: AppColors.forest,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
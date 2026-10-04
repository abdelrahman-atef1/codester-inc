/// pos_dashboard_screen.dart — نقطة البيع (Bold Executive design from Stitch)
///
/// RTL Arabic POS dashboard:
/// 1. Dark executive top bar (storefront, shop name, shift badge, cashier)
/// 2. Search + barcode scanner row with shift metrics strip
/// 3. Horizontal category chips ("الكل" active slate-900, others white)
/// 4. 3-column product grid with red cart-quantity badges
/// 5. Sticky dark cart panel (steppers, empty, discount, total, checkout CTA)
/// 6. Bottom navigation (نقطة البيع / الفواتير / المخزون / التقارير)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repository.dart' show CartLine;
import '../providers/pos_providers.dart';
import '../widgets/barcode_scanner_widget.dart';
import 'executive_theme.dart';

class PosDashboardScreen extends ConsumerWidget {
  const PosDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ExecutiveColors.background,
        body: Column(
          children: [
            const _TopBar(),
            const _SearchAndMetrics(),
            const _CategoryChips(),
            const Expanded(child: _ProductGrid()),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _CartPanel(),
            _BottomNav(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Top app bar — dark executive surface
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ExecutiveColors.slate800,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ExecutiveColors.slate700, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Storefront icon chip
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ExecutiveColors.slate700,
                border: Border.all(color: ExecutiveColors.slate600),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront,
                  color: ExecutiveColors.red, size: 24),
            ),
            const SizedBox(width: 10),
            // Shop name + date
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سوبر ماركت النور',
                    style: ExecutiveText.headline.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'السبت ٣ أكتوبر ٢٠٢٦',
                    style: ExecutiveText.label.copyWith(
                      color: ExecutiveColors.slate400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Shift badge + cashier name
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ExecutiveColors.emerald950.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: ExecutiveColors.emerald700.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: ExecutiveColors.emerald400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'وردية صباحية',
                        style: ExecutiveText.label.copyWith(
                          color: ExecutiveColors.emerald400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'أحمد محمود',
                  style: ExecutiveText.label.copyWith(
                    color: ExecutiveColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Cashier avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ExecutiveColors.slate700,
                    border: Border.all(color: ExecutiveColors.slate600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'أ.م',
                    style: ExecutiveText.title.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ExecutiveColors.emerald400,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: ExecutiveColors.slate800, width: 2),
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
}

// ---------------------------------------------------------------------------
// 2. Search + barcode + shift metrics strip
// ---------------------------------------------------------------------------

class _SearchAndMetrics extends ConsumerWidget {
  const _SearchAndMetrics();

  /// Launch the barcode scanner → look up the product by barcode → add to cart.
  Future<void> _onScanBarcode(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final code = await showBarcodeScanner(context);
    if (code == null || code.isEmpty) return;
    if (!context.mounted) return;

    final repo = ref.read(posRepositoryProvider);
    final matches = await repo.getProducts(query: code);
    final product = matches.isEmpty ? null : matches.first;
    if (product == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('لا يوجد منتج بالباركود: $code')),
      );
      return;
    }
    ref.read(cartProvider.notifier).addProduct(product);
    messenger.showSnackBar(
      SnackBar(content: Text('أُضيف ${product.name} إلى السلة')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(todayMetricsProvider).valueOrNull;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    key: const Key('pos_search_field'),
                    onChanged: (v) =>
                        ref.read(productSearchProvider.notifier).state = v,
                    style: ExecutiveText.body.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w400),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج أو امسح الباركود...',
                      hintStyle: ExecutiveText.label.copyWith(
                          fontSize: 14, fontWeight: FontWeight.w400),
                      prefixIcon: const Icon(Icons.search,
                          color: ExecutiveColors.slate400, size: 20),
                      filled: true,
                      fillColor: ExecutiveColors.slate100,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: ExecutiveColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: ExecutiveColors.red, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Barcode scanner button
              SizedBox(
                width: 44,
                height: 44,
                child: Material(
                  key: const Key('barcode_button'),
                  color: ExecutiveColors.red,
                  borderRadius: BorderRadius.circular(8),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _onScanBarcode(context, ref),
                    child: const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick metrics strip
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: ExecutiveColors.slate100, width: 1),
              ),
            ),
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _MetricCell(
                  label: 'مبيعات الوردية',
                  value:
                      '${(metrics?.salesTotal ?? 1840).toStringAsFixed(2)} ج.م',
                ),
                const SizedBox(width: 8),
                _MetricCell(
                  label: 'عدد الفواتير',
                  value: '${metrics?.invoiceCount ?? 24} فاتورة',
                ),
                const SizedBox(width: 8),
                const _MetricCell(
                  label: 'حالة الدرج',
                  value: 'متزن (طبيعي)',
                  valueColor: ExecutiveColors.emerald700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: ExecutiveColors.slate100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ExecutiveColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: ExecutiveText.label.copyWith(
                fontSize: 10,
                color: ExecutiveColors.muted,
              ),
            ),
            Text(
              value,
              style: ExecutiveText.tabular.copyWith(
                fontSize: 12,
                color: valueColor ?? ExecutiveColors.darkText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Category filter chips
// ---------------------------------------------------------------------------

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final selected = ref.watch(selectedCategoryProvider);

    return Container(
      color: ExecutiveColors.slate100.withValues(alpha: 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "الكل" chip
            _Chip(
              label: 'الكل',
              icon: Icons.apps,
              isActive: selected == null,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            for (final c in categories)
              _Chip(
                label: c.name,
                icon: _categoryIcon(c.icon),
                isActive: selected == c.id,
                onTap: () =>
                    ref.read(selectedCategoryProvider.notifier).state = c.id,
              ),
          ],
        ),
      ),
    );
  }

  static IconData _categoryIcon(String name) {
    switch (name) {
      case 'local_drink':
        return Icons.local_drink;
      case 'egg_alt':
        return Icons.egg_alt;
      case 'soup_kitchen':
        return Icons.soup_kitchen;
      case 'sanitizer':
        return Icons.sanitizer;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'cookie':
        return Icons.cookie;
      default:
        return Icons.category;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: isActive ? ExecutiveColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? null
                  : Border.all(color: ExecutiveColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? Colors.white
                      : ExecutiveColors.slate400,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: ExecutiveText.body.copyWith(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : ExecutiveColors.slate700,
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

// ---------------------------------------------------------------------------
// 4. Product grid (3 columns)
// ---------------------------------------------------------------------------

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final quantities = ref.watch(cartQuantitiesProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ExecutiveColors.red),
      ),
      error: (e, _) => Center(
        child: Text('خطأ: $e',
            style: ExecutiveText.body.copyWith(color: ExecutiveColors.red)),
      ),
      data: (products) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المنتجات السريعة (${products.length})',
                  style: ExecutiveText.title.copyWith(
                      fontSize: 12, color: ExecutiveColors.slate700),
                ),
                Text(
                  'الترتيب: الأكثر مبيعاً',
                  style: ExecutiveText.label.copyWith(
                      fontSize: 11, color: ExecutiveColors.slate500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final product = products[i];
                final qty = quantities[product.id] ?? 0;
                return _ProductTile(
                  product: product,
                  inCart: qty,
                  onTap: () =>
                      ref.read(cartProvider.notifier).addProduct(product),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.inCart,
    required this.onTap,
  });

  final Product product;
  final int inCart;
  final VoidCallback onTap;

  /// Per-tile accent colors matching the Stitch design (soft pastel bg +
  /// richer icon color), cycled by colorHue slot.
  static const _accents = <(Color bg, Color fg)>[
    (ExecutiveColors.slate100, ExecutiveColors.slate500),
    (Color(0xFFEFF6FF), Color(0xFF2563EB)), // blue
    (Color(0xFFFFFBEB), Color(0xFFB45309)), // amber
    (Color(0xFFFEF2F2), Color(0xFFDC2626)), // red
    (Color(0xFFECFDF5), Color(0xFF059669)), // emerald
    (Color(0xFFFEFCE8), Color(0xFFA16207)), // yellow
    (Color(0xFFFFF7ED), Color(0xFFEA580C)), // orange
    (Color(0xFFECFEFF), Color(0xFF0E7490)), // cyan
  ];

  static IconData _iconFor(String name) {
    switch (name) {
      case 'water_bottle':
        return Icons.water_drop;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'grain':
        return Icons.grain;
      case 'emoji_food_beverage':
        return Icons.emoji_food_beverage;
      case 'egg':
        return Icons.egg;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'opacity':
        return Icons.opacity;
      case 'ramen_dining':
        return Icons.ramen_dining;
      case 'set_meal':
        return Icons.set_meal;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accents[product.colorHue % _accents.length];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        key: Key('product_tile_${product.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ExecutiveColors.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon area
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.$1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(_iconFor(product.icon),
                        color: accent.$2, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: ExecutiveText.title.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.unit,
                          style: ExecutiveText.label.copyWith(
                              fontSize: 10, color: ExecutiveColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: product.price.toStringAsFixed(2),
                                  style: ExecutiveText.headline.copyWith(
                                      fontSize: 12),
                                ),
                                TextSpan(
                                  text: ' ج.م',
                                  style: ExecutiveText.label.copyWith(
                                      fontSize: 9,
                                      color: ExecutiveColors.slate500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // In-cart quantity badge (top-left in RTL start = left visually)
            if (inCart > 0)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  key: Key('cart_badge_${product.id}'),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: ExecutiveColors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 2),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$inCart',
                    style: ExecutiveText.title.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Sticky cart panel — dark surface
// ---------------------------------------------------------------------------

class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);

    return Container(
      color: ExecutiveColors.slate900,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Container(
            color: ExecutiveColors.slate800,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ExecutiveColors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${totals.itemCount}',
                    key: const Key('cart_count_badge'),
                    style: ExecutiveText.title.copyWith(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'السلة الجارية · ${totals.itemCount} أصناف',
                    style: ExecutiveText.title.copyWith(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                // Discount button
                _PanelAction(
                  key: const Key('discount_button'),
                  icon: Icons.percent,
                  label: 'خصم',
                  iconColor: ExecutiveColors.slate300,
                  labelColor: ExecutiveColors.slate300,
                  background: ExecutiveColors.slate700,
                  border: ExecutiveColors.slate600,
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                // Empty-cart button
                _PanelAction(
                  key: const Key('empty_cart_button'),
                  icon: Icons.delete_outline,
                  label: 'إفراغ',
                  iconColor: ExecutiveColors.red400,
                  labelColor: ExecutiveColors.red400,
                  background:
                      ExecutiveColors.red950.withValues(alpha: 0.4),
                  border: ExecutiveColors.red800.withValues(alpha: 0.6),
                  onTap: () => ref.read(cartProvider.notifier).clear(),
                ),
              ],
            ),
          ),
          // Cart lines (compact, scrollable up to ~2 rows)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 96),
            child: ListView.builder(
              shrinkWrap: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: lines.length,
              itemBuilder: (context, i) => _CartLineRow(
                line: lines[i],
              ),
            ),
          ),
          // Total + checkout
          Container(
            color: ExecutiveColors.slate950,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'الإجمالي المطلوب:',
                              style: ExecutiveText.label.copyWith(
                                  color: ExecutiveColors.slate400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(شامل ضريبة القيمة المضافة)',
                              style: ExecutiveText.label.copyWith(
                                  color: ExecutiveColors.emerald400,
                                  fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: totals.total.toStringAsFixed(2),
                            style: ExecutiveText.headline.copyWith(
                                color: Colors.white, fontSize: 18),
                          ),
                          TextSpan(
                            text: ' ج.م',
                            style: ExecutiveText.label.copyWith(
                                color: ExecutiveColors.slate300,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      key: const Key('cart_total'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('checkout_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ExecutiveColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: lines.isEmpty
                        ? null
                        : () async {
                            final id = await ref
                                .read(cartProvider.notifier)
                                .checkout();
                            ref
                                .read(lastInvoiceIdProvider.notifier)
                                .state = id;
                          },
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text(
                      'إتمام البيع وسداد الفاتورة (Enter)',
                      style: ExecutiveText.headline.copyWith(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 2),
            Text(
              label,
              style: ExecutiveText.label.copyWith(
                  color: labelColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineRow extends ConsumerWidget {
  const _CartLineRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ExecutiveColors.slate800, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Name + unit price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.product.name} ${line.product.unit}',
                  style: ExecutiveText.title.copyWith(
                      color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${line.quantity} × ${line.product.price.toStringAsFixed(2)} ج.م',
                  style: ExecutiveText.label.copyWith(
                      color: ExecutiveColors.slate400, fontSize: 10),
                ),
              ],
            ),
          ),
          // Stepper
          Container(
            decoration: BoxDecoration(
              color: ExecutiveColors.slate800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ExecutiveColors.slate700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperButton(
                  symbol: '−',
                  onTap: () => ref
                      .read(cartProvider.notifier)
                      .decrement(line.product.id),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${line.quantity}',
                    textAlign: TextAlign.center,
                    style: ExecutiveText.title.copyWith(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                _StepperButton(
                  symbol: '+',
                  onTap: () => ref
                      .read(cartProvider.notifier)
                      .increment(line.product.id),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Line total
          SizedBox(
            width: 64,
            child: Text(
              '${line.lineTotal.toStringAsFixed(2)} ج.م',
              textAlign: TextAlign.end,
              style: ExecutiveText.title.copyWith(
                  color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.symbol, required this.onTap});

  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Text(
            symbol,
            style: ExecutiveText.title.copyWith(
                color: ExecutiveColors.slate300, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Bottom navigation bar
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ExecutiveColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(
            icon: Icons.point_of_sale,
            label: 'نقطة البيع',
            isActive: true,
          ),
          _NavItem(icon: Icons.receipt_long, label: 'الفواتير'),
          _NavItem(icon: Icons.inventory_2, label: 'المخزون'),
          _NavItem(icon: Icons.bar_chart, label: 'التقارير'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? ExecutiveColors.red600 : ExecutiveColors.slate500;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: ExecutiveText.body.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

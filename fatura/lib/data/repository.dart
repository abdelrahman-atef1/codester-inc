/// repository.dart — Data access layer for the Bold Executive POS flow.
///
/// Wraps [PosDatabase] with product/category/invoice operations used by the
/// Stitch-designed screens (pos_dashboard_screen, invoice_screen).
library;

import 'package:drift/drift.dart';

import 'database.dart';

/// A cart line — product + quantity + line total.
class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartLine copyWith({Product? product, int? quantity}) => CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );
}

/// Aggregated totals for a set of cart lines.
class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.itemCount,
  });

  final double subtotal;
  final double tax;
  final double discount;
  final double total;

  /// Total quantity of units across all lines.
  final int itemCount;

  static const double vatRate = 0.14;

  factory CartTotals.compute(List<CartLine> lines, {double discount = 0}) {
    final subtotal = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final itemCount = lines.fold<int>(0, (sum, l) => sum + l.quantity);
    final tax = subtotal * vatRate;
    final total = subtotal + tax - discount;
    return CartTotals(
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      itemCount: itemCount,
    );
  }
}

/// A fully-assembled invoice: header + items.
class FullInvoice {
  const FullInvoice({required this.invoice, required this.items});

  final Invoice invoice;
  final List<InvoiceItem> items;
}

/// Repository over [PosDatabase].
class PosRepository {
  PosRepository(this._db);

  final PosDatabase _db;

  // ---------- Categories ----------

  Stream<List<Category>> watchCategories() =>
      (_db.select(_db.categories)
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<List<Category>> getCategories() =>
      (_db.select(_db.categories)
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      _db.into(_db.categories).insert(entry);

  // ---------- Products ----------

  Stream<List<Product>> watchProducts({int? categoryId, String? query}) {
    final sel = _db.select(_db.products);
    if (categoryId != null) {
      sel.where((p) => p.categoryId.equals(categoryId));
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      sel.where((p) => p.name.like('%$q%') | p.barcode.like('%$q%'));
    }
    sel.orderBy([(p) => OrderingTerm.asc(p.id)]);
    return sel.watch();
  }

  Future<List<Product>> getProducts({int? categoryId, String? query}) {
    final sel = _db.select(_db.products);
    if (categoryId != null) {
      sel.where((p) => p.categoryId.equals(categoryId));
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      sel.where((p) => p.name.like('%$q%') | p.barcode.like('%$q%'));
    }
    sel.orderBy([(p) => OrderingTerm.asc(p.id)]);
    return sel.get();
  }

  Future<Product?> getProductById(int id) =>
      (_db.select(_db.products)..where((p) => p.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertProduct(ProductsCompanion entry) =>
      _db.into(_db.products).insert(entry);

  // ---------- Invoices ----------

  /// Persist a completed invoice + its items in one transaction.
  /// Returns the new invoice row id.
  Future<int> createInvoice({
    required String invoiceNumber,
    required List<CartLine> lines,
    double discount = 0,
    String paymentMethod = 'cash',
    String? customerName,
    String status = 'paid',
  }) {
    final totals = CartTotals.compute(lines, discount: discount);
    return _db.transaction(() async {
      final invoiceId = await _db.into(_db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceNumber: invoiceNumber,
              customerName: Value(customerName),
              subtotal: totals.subtotal,
              tax: Value(totals.tax),
              discount: Value(totals.discount),
              total: totals.total,
              paymentMethod: Value(paymentMethod),
              status: Value(status),
            ),
          );
      for (final line in lines) {
        await _db.into(_db.invoiceItems).insert(
              InvoiceItemsCompanion.insert(
                invoiceId: invoiceId,
                productId: Value(line.product.id),
                name: line.product.name,
                subtitle: Value(line.product.unit),
                price: line.product.price,
                quantity: line.quantity,
                total: line.lineTotal,
              ),
            );
      }
      return invoiceId;
    });
  }

  Future<FullInvoice?> getInvoice(int id) async {
    final invoice = await (_db.select(_db.invoices)
          ..where((i) => i.id.equals(id)))
        .getSingleOrNull();
    if (invoice == null) return null;
    final items = await (_db.select(_db.invoiceItems)
          ..where((it) => it.invoiceId.equals(id))
          ..orderBy([(it) => OrderingTerm.asc(it.id)]))
        .get();
    return FullInvoice(invoice: invoice, items: items);
  }

  Stream<List<Invoice>> watchInvoices() => (_db.select(_db.invoices)
        ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
      .watch();

  /// Number of invoices created today (for the POS shift metrics bar).
  Future<int> todayInvoiceCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows = await (_db.select(_db.invoices)
          ..where((i) => i.createdAt.isBiggerOrEqualValue(startOfDay)))
        .get();
    return rows.length;
  }

  /// Sum of today's invoice totals (for the POS shift metrics bar).
  Future<double> todaySalesTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows = await (_db.select(_db.invoices)
          ..where((i) => i.createdAt.isBiggerOrEqualValue(startOfDay)))
        .get();
    return rows.fold<double>(0, (sum, i) => sum + i.total);
  }

  /// Sequential invoice number like INV-00248 based on row count.
  Future<String> nextInvoiceNumber() async {
    final count = await (_db.selectOnly(_db.invoices)
          ..addColumns([_db.invoices.id.count()]))
        .getSingle();
    final n = (count.read(_db.invoices.id.count()) ?? 0) + 1;
    return 'INV-${n.toString().padLeft(5, '0')}';
  }

  // ---------- Seed ----------

  /// Seed the dashboard demo data (categories + the 9 quick products from
  /// the Stitch design) if the products table is empty.
  Future<void> seedIfEmpty() async {
    final existing =
        await (_db.select(_db.products)..limit(1)).get();
    if (existing.isNotEmpty) return;

    await _db.transaction(() async {
      final drinks = await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: 'مشروبات', icon: const Value('local_drink'), sortOrder: const Value(1)));
      final dairy = await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: 'ألبان', icon: const Value('egg_alt'), sortOrder: const Value(2)));
      await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: 'معلبات', icon: const Value('soup_kitchen'), sortOrder: const Value(3)));
      await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: 'منظفات', icon: const Value('sanitizer'), sortOrder: const Value(4)));
      final bakery = await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: 'مخبوزات', icon: const Value('bakery_dining'), sortOrder: const Value(5)));
      await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: 'حلويات', icon: const Value('cookie'), sortOrder: const Value(6)));

      Future<void> add(String name, double price, String unit, String icon,
          int colorHue, int? categoryId) {
        return _db.into(_db.products).insert(ProductsCompanion.insert(
              name: name,
              price: price,
              unit: Value(unit),
              icon: Value(icon),
              colorHue: Value(colorHue),
              categoryId: Value(categoryId),
              quantity: const Value(50),
            ));
      }

      await add('حليب جهينة', 35.00, '١ لتر', 'water_bottle', 215, dairy);
      await add('بيبسي كانز', 12.00, '٣٣٠ مل', 'local_cafe', 217, drinks);
      await add('أرز الضحى', 42.50, '١ كجم', 'grain', 42, null);
      await add('شاي العروسة', 45.00, '٢٥٠ جم', 'emoji_food_beverage', 4, null);
      await add('جبنة دومتي', 28.00, '٥٠٠ جم', 'egg', 152, dairy);
      await add('عيش فينو', 15.00, 'كيس ٥ رغيف', 'lunch_dining', 54, bakery);
      await add('زيت عافية ذرة', 65.00, '٨٠٠ مل', 'opacity', 35, null);
      await add('مكرونة الملكة', 10.00, '٣٥٠ جم', 'ramen_dining', 26, null);
      await add('تونة صن شاين', 40.00, 'قطع ١٤٠ جم', 'set_meal', 190, null);
    });
  }
}

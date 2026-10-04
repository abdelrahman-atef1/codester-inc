/// pos_providers.dart — Riverpod providers for the Bold Executive POS flow.
///
/// State graph:
///   posDatabaseProvider  → singleton [PosDatabase]
///   posRepositoryProvider → [PosRepository]
///   categoriesProvider    → stream of [Category]
///   selectedCategoryProvider → currently-selected category chip (null = الكل)
///   productSearchProvider → current search text
///   productsProvider      → stream of [Product] filtered by category+search
///   cartProvider          → cart state (lines, add/remove/stepper/checkout)
///   todayMetricsProvider  → shift sales total + invoice count
///   invoiceProvider(id)   → assembled [FullInvoice] for the receipt screen
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repository.dart';

// ---------- Infrastructure ----------

final posDatabaseProvider = Provider<PosDatabase>((ref) {
  final db = PosDatabase();
  ref.onDispose(db.close);
  return db;
});

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return PosRepository(ref.watch(posDatabaseProvider));
});

// ---------- Categories ----------

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(posRepositoryProvider).watchCategories();
});

/// Currently-selected category id on the POS filter rail; null = "الكل".
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

// ---------- Product search ----------

final productSearchProvider = StateProvider<String>((ref) => '');

// ---------- Products ----------

final productsProvider = StreamProvider<List<Product>>((ref) {
  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(productSearchProvider);
  return ref
      .watch(posRepositoryProvider)
      .watchProducts(categoryId: categoryId, query: query);
});

// ---------- Cart ----------

/// Cart state: ordered list of [CartLine] keyed by product id.
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier(this._repo) : super(const []);

  final PosRepository _repo;

  /// Discount in EGP applied at checkout level.
  double discount = 0;

  /// Add one unit of [product] to the cart (or increment existing line).
  void addProduct(Product product) {
    final idx = state.indexWhere((l) => l.product.id == product.id);
    if (idx >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          i == idx ? state[i].copyWith(quantity: state[i].quantity + 1) : state[i],
      ];
    } else {
      state = [...state, CartLine(product: product, quantity: 1)];
    }
  }

  /// Decrement, or remove the line entirely when it reaches zero.
  void decrement(int productId) {
    final idx = state.indexWhere((l) => l.product.id == productId);
    if (idx < 0) return;
    final q = state[idx].quantity;
    if (q <= 1) {
      remove(productId);
    } else {
      state = [
        for (var i = 0; i < state.length; i++)
          i == idx ? state[i].copyWith(quantity: q - 1) : state[i],
      ];
    }
  }

  void increment(int productId) {
    final idx = state.indexWhere((l) => l.product.id == productId);
    if (idx < 0) return;
    final q = state[idx].quantity;
    state = [
      for (var i = 0; i < state.length; i++)
        i == idx ? state[i].copyWith(quantity: q + 1) : state[i],
    ];
  }

  void remove(int productId) {
    state = state.where((l) => l.product.id != productId).toList();
  }

  void clear() {
    discount = 0;
    state = const [];
  }

  /// Quantity currently in the cart for [productId] (0 when absent) —
  /// drives the red badge on POS grid tiles.
  int quantityOf(int productId) {
    final idx = state.indexWhere((l) => l.product.id == productId);
    return idx < 0 ? 0 : state[idx].quantity;
  }

  CartTotals get totals => CartTotals.compute(state, discount: discount);

  /// Persist the cart as a paid invoice. Returns the new invoice id.
  Future<int> checkout({String paymentMethod = 'cash'}) async {
    final number = await _repo.nextInvoiceNumber();
    final id = await _repo.createInvoice(
      invoiceNumber: number,
      lines: state,
      discount: discount,
      paymentMethod: paymentMethod,
    );
    clear();
    return id;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  return CartNotifier(ref.watch(posRepositoryProvider));
});

/// Derived totals for the cart panel (subtotal / VAT / total / item count).
final cartTotalsProvider = Provider<CartTotals>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).totals;
});

/// Quick lookup: productId → quantity in cart (for tile badges).
final cartQuantitiesProvider = Provider<Map<int, int>>((ref) {
  final lines = ref.watch(cartProvider);
  return {for (final l in lines) l.product.id: l.quantity};
});

// ---------- Shift metrics (header strip) ----------

class ShiftMetrics {
  const ShiftMetrics({required this.salesTotal, required this.invoiceCount});

  final double salesTotal;
  final int invoiceCount;
}

final todayMetricsProvider = FutureProvider<ShiftMetrics>((ref) async {
  final repo = ref.watch(posRepositoryProvider);
  // Re-run when a checkout completes (cart empties after persist).
  ref.watch(cartProvider);
  final total = await repo.todaySalesTotal();
  final count = await repo.todayInvoiceCount();
  return ShiftMetrics(salesTotal: total, invoiceCount: count);
});

// ---------- Invoice detail ----------

final invoiceProvider =
    FutureProvider.family<FullInvoice?, int>((ref, id) async {
  return ref.watch(posRepositoryProvider).getInvoice(id);
});

/// The most recently completed invoice id (set right after checkout so the
/// invoice screen can be shown without routing parameters).
final lastInvoiceIdProvider = StateProvider<int?>((ref) => null);

/// pos_providers.dart — Riverpod state management for POS feature
///
/// Contains:
/// - CartNotifier: add/remove/quantity/total
/// - PaymentNotifier: selected method + amount paid
/// - InvoiceCreationProvider: completes sale → Drift transaction
/// - Search providers for product lookup
///
/// Phase 2 — T-011, T-012, T-013
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart' as db;
import '../../../core/database/daos/invoices_dao.dart';
import '../../../core/database/daos/invoice_items_dao.dart';
import '../../../core/database/daos/stores_dao.dart';
import '../../../core/utils/formatters.dart';
import '../../inventory/providers/inventory_providers.dart'
    show appDatabaseProvider, productsDaoProvider, activityLogDaoProvider;
import '../domain/cart_item.dart';
import '../domain/payment_method.dart';

// ─── DAOs (re-export from inventory_providers where shared) ───

final invoicesDaoProvider = Provider<InvoicesDao>((ref) {
  return InvoicesDao(ref.watch(appDatabaseProvider));
});

final invoiceItemsDaoProvider = Provider<InvoiceItemsDao>((ref) {
  return InvoiceItemsDao(ref.watch(appDatabaseProvider));
});

final storesDaoProvider = Provider<StoresDao>((ref) {
  return StoresDao(ref.watch(appDatabaseProvider));
});

// ─── Cart State ───

/// Cart state holder
///
/// Immutable: items + tax settings from store.
class CartState {
  final List<CartItem> items;
  final double taxRate; // 0.0 = no tax
  final bool taxEnabled;

  const CartState({
    this.items = const [],
    this.taxRate = 0,
    this.taxEnabled = false,
  });

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);
  int get uniqueCount => items.length;

  double get subtotal => items.fold(0.0, (sum, e) => sum + e.lineTotal);

  double get taxAmount {
    if (!taxEnabled || taxRate <= 0) return 0;
    return subtotal * (taxRate / 100);
  }

  double get total => subtotal + taxAmount;

  CartState copyWith({
    List<CartItem>? items,
    double? taxRate,
    bool? taxEnabled,
  }) {
    return CartState(
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      taxEnabled: taxEnabled ?? this.taxEnabled,
    );
  }

  static const initial = CartState();
}

/// Cart notifier — manages cart items, quantities, tax settings
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.initial);

  /// Add product to cart (or increment if already there)
  void addProduct(db.Product product) {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == product.id);

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] =
          newItems[existingIndex].copyWith(quantity: newItems[existingIndex].quantity + 1);
    } else {
      newItems = [...state.items, CartItem(product: product, quantity: 1)];
    }

    state = state.copyWith(items: newItems);
  }

  /// Remove item entirely from cart
  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  /// Increment quantity
  void incrementQuantity(int productId) {
    final newItems = List<CartItem>.from(state.items);
    final index = newItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      newItems[index] = newItems[index].copyWith(quantity: newItems[index].quantity + 1);
      state = state.copyWith(items: newItems);
    }
  }

  /// Decrement quantity (removes if reaches 0)
  void decrementQuantity(int productId) {
    final newItems = List<CartItem>.from(state.items);
    final index = newItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final currentQty = newItems[index].quantity;
      if (currentQty <= 1) {
        newItems.removeAt(index);
      } else {
        newItems[index] = newItems[index].copyWith(quantity: currentQty - 1);
      }
      state = state.copyWith(items: newItems);
    }
  }

  /// Set exact quantity
  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final newItems = List<CartItem>.from(state.items);
    final index = newItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      newItems[index] = newItems[index].copyWith(quantity: quantity);
      state = state.copyWith(items: newItems);
    }
  }

  /// Update tax settings from store
  void updateTaxSettings({required bool enabled, required double rate}) {
    state = state.copyWith(taxEnabled: enabled, taxRate: rate);
  }

  /// Clear the cart
  void clear() {
    state = CartState.initial;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// ─── Payment State ───

class PaymentState {
  final PaymentMethod? method;
  final double amountPaid;

  const PaymentState({
    this.method,
    this.amountPaid = 0,
  });

  bool get isMethodSelected => method != null;

  /// Calculate change (only for cash)
  double calculateChange(double total) {
    if (amountPaid <= 0 || amountPaid < total) return 0;
    return amountPaid - total;
  }

  bool get isAmountSufficient => amountPaid > 0;

  PaymentState copyWith({
    PaymentMethod? method,
    double? amountPaid,
    bool clearMethod = false,
  }) {
    return PaymentState(
      method: clearMethod ? null : (method ?? this.method),
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  static const initial = PaymentState();
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState.initial);

  void selectMethod(PaymentMethod method) {
    state = state.copyWith(method: method);
  }

  void setAmountPaid(double amount) {
    state = state.copyWith(amountPaid: amount);
  }

  void reset() {
    state = PaymentState.initial;
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});

// ─── Product Search (POS local) ───

/// Search query for POS product grid
final posSearchProvider = StateProvider<String>((ref) => '');

/// Stream of products filtered by search query
final posProductsProvider = StreamProvider<List<db.Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  final query = ref.watch(posSearchProvider);

  if (query.isEmpty) {
    return dao.watchAllProducts();
  } else {
    // Drift searchProducts is Future-based; we use watchAllProducts and filter
    // to keep the stream reactive.
    return dao.watchAllProducts().map(
          (products) => products
              .where((p) =>
                  p.name.toLowerCase().contains(query.toLowerCase()) ||
                  (p.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false))
              .toList(),
        );
  }
});

// ─── Store Info (for tax settings) ───

/// Current store info (for tax rate, currency)
final currentStoreProvider = FutureProvider<db.Store?>((ref) async {
  final dao = ref.watch(storesDaoProvider);
  return dao.getFirstStore();
});

// ─── Invoice Creation ───

/// Result of a checkout operation
class CheckoutResult {
  final bool success;
  final String? invoiceNumber;
  final double? total;
  final double? change;
  final String? error;

  const CheckoutResult({
    required this.success,
    this.invoiceNumber,
    this.total,
    this.change,
    this.error,
  });

  const CheckoutResult.success({
    required this.invoiceNumber,
    required this.total,
    required this.change,
  })  : success = true,
        error = null;

  const CheckoutResult.failure(this.error)
      : success = false,
        invoiceNumber = null,
        total = null,
        change = null;
}

/// Invoice creation provider — completes the sale
///
/// 1. Generates invoice number
/// 2. Inserts invoice record
/// 3. Inserts invoice items
/// 4. Decrements product quantities
/// 5. Logs activity
class InvoiceCreationNotifier extends AsyncNotifier<CheckoutResult?> {
  InvoiceCreationNotifier();

  @override
  CheckoutResult? build() => null;

  /// Execute checkout
  Future<CheckoutResult> checkout({
    required CartState cart,
    required PaymentState payment,
    int? userId,
    int? storeId,
    String? customerName,
    String? customerPhone,
  }) async {
    if (cart.isEmpty) {
      return const CheckoutResult.failure('السلة فارغة');
    }
    if (!payment.isMethodSelected) {
      return const CheckoutResult.failure('اختر طريقة الدفع');
    }

    final invoicesDao = ref.read(invoicesDaoProvider);
    final invoiceItemsDao = ref.read(invoiceItemsDaoProvider);
    final productsDao = ref.read(productsDaoProvider);
    final activityLogDao = ref.read(activityLogDaoProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      // Generate invoice number
      final existingInvoices = await invoicesDao.getAllInvoices();
      final sequence = existingInvoices.length + 1;
      final invoiceNumber = Formatters.generateInvoiceNumber(sequence);

      final total = cart.total;
      final change = payment.calculateChange(total);

      // Use Drift transaction for atomicity
      await database.transaction(() async {
        // 1. Insert invoice
        final id = await invoicesDao.insertInvoice(
          db.InvoicesCompanion.insert(
            invoiceNumber: invoiceNumber,
            storeId: Value(storeId),
            userId: Value(userId),
            customerName: Value(customerName),
            customerPhone: Value(customerPhone),
            subtotal: cart.subtotal,
            tax: Value(cart.taxAmount),
            total: total,
            paymentMethod: Value(payment.method!.name),
            amountPaid: Value(payment.amountPaid > 0 ? payment.amountPaid : total),
            change: Value(change),
            status: const Value('completed'),
          ),
        );

        // 2. Insert invoice items
        final itemCompanions = cart.items.map((item) {
          return db.InvoiceItemsCompanion.insert(
            invoiceId: id,
            productId: Value(item.product.id),
            name: item.product.name,
            price: item.product.price,
            quantity: item.quantity,
            total: item.lineTotal,
          );
        }).toList();
        await invoiceItemsDao.insertItems(itemCompanions);

        // 3. Decrement product quantities
        for (final item in cart.items) {
          await productsDao.adjustQuantity(item.product.id, -item.quantity);
        }

        // 4. Log activity
        await activityLogDao.insertLog(
          db.ActivityLogCompanion.insert(
            userId: Value(userId),
            action: 'sale',
            entityType: const Value('invoice'),
            entityId: Value(id),
            details: Value('فاتورة $invoiceNumber - ${total.toStringAsFixed(2)}'),
          ),
        );

        return id;
      });

      final result = CheckoutResult.success(
        invoiceNumber: invoiceNumber,
        total: total,
        change: change,
      );

      state = AsyncData(result);
      return result;
    } catch (e) {
      return CheckoutResult.failure('فشل إتمام البيع: ${e.toString()}');
    }
  }
}

final invoiceCreationProvider =
    AsyncNotifierProvider<InvoiceCreationNotifier, CheckoutResult?>(
  InvoiceCreationNotifier.new,
);
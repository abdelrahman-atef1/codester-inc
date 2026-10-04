/// cart_item.dart — Cart line-item model for POS
///
/// Wraps a Product with cart-specific state (quantity, line total).
/// Immutable value object — copies on change.
library;

import '../../../../core/database/database.dart' as db;

class CartItem {
  final db.Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  /// Line total = price × quantity
  double get lineTotal => product.price * quantity;

  CartItem copyWith({db.Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && product.id == other.product.id;

  @override
  int get hashCode => product.id;

  @override
  String toString() => 'CartItem(${product.name} ×$quantity = ${lineTotal.toStringAsFixed(2)})';
}
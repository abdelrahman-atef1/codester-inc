import 'package:equatable/equatable.dart';

/// Product entity — domain model for inventory
/// Maps to the `products` Drift table but is persistence-agnostic.
class Product extends Equatable {
  final int id;
  final String name;
  final String? barcode;
  final double price;
  final double? cost;
  final int quantity;
  final int minQuantity;
  final String? category;
  final String unit;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.barcode,
    required this.price,
    this.cost,
    required this.quantity,
    required this.minQuantity,
    this.category,
    required this.unit,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stock status derived from quantity vs minQuantity
  ProductStockStatus get stockStatus {
    if (quantity <= 0) return ProductStockStatus.outOfStock;
    if (quantity <= minQuantity) return ProductStockStatus.lowStock;
    return ProductStockStatus.inStock;
  }

  /// Whether this product needs reorder
  bool get needsReorder => quantity <= minQuantity;

  @override
  List<Object?> get props => [
        id, name, barcode, price, cost, quantity,
        minQuantity, category, unit, imagePath, createdAt, updatedAt,
      ];
}

/// Stock status enum for UI color indicators
enum ProductStockStatus {
  inStock,    // متاح
  lowStock,   // منخفض
  outOfStock, // نفد
}

extension ProductStockStatusX on ProductStockStatus {
  String get label {
    switch (this) {
      case ProductStockStatus.inStock: return 'متاح';
      case ProductStockStatus.lowStock: return 'منخفض';
      case ProductStockStatus.outOfStock: return 'نفد';
    }
  }
}
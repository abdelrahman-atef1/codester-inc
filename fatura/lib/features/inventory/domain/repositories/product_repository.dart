import '../entities/product.dart';

/// Repository interface for inventory (products)
/// Implementations: DriftInventoryRepository in data layer
abstract class ProductRepository {
  /// Watch all products (reactive stream)
  Stream<List<Product>> watchAll();

  /// Search products by name or barcode
  Stream<List<Product>> search(String query);

  /// Get a single product by ID
  Stream<Product> watchById(int id);

  /// Get a single product by ID (one-shot)
  Future<Product> getById(int id);

  /// Add a new product
  Future<int> add(Product product);

  /// Edit an existing product
  Future<bool> edit(Product product);

  /// Delete a product by ID
  Future<int> delete(int id);
}
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case: Get all products (reactive stream)
class GetProducts {
  final ProductRepository repository;
  GetProducts(this.repository);

  Stream<List<Product>> call() => repository.watchAll();

  /// Search products
  Stream<List<Product>> search(String query) => repository.search(query);
}
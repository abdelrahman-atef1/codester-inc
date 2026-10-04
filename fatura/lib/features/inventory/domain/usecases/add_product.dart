import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case: Add a new product to inventory
class AddProduct {
  final ProductRepository repository;
  AddProduct(this.repository);

  Future<int> call(Product product) {
    return repository.add(product);
  }
}
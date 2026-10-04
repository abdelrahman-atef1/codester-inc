import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case: Edit an existing product
class EditProduct {
  final ProductRepository repository;
  EditProduct(this.repository);

  Future<bool> call(Product product) {
    return repository.edit(product);
  }
}
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case: Get a single product by ID
class GetProductById {
  final ProductRepository repository;
  GetProductById(this.repository);

  Stream<Product> watch(int id) => repository.watchById(id);

  Future<Product> call(int id) => repository.getById(id);
}
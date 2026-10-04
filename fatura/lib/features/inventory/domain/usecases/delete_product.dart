import '../repositories/product_repository.dart';

/// Use case: Delete a product by ID
class DeleteProduct {
  final ProductRepository repository;
  DeleteProduct(this.repository);

  Future<int> call(int id) => repository.delete(id);
}
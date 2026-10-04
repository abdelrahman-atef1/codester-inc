/// products_dao.dart — DAO for products table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<Product>> getAllProducts() => select(products).get();

  Stream<List<Product>> watchAllProducts() => select(products).watch();

  Future<Product?> getProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Product?> getProductByBarcode(String barcode) =>
      (select(products)..where((p) => p.barcode.equals(barcode)))
          .getSingleOrNull();

  Stream<Product?> watchProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((p) => p.name.like('%$query%') | p.barcode.like('%$query%')))
        .get();
  }

  Future<List<Product>> getLowStockProducts() {
    return (select(products)
          ..where((p) => p.quantity.isSmallerOrEqual(p.minQuantity)))
        .get();
  }

  Stream<List<Product>> watchLowStockProducts() {
    return (select(products)
          ..where((p) => p.quantity.isSmallerOrEqual(p.minQuantity)))
        .watch();
  }

  Future<int> insertProduct(ProductsCompanion companion) =>
      into(products).insert(companion);

  Future<bool> updateProduct(Product product) => update(products).replace(product);

  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  Future<void> updateQuantity(int id, int newQuantity) {
    return (update(products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(
      quantity: Value(newQuantity),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> adjustQuantity(int id, int delta) async {
    final product = await getProductById(id);
    if (product != null) {
      await updateQuantity(id, product.quantity + delta);
    }
  }
}
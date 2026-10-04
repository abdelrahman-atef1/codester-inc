import 'package:drift/drift.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/database/daos/products_dao.dart';
import '../../../../core/database/daos/activity_log_dao.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';

/// Drift-based implementation of [ProductRepository].
/// T-006: Data layer for inventory feature.
/// Uses ProductsDao and ActivityLogDao from the core database layer.
class DriftInventoryRepository implements ProductRepository {
  final ProductsDao _productsDao;
  final ActivityLogDao _activityLogDao;

  DriftInventoryRepository(this._productsDao, this._activityLogDao);

  // ─── Mapping: Drift row → Domain entity ───

  Product _toDomain(db.Product p) {
    return Product(
      id: p.id,
      name: p.name,
      barcode: p.barcode,
      price: p.price,
      cost: p.cost,
      quantity: p.quantity,
      minQuantity: p.minQuantity,
      category: p.category,
      unit: p.unit,
      imagePath: p.imagePath,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  // ─── ProductRepository impl ───

  @override
  Stream<List<Product>> watchAll() {
    return _productsDao.watchAllProducts().map(
      (rows) => rows.map(_toDomain).toList(),
    );
  }

  @override
  Stream<List<Product>> search(String query) {
    if (query.trim().isEmpty) return watchAll();
    // Use a stream that re-queries on changes
    return _productsDao.watchAllProducts().map((all) {
      final q = query.trim().toLowerCase();
      return all
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.barcode?.toLowerCase().contains(q) ?? false))
          .map(_toDomain)
          .toList();
    });
  }

  @override
  Stream<Product> watchById(int id) {
    return _productsDao.watchProductById(id).map((p) {
      if (p == null) throw Exception('Product $id not found');
      return _toDomain(p);
    });
  }

  @override
  Future<Product> getById(int id) async {
    final p = await _productsDao.getProductById(id);
    if (p == null) throw Exception('Product $id not found');
    return _toDomain(p);
  }

  @override
  Future<int> add(Product product) {
    final companion = db.ProductsCompanion(
      name: Value(product.name),
      barcode: Value(product.barcode),
      price: Value(product.price),
      cost: Value(product.cost),
      quantity: Value(product.quantity),
      minQuantity: Value(product.minQuantity),
      category: Value(product.category),
      unit: Value(product.unit),
      imagePath: Value(product.imagePath),
      createdAt: Value(product.createdAt),
      updatedAt: Value(product.updatedAt),
    );
    return _productsDao.insertProduct(companion);
  }

  @override
  Future<bool> edit(Product product) {
    final row = db.Product(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      cost: product.cost,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      category: product.category,
      unit: product.unit,
      imagePath: product.imagePath,
      createdAt: product.createdAt,
      updatedAt: DateTime.now(),
    );
    return _productsDao.updateProduct(row);
  }

  @override
  Future<int> delete(int id) {
    return _productsDao.deleteProduct(id);
  }

  // ─── Activity Log helpers ───

  Future<void> logActivity({
    required String action,
    required int entityId,
    String? details,
  }) async {
    await _activityLogDao.insertLog(
      db.ActivityLogCompanion(
        action: Value(action),
        entityType: const Value('product'),
        entityId: Value(entityId),
        details: Value(details),
      ),
    );
  }
}
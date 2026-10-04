import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/database/daos/products_dao.dart';
import '../../../../core/database/daos/activity_log_dao.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/usecases/add_product.dart';
import '../domain/usecases/delete_product.dart';
import '../domain/usecases/edit_product.dart';
import '../domain/usecases/get_product_by_id.dart';
import '../domain/usecases/get_products.dart';
import '../data/drift_inventory_repository.dart';

// ─── Database ───

/// Singleton AppDatabase provider
final appDatabaseProvider = Provider<db.AppDatabase>((ref) {
  final database = db.AppDatabase();
  ref.onDispose(database.close);
  return database;
});

// ─── DAOs ───

final productsDaoProvider = Provider<ProductsDao>((ref) {
  return ProductsDao(ref.watch(appDatabaseProvider));
});

final activityLogDaoProvider = Provider<ActivityLogDao>((ref) {
  return ActivityLogDao(ref.watch(appDatabaseProvider));
});

// ─── Repository ───

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return DriftInventoryRepository(
    ref.watch(productsDaoProvider),
    ref.watch(activityLogDaoProvider),
  );
});

// ─── Use Cases ───

final addProductUseCaseProvider = Provider<AddProduct>((ref) {
  return AddProduct(ref.watch(productRepositoryProvider));
});

final editProductUseCaseProvider = Provider<EditProduct>((ref) {
  return EditProduct(ref.watch(productRepositoryProvider));
});

final getProductsUseCaseProvider = Provider<GetProducts>((ref) {
  return GetProducts(ref.watch(productRepositoryProvider));
});

final getProductByIdUseCaseProvider = Provider<GetProductById>((ref) {
  return GetProductById(ref.watch(productRepositoryProvider));
});

final deleteProductUseCaseProvider = Provider<DeleteProduct>((ref) {
  return DeleteProduct(ref.watch(productRepositoryProvider));
});

// ─── View Models / State ───

/// Search query state for product list
final productSearchProvider = StateProvider<String>((ref) => '');

/// Reactive product list (filtered by search query if non-empty)
final productListProvider = StreamProvider<List<Product>>((ref) {
  final useCase = ref.watch(getProductsUseCaseProvider);
  final query = ref.watch(productSearchProvider);

  if (query.isEmpty) {
    return useCase();
  } else {
    return useCase.search(query);
  }
});

/// Single product by ID (reactive)
final productByIdProvider =
    StreamProvider.family<Product, int>((ref, id) {
  final useCase = ref.watch(getProductByIdUseCaseProvider);
  return useCase.watch(id);
});

/// Activity log for a specific product (reactive)
final productActivityLogProvider =
    StreamProvider.family<List<db.ActivityLogData>, int>((ref, productId) {
  final dao = ref.watch(activityLogDaoProvider);
  // Poll-based approach: watch all logs and filter by entity
  return dao.watchAllLogs().map((logs) => logs
      .where((l) =>
          l.entityId == productId && l.entityType == 'product')
      .toList());
});
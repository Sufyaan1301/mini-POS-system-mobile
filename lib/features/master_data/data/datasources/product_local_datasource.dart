import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts({int? categoryId, String? query});
  Future<ProductModel?> getProductById(int id);
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> softDeleteProduct(int id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  ProductLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  @override
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? query,
  }) async {
    try {
      final db = await _database.database;
      final conditions = <String>['p.${DbConstants.colIsDeleted} = 0'];
      final args = <Object?>[];

      if (categoryId != null) {
        conditions.add('p.${DbConstants.colCategoryId} = ?');
        args.add(categoryId);
      }

      if (query != null && query.trim().isNotEmpty) {
        conditions.add('LOWER(p.${DbConstants.colName}) LIKE ?');
        args.add('%${query.trim().toLowerCase()}%');
      }

      final rows = await db.rawQuery('''
        SELECT p.*, c.${DbConstants.colName} AS category_name
        FROM ${DbConstants.tableProducts} p
        INNER JOIN ${DbConstants.tableCategories} c
          ON c.${DbConstants.colId} = p.${DbConstants.colCategoryId}
        WHERE ${conditions.join(' AND ')}
        ORDER BY p.${DbConstants.colName} ASC
      ''', args);

      return rows.map(ProductModel.fromMap).toList();
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat produk: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    try {
      final db = await _database.database;
      final rows = await db.rawQuery('''
        SELECT p.*, c.${DbConstants.colName} AS category_name
        FROM ${DbConstants.tableProducts} p
        INNER JOIN ${DbConstants.tableCategories} c
          ON c.${DbConstants.colId} = p.${DbConstants.colCategoryId}
        WHERE p.${DbConstants.colId} = ?
        LIMIT 1
      ''', [id]);

      if (rows.isEmpty) return null;
      return ProductModel.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat detail produk: $e');
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final db = await _database.database;
      final id = await db.insert(
        DbConstants.tableProducts,
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return (await getProductById(id)) ?? product.copyWith(id: id);
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menambah produk: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final db = await _database.database;
      await db.update(
        DbConstants.tableProducts,
        product.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [product.id],
      );
      return (await getProductById(product.id!)) ?? product;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memperbarui produk: $e');
    }
  }

  @override
  Future<void> softDeleteProduct(int id) async {
    try {
      final db = await _database.database;
      await db.update(
        DbConstants.tableProducts,
        {
          DbConstants.colIsDeleted: 1,
          DbConstants.colUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menghapus produk: $e');
    }
  }
}

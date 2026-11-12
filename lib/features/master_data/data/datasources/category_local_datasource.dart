import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(CategoryModel category);
  Future<void> deleteCategory(int id);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  CategoryLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final db = await _database.database;
      final rows = await db.query(
        DbConstants.tableCategories,
        orderBy: '${DbConstants.colName} ASC',
      );
      return rows.map(CategoryModel.fromMap).toList();
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat kategori: $e');
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final db = await _database.database;
      final duplicate = await _existsByName(db, category.name);
      if (duplicate) {
        throw const ValidationException('Nama kategori sudah ada.');
      }

      final id = await db.insert(
        DbConstants.tableCategories,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return category.copyWith(id: id);
    } on AppException {
      rethrow;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menambah kategori: $e');
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final db = await _database.database;
      final duplicate = await _existsByName(
        db,
        category.name,
        excludeId: category.id,
      );
      if (duplicate) {
        throw const ValidationException('Nama kategori sudah ada.');
      }

      await db.update(
        DbConstants.tableCategories,
        {DbConstants.colName: category.name},
        where: '${DbConstants.colId} = ?',
        whereArgs: [category.id],
      );
      return category;
    } on AppException {
      rethrow;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memperbarui kategori: $e');
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    try {
      await _database.runInTransaction((txn) async {
        final activeProducts = Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(*) FROM ${DbConstants.tableProducts} '
                'WHERE ${DbConstants.colCategoryId} = ? '
                'AND ${DbConstants.colIsDeleted} = 0',
                [id],
              ),
            ) ??
            0;

        if (activeProducts > 0) {
          throw const ValidationException(
            'Kategori masih digunakan oleh produk aktif.',
          );
        }

        // Remove soft-deleted products under this category before deleting it;
        // historical transaction items keep immutable snapshot columns.
        await txn.delete(
          DbConstants.tableProducts,
          where: '${DbConstants.colCategoryId} = ? '
              'AND ${DbConstants.colIsDeleted} = 1',
          whereArgs: [id],
        );

        await txn.delete(
          DbConstants.tableCategories,
          where: '${DbConstants.colId} = ?',
          whereArgs: [id],
        );
      });
    } on AppException {
      rethrow;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menghapus kategori: $e');
    }
  }

  Future<bool> _existsByName(
    Database db,
    String name, {
    int? excludeId,
  }) async {
    final rows = await db.query(
      DbConstants.tableCategories,
      columns: [DbConstants.colId],
      where: excludeId == null
          ? 'LOWER(${DbConstants.colName}) = LOWER(?)'
          : 'LOWER(${DbConstants.colName}) = LOWER(?) AND ${DbConstants.colId} != ?',
      whereArgs: excludeId == null ? [name.trim()] : [name.trim(), excludeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}

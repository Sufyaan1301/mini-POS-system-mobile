import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../models/addon_model.dart';

abstract class AddonLocalDataSource {
  Future<List<AddonModel>> getAddons();
  Future<AddonModel> createAddon(AddonModel addon);
  Future<AddonModel> updateAddon(AddonModel addon);
  Future<void> softDeleteAddon(int id);
}

class AddonLocalDataSourceImpl implements AddonLocalDataSource {
  AddonLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  @override
  Future<List<AddonModel>> getAddons() async {
    try {
      final db = await _database.database;
      final rows = await db.query(
        DbConstants.tableAddons,
        where: '${DbConstants.colIsDeleted} = 0',
        orderBy: '${DbConstants.colName} ASC',
      );
      return rows.map(AddonModel.fromMap).toList();
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat add-on: $e');
    }
  }

  @override
  Future<AddonModel> createAddon(AddonModel addon) async {
    try {
      final db = await _database.database;
      final id = await db.insert(
        DbConstants.tableAddons,
        addon.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return addon.copyWith(id: id);
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menambah add-on: $e');
    }
  }

  @override
  Future<AddonModel> updateAddon(AddonModel addon) async {
    try {
      final db = await _database.database;
      await db.update(
        DbConstants.tableAddons,
        addon.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [addon.id],
      );
      return addon;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memperbarui add-on: $e');
    }
  }

  @override
  Future<void> softDeleteAddon(int id) async {
    try {
      final db = await _database.database;
      await db.update(
        DbConstants.tableAddons,
        {
          DbConstants.colIsDeleted: 1,
          DbConstants.colUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menghapus add-on: $e');
    }
  }
}

import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../models/cashier_model.dart';

/// Local SQLite datasource for cashier accounts.
abstract class AuthLocalDataSource {
  Future<CashierModel?> getCashierByUsername(String username);
  Future<CashierModel?> getCashierById(int id);
  Future<CashierModel> createCashier(CashierModel cashier);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  @override
  Future<CashierModel?> getCashierByUsername(String username) async {
    try {
      final db = await _database.database;
      final rows = await db.query(
        DbConstants.tableCashiers,
        where: 'LOWER(${DbConstants.colUsername}) = LOWER(?)',
        whereArgs: [username.trim()],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return CashierModel.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal membaca data kasir: $e');
    }
  }

  @override
  Future<CashierModel?> getCashierById(int id) async {
    try {
      final db = await _database.database;
      final rows = await db.query(
        DbConstants.tableCashiers,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return CashierModel.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat profil kasir: $e');
    }
  }

  @override
  Future<CashierModel> createCashier(CashierModel cashier) async {
    try {
      final db = await _database.database;
      final id = await db.insert(
        DbConstants.tableCashiers,
        cashier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return CashierModel(
        id: id,
        name: cashier.name,
        username: cashier.username,
        passwordHash: cashier.passwordHash,
        createdAt: cashier.createdAt,
      );
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal mendaftarkan kasir: $e');
    }
  }
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../constants/db_constants.dart';

/// Singleton SQLite helper managing schema creation and atomic transactions.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCashiers} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colName} TEXT NOT NULL,
        ${DbConstants.colUsername} TEXT NOT NULL UNIQUE,
        ${DbConstants.colPasswordHash} TEXT NOT NULL,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colName} TEXT NOT NULL UNIQUE,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableProducts} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colCategoryId} INTEGER NOT NULL,
        ${DbConstants.colName} TEXT NOT NULL,
        ${DbConstants.colPrice} REAL NOT NULL,
        ${DbConstants.colStock} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colImagePath} TEXT,
        ${DbConstants.colIsDeleted} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colCategoryId})
          REFERENCES ${DbConstants.tableCategories} (${DbConstants.colId})
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableAddons} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colName} TEXT NOT NULL,
        ${DbConstants.colPrice} REAL NOT NULL,
        ${DbConstants.colStock} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colIsDeleted} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableTransactions} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colInvoiceNumber} TEXT NOT NULL UNIQUE,
        ${DbConstants.colCashierId} INTEGER,
        ${DbConstants.colCashierNameSnapshot} TEXT NOT NULL,
        ${DbConstants.colSubtotal} REAL NOT NULL,
        ${DbConstants.colDiscountType} TEXT NOT NULL,
        ${DbConstants.colDiscountValue} REAL NOT NULL,
        ${DbConstants.colDiscountAmount} REAL NOT NULL,
        ${DbConstants.colTotal} REAL NOT NULL,
        ${DbConstants.colCashReceived} REAL NOT NULL,
        ${DbConstants.colChangeAmount} REAL NOT NULL,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colCashierId})
          REFERENCES ${DbConstants.tableCashiers} (${DbConstants.colId})
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableTransactionItems} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colTransactionId} INTEGER NOT NULL,
        ${DbConstants.colProductId} INTEGER,
        ${DbConstants.colProductNameSnapshot} TEXT NOT NULL,
        ${DbConstants.colUnitPriceSnapshot} REAL NOT NULL,
        ${DbConstants.colQuantity} INTEGER NOT NULL,
        ${DbConstants.colItemSubtotal} REAL NOT NULL,
        FOREIGN KEY (${DbConstants.colTransactionId})
          REFERENCES ${DbConstants.tableTransactions} (${DbConstants.colId})
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.colProductId})
          REFERENCES ${DbConstants.tableProducts} (${DbConstants.colId})
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableTransactionItemAddons} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colTransactionItemId} INTEGER NOT NULL,
        ${DbConstants.colAddonId} INTEGER,
        ${DbConstants.colAddonNameSnapshot} TEXT NOT NULL,
        ${DbConstants.colAddonPriceSnapshot} REAL NOT NULL,
        ${DbConstants.colQuantity} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.colTransactionItemId})
          REFERENCES ${DbConstants.tableTransactionItems} (${DbConstants.colId})
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.colAddonId})
          REFERENCES ${DbConstants.tableAddons} (${DbConstants.colId})
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableHeldOrders} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colLabel} TEXT NOT NULL,
        ${DbConstants.colCartJson} TEXT NOT NULL,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');
  }

  /// Runs [action] inside an atomic SQLite transaction so stock deduction
  /// and receipt persistence succeed or roll back together.
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }
}

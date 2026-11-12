import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../../../master_data/data/models/addon_model.dart';
import '../../../master_data/data/models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/discount_model.dart';
import '../models/held_order_model.dart';
import '../models/transaction_receipt_model.dart';
import '../services/stock_validator.dart';

abstract class PosLocalDataSource {
  Future<TransactionReceiptModel> checkoutTransaction({
    required int? cashierId,
    required String cashierName,
    required List<CartItemModel> items,
    required DiscountModel discount,
    required double cashReceived,
    int? heldOrderId,
  });

  Future<HeldOrderModel> saveHeldOrder(HeldOrderModel order);
  Future<List<HeldOrderModel>> getHeldOrders();
  Future<void> deleteHeldOrder(int id);
}

class PosLocalDataSourceImpl implements PosLocalDataSource {
  PosLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  @override
  Future<TransactionReceiptModel> checkoutTransaction({
    required int? cashierId,
    required String cashierName,
    required List<CartItemModel> items,
    required DiscountModel discount,
    required double cashReceived,
    int? heldOrderId,
  }) async {
    if (items.isEmpty) {
      throw const ValidationException('Keranjang masih kosong.');
    }

    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.lineSubtotal,
    );
    discount.validateAgainstSubtotal(subtotal);
    final discountAmount = discount.computeDiscountAmount(subtotal);
    final total = discount.computeTotal(subtotal);

    if (cashReceived < total) {
      throw const ValidationException(
        'Uang tunai yang diterima kurang dari total tagihan.',
      );
    }

    final changeAmount = cashReceived - total;
    final now = DateTime.now();
    final invoiceNumber = _generateInvoiceNumber(now);

    try {
      return await _database.runInTransaction((txn) async {
        final productsById = await _loadProductsForCart(txn, items);
        final addonsById = await _loadAddonsForCart(txn, items);

        StockValidator.validateEntireCart(
          cart: items,
          productsById: productsById,
          addonsById: addonsById,
        );

        await _deductStocks(txn, items, now);

        final transactionId = await txn.insert(
          DbConstants.tableTransactions,
          {
            DbConstants.colInvoiceNumber: invoiceNumber,
            DbConstants.colCashierId: cashierId,
            DbConstants.colCashierNameSnapshot: cashierName,
            DbConstants.colSubtotal: subtotal,
            DbConstants.colDiscountType: discount.type.dbValue,
            DbConstants.colDiscountValue: discount.value,
            DbConstants.colDiscountAmount: discountAmount,
            DbConstants.colTotal: total,
            DbConstants.colCashReceived: cashReceived,
            DbConstants.colChangeAmount: changeAmount,
            DbConstants.colCreatedAt: now.toIso8601String(),
          },
        );

        final receiptItems = <TransactionReceiptItem>[];
        for (final item in items) {
          final itemId = await txn.insert(
            DbConstants.tableTransactionItems,
            {
              DbConstants.colTransactionId: transactionId,
              DbConstants.colProductId: item.productId,
              DbConstants.colProductNameSnapshot: item.productName,
              DbConstants.colUnitPriceSnapshot: item.unitPrice,
              DbConstants.colQuantity: item.quantity,
              DbConstants.colItemSubtotal: item.lineSubtotal,
            },
          );

          final receiptAddons = <TransactionReceiptAddon>[];
          for (final addon in item.addons) {
            final addonRowId = await txn.insert(
              DbConstants.tableTransactionItemAddons,
              {
                DbConstants.colTransactionItemId: itemId,
                DbConstants.colAddonId: addon.addonId,
                DbConstants.colAddonNameSnapshot: addon.name,
                DbConstants.colAddonPriceSnapshot: addon.price,
                DbConstants.colQuantity: item.quantity,
              },
            );
            receiptAddons.add(
              TransactionReceiptAddon(
                id: addonRowId,
                addonId: addon.addonId,
                addonName: addon.name,
                addonPrice: addon.price,
                quantity: item.quantity,
              ),
            );
          }

          receiptItems.add(
            TransactionReceiptItem(
              id: itemId,
              productId: item.productId,
              productName: item.productName,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              itemSubtotal: item.lineSubtotal,
              addons: receiptAddons,
            ),
          );
        }

        if (heldOrderId != null) {
          await txn.delete(
            DbConstants.tableHeldOrders,
            where: '${DbConstants.colId} = ?',
            whereArgs: [heldOrderId],
          );
        }

        return TransactionReceiptModel(
          id: transactionId,
          invoiceNumber: invoiceNumber,
          cashierId: cashierId,
          cashierName: cashierName,
          subtotal: subtotal,
          discountType: discount.type,
          discountValue: discount.value,
          discountAmount: discountAmount,
          total: total,
          cashReceived: cashReceived,
          changeAmount: changeAmount,
          createdAt: now,
          items: receiptItems,
        );
      });
    } on AppException {
      rethrow;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menyimpan transaksi: $e');
    }
  }

  Future<Map<int, ProductModel>> _loadProductsForCart(
    Transaction txn,
    List<CartItemModel> items,
  ) async {
    final ids = items.map((e) => e.productId).toSet().toList();
    if (ids.isEmpty) return {};

    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await txn.query(
      DbConstants.tableProducts,
      where: '${DbConstants.colId} IN ($placeholders)',
      whereArgs: ids,
    );

    return {
      for (final row in rows)
        row[DbConstants.colId] as int: ProductModel.fromMap(row),
    };
  }

  Future<Map<int, AddonModel>> _loadAddonsForCart(
    Transaction txn,
    List<CartItemModel> items,
  ) async {
    final ids = items
        .expand((item) => item.addons.map((a) => a.addonId))
        .toSet()
        .toList();
    if (ids.isEmpty) return {};

    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await txn.query(
      DbConstants.tableAddons,
      where: '${DbConstants.colId} IN ($placeholders)',
      whereArgs: ids,
    );

    return {
      for (final row in rows)
        row[DbConstants.colId] as int: AddonModel.fromMap(row),
    };
  }

  Future<void> _deductStocks(
    Transaction txn,
    List<CartItemModel> items,
    DateTime now,
  ) async {
    final productDemand = <int, int>{};
    final addonDemand = <int, int>{};

    for (final item in items) {
      productDemand[item.productId] =
          (productDemand[item.productId] ?? 0) + item.quantity;
      for (final addon in item.addons) {
        addonDemand[addon.addonId] =
            (addonDemand[addon.addonId] ?? 0) + item.quantity;
      }
    }

    final timestamp = now.toIso8601String();
    for (final entry in productDemand.entries) {
      await txn.rawUpdate(
        'UPDATE ${DbConstants.tableProducts} '
        'SET ${DbConstants.colStock} = ${DbConstants.colStock} - ?, '
        '${DbConstants.colUpdatedAt} = ? '
        'WHERE ${DbConstants.colId} = ?',
        [entry.value, timestamp, entry.key],
      );
    }

    for (final entry in addonDemand.entries) {
      await txn.rawUpdate(
        'UPDATE ${DbConstants.tableAddons} '
        'SET ${DbConstants.colStock} = ${DbConstants.colStock} - ?, '
        '${DbConstants.colUpdatedAt} = ? '
        'WHERE ${DbConstants.colId} = ?',
        [entry.value, timestamp, entry.key],
      );
    }
  }

  String _generateInvoiceNumber(DateTime now) {
    final datePart = DateFormat('yyyyMMdd-HHmmss').format(now);
    final millisPart = now.millisecond.toString().padLeft(3, '0');
    return 'INV-$datePart-$millisPart';
  }

  @override
  Future<HeldOrderModel> saveHeldOrder(HeldOrderModel order) async {
    try {
      final db = await _database.database;
      final id = await db.insert(
        DbConstants.tableHeldOrders,
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return HeldOrderModel(
        id: id,
        label: order.label,
        items: order.items,
        discount: order.discount,
        createdAt: order.createdAt,
      );
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menyimpan bill sementara: $e');
    }
  }

  @override
  Future<List<HeldOrderModel>> getHeldOrders() async {
    try {
      final db = await _database.database;
      final rows = await db.query(
        DbConstants.tableHeldOrders,
        orderBy: '${DbConstants.colCreatedAt} DESC',
      );
      return rows.map(HeldOrderModel.fromMap).toList();
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat daftar hold bill: $e');
    }
  }

  @override
  Future<void> deleteHeldOrder(int id) async {
    try {
      final db = await _database.database;
      await db.delete(
        DbConstants.tableHeldOrders,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal menghapus hold bill: $e');
    }
  }
}

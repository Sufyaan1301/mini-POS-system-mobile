import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';
import 'discount_model.dart';

/// Immutable snapshot of an add-on attached to a completed transaction item.
class TransactionReceiptAddon extends Equatable {
  const TransactionReceiptAddon({
    this.id,
    this.addonId,
    required this.addonName,
    required this.addonPrice,
    required this.quantity,
  });

  final int? id;
  final int? addonId;
  final String addonName;
  final double addonPrice;
  final int quantity;

  factory TransactionReceiptAddon.fromMap(Map<String, dynamic> map) {
    return TransactionReceiptAddon(
      id: map[DbConstants.colId] as int?,
      addonId: map[DbConstants.colAddonId] as int?,
      addonName: map[DbConstants.colAddonNameSnapshot] as String,
      addonPrice: (map[DbConstants.colAddonPriceSnapshot] as num).toDouble(),
      quantity: map[DbConstants.colQuantity] as int,
    );
  }

  @override
  List<Object?> get props => [id, addonId, addonName, addonPrice, quantity];
}

/// Immutable snapshot of a sold item inside a completed transaction.
class TransactionReceiptItem extends Equatable {
  const TransactionReceiptItem({
    this.id,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.itemSubtotal,
    this.addons = const [],
  });

  final int? id;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double itemSubtotal;
  final List<TransactionReceiptAddon> addons;

  factory TransactionReceiptItem.fromMap(
    Map<String, dynamic> map, {
    List<TransactionReceiptAddon> addons = const [],
  }) {
    return TransactionReceiptItem(
      id: map[DbConstants.colId] as int?,
      productId: map[DbConstants.colProductId] as int?,
      productName: map[DbConstants.colProductNameSnapshot] as String,
      unitPrice: (map[DbConstants.colUnitPriceSnapshot] as num).toDouble(),
      quantity: map[DbConstants.colQuantity] as int,
      itemSubtotal: (map[DbConstants.colItemSubtotal] as num).toDouble(),
      addons: addons,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        unitPrice,
        quantity,
        itemSubtotal,
        addons,
      ];
}

/// Immutable completed transaction record used for digital receipts and reports.
class TransactionReceiptModel extends Equatable {
  const TransactionReceiptModel({
    this.id,
    required this.invoiceNumber,
    this.cashierId,
    required this.cashierName,
    required this.subtotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.total,
    required this.cashReceived,
    required this.changeAmount,
    required this.createdAt,
    this.items = const [],
  });

  final int? id;
  final String invoiceNumber;
  final int? cashierId;
  final String cashierName;
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double total;
  final double cashReceived;
  final double changeAmount;
  final DateTime createdAt;
  final List<TransactionReceiptItem> items;

  factory TransactionReceiptModel.fromMap(
    Map<String, dynamic> map, {
    List<TransactionReceiptItem> items = const [],
  }) {
    return TransactionReceiptModel(
      id: map[DbConstants.colId] as int?,
      invoiceNumber: map[DbConstants.colInvoiceNumber] as String,
      cashierId: map[DbConstants.colCashierId] as int?,
      cashierName: map[DbConstants.colCashierNameSnapshot] as String,
      subtotal: (map[DbConstants.colSubtotal] as num).toDouble(),
      discountType: DiscountType.fromDb(
        map[DbConstants.colDiscountType] as String,
      ),
      discountValue: (map[DbConstants.colDiscountValue] as num).toDouble(),
      discountAmount: (map[DbConstants.colDiscountAmount] as num).toDouble(),
      total: (map[DbConstants.colTotal] as num).toDouble(),
      cashReceived: (map[DbConstants.colCashReceived] as num).toDouble(),
      changeAmount: (map[DbConstants.colChangeAmount] as num).toDouble(),
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
      items: items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        cashierId,
        cashierName,
        subtotal,
        discountType,
        discountValue,
        discountAmount,
        total,
        cashReceived,
        changeAmount,
        createdAt,
        items,
      ];
}

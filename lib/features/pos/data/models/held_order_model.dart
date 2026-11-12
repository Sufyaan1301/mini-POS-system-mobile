import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';
import 'cart_item_model.dart';
import 'discount_model.dart';

/// Temporarily saved ongoing order (Hold / Save Bill bonus feature).
class HeldOrderModel extends Equatable {
  const HeldOrderModel({
    this.id,
    required this.label,
    required this.items,
    required this.discount,
    required this.createdAt,
  });

  final int? id;
  final String label;
  final List<CartItemModel> items;
  final DiscountModel discount;
  final DateTime createdAt;

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineSubtotal);

  factory HeldOrderModel.fromMap(Map<String, dynamic> map) {
    final decoded =
        jsonDecode(map[DbConstants.colCartJson] as String) as Map<String, dynamic>;
    final rawItems = decoded['items'] as List<dynamic>? ?? [];
    final rawDiscount = decoded['discount'] as Map<String, dynamic>? ?? {};

    return HeldOrderModel(
      id: map[DbConstants.colId] as int?,
      label: map[DbConstants.colLabel] as String,
      items: rawItems
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      discount: DiscountModel.fromJson(rawDiscount),
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final cartJson = jsonEncode({
      'items': items.map((e) => e.toJson()).toList(),
      'discount': discount.toJson(),
    });
    return {
      if (id != null) DbConstants.colId: id,
      DbConstants.colLabel: label,
      DbConstants.colCartJson: cartJson,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, label, items, discount, createdAt];
}

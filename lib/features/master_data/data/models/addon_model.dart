import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';

/// Represents an add-on / topping with its own price and independent stock.
class AddonModel extends Equatable {
  const AddonModel({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final double price;
  final int stock;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AddonModel.fromMap(Map<String, dynamic> map) {
    return AddonModel(
      id: map[DbConstants.colId] as int?,
      name: map[DbConstants.colName] as String,
      price: (map[DbConstants.colPrice] as num).toDouble(),
      stock: map[DbConstants.colStock] as int,
      isDeleted: (map[DbConstants.colIsDeleted] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[DbConstants.colUpdatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colId: id,
      DbConstants.colName: name,
      DbConstants.colPrice: price,
      DbConstants.colStock: stock,
      DbConstants.colIsDeleted: isDeleted ? 1 : 0,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  AddonModel copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        stock,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}

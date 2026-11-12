import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';

/// Represents a sellable product with stock and optional persistent photo path.
class ProductModel extends Equatable {
  const ProductModel({
    this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.price,
    required this.stock,
    this.imagePath,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int categoryId;
  final String? categoryName;
  final String name;
  final double price;
  final int stock;
  final String? imagePath;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map[DbConstants.colId] as int?,
      categoryId: map[DbConstants.colCategoryId] as int,
      categoryName: map['category_name'] as String?,
      name: map[DbConstants.colName] as String,
      price: (map[DbConstants.colPrice] as num).toDouble(),
      stock: map[DbConstants.colStock] as int,
      imagePath: map[DbConstants.colImagePath] as String?,
      isDeleted: (map[DbConstants.colIsDeleted] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[DbConstants.colUpdatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colId: id,
      DbConstants.colCategoryId: categoryId,
      DbConstants.colName: name,
      DbConstants.colPrice: price,
      DbConstants.colStock: stock,
      DbConstants.colImagePath: imagePath,
      DbConstants.colIsDeleted: isDeleted ? 1 : 0,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    String? name,
    double? price,
    int? stock,
    String? imagePath,
    bool clearImagePath = false,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        categoryName,
        name,
        price,
        stock,
        imagePath,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}

import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';

/// Represents a product category stored in SQLite.
class CategoryModel extends Equatable {
  const CategoryModel({
    this.id,
    required this.name,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final DateTime createdAt;

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map[DbConstants.colId] as int?,
      name: map[DbConstants.colName] as String,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colId: id,
      DbConstants.colName: name,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}

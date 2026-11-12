import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';

/// Represents a registered cashier account stored in SQLite.
class CashierModel extends Equatable {
  const CashierModel({
    this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String username;
  final String passwordHash;
  final DateTime createdAt;

  factory CashierModel.fromMap(Map<String, dynamic> map) {
    return CashierModel(
      id: map[DbConstants.colId] as int?,
      name: map[DbConstants.colName] as String,
      username: map[DbConstants.colUsername] as String,
      passwordHash: map[DbConstants.colPasswordHash] as String,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colId: id,
      DbConstants.colName: name,
      DbConstants.colUsername: username,
      DbConstants.colPasswordHash: passwordHash,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, username, passwordHash, createdAt];
}

import 'package:equatable/equatable.dart';

import '../../../../core/error/app_exception.dart';

enum DiscountType {
  none('none'),
  percent('percent'),
  fixed('fixed');

  const DiscountType(this.dbValue);
  final String dbValue;

  static DiscountType fromDb(String value) {
    return DiscountType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => DiscountType.none,
    );
  }
}

/// Encapsulates discount configuration and strict calculation protection rules.
class DiscountModel extends Equatable {
  const DiscountModel({
    this.type = DiscountType.none,
    this.value = 0,
  });

  const DiscountModel.none() : this(type: DiscountType.none, value: 0);

  final DiscountType type;
  final double value;

  /// Validates discount rules before applying to the cart.
  void validateAgainstSubtotal(double subtotal) {
    if (value < 0) {
      throw const ValidationException('Nilai diskon tidak boleh negatif.');
    }
    if (type == DiscountType.percent && value > 100) {
      throw const ValidationException(
        'Diskon persentase tidak boleh lebih dari 100%.',
      );
    }
    if (type == DiscountType.fixed && value > subtotal) {
      throw const ValidationException(
        'Nominal diskon tidak boleh melebihi subtotal belanja.',
      );
    }
  }

  /// Computes a safe discount amount strictly bounded within `[0, subtotal]`
  /// so the total bill can never become negative.
  double computeDiscountAmount(double subtotal) {
    if (subtotal <= 0 || type == DiscountType.none || value <= 0) {
      return 0;
    }

    final rawDiscount = switch (type) {
      DiscountType.none => 0.0,
      DiscountType.percent => subtotal * (value.clamp(0, 100) / 100.0),
      DiscountType.fixed => value,
    };

    return rawDiscount.clamp(0.0, subtotal);
  }

  double computeTotal(double subtotal) {
    final total = subtotal - computeDiscountAmount(subtotal);
    return total < 0 ? 0 : total;
  }

  Map<String, dynamic> toJson() => {
        'type': type.dbValue,
        'value': value,
      };

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      type: DiscountType.fromDb(json['type'] as String? ?? 'none'),
      value: (json['value'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [type, value];
}

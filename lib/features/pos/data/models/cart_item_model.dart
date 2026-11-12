import 'package:equatable/equatable.dart';

/// Selected add-on attached to a cart line item.
class CartAddonModel extends Equatable {
  const CartAddonModel({
    required this.addonId,
    required this.name,
    required this.price,
  });

  final int addonId;
  final String name;
  final double price;

  Map<String, dynamic> toJson() => {
        'addon_id': addonId,
        'name': name,
        'price': price,
      };

  factory CartAddonModel.fromJson(Map<String, dynamic> json) {
    return CartAddonModel(
      addonId: json['addon_id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [addonId, name, price];
}

/// Represents a product + selected add-on combination inside the cashier cart.
class CartItemModel extends Equatable {
  const CartItemModel({
    required this.lineId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.imagePath,
    required this.quantity,
    this.addons = const [],
  });

  final String lineId;
  final int productId;
  final String productName;
  final double unitPrice;
  final String? imagePath;
  final int quantity;
  final List<CartAddonModel> addons;

  /// Deterministic key combining product ID and sorted add-on IDs so identical
  /// configurations merge into a single cart line.
  static String buildLineId(int productId, List<CartAddonModel> addons) {
    final sortedIds = addons.map((a) => a.addonId).toList()..sort();
    return '$productId:${sortedIds.join(",")}';
  }

  double get addonsUnitTotal =>
      addons.fold<double>(0, (sum, addon) => sum + addon.price);

  double get unitTotal => unitPrice + addonsUnitTotal;

  double get lineSubtotal => unitTotal * quantity;

  CartItemModel copyWith({
    int? quantity,
    List<CartAddonModel>? addons,
  }) {
    return CartItemModel(
      lineId: lineId,
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      imagePath: imagePath,
      quantity: quantity ?? this.quantity,
      addons: addons ?? this.addons,
    );
  }

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'product_id': productId,
        'product_name': productName,
        'unit_price': unitPrice,
        'image_path': imagePath,
        'quantity': quantity,
        'addons': addons.map((a) => a.toJson()).toList(),
      };

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawAddons = (json['addons'] as List<dynamic>? ?? []);
    return CartItemModel(
      lineId: json['line_id'] as String,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      imagePath: json['image_path'] as String?,
      quantity: json['quantity'] as int,
      addons: rawAddons
          .map((e) => CartAddonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        lineId,
        productId,
        productName,
        unitPrice,
        imagePath,
        quantity,
        addons,
      ];
}

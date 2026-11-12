import '../../../../core/error/app_exception.dart';
import '../../../master_data/data/models/addon_model.dart';
import '../../../master_data/data/models/product_model.dart';
import '../models/cart_item_model.dart';

/// Validates shared product and add-on stock across all lines in the cart.
class StockValidator {
  StockValidator._();

  /// Total quantity of [productId] already consumed across all cart lines
  /// (including plain and add-on variants of the same product).
  static int consumedProductQuantity(List<CartItemModel> cart, int productId) {
    return cart
        .where((item) => item.productId == productId)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Total quantity of [addonId] already consumed across all cart lines.
  static int consumedAddonQuantity(List<CartItemModel> cart, int addonId) {
    var total = 0;
    for (final item in cart) {
      if (item.addons.any((a) => a.addonId == addonId)) {
        total += item.quantity;
      }
    }
    return total;
  }

  /// Validates whether adding [deltaQty] of [product] with [selectedAddons]
  /// respects the shared stock limits for both the product and each add-on.
  static void validateAddition({
    required List<CartItemModel> currentCart,
    required ProductModel product,
    required List<AddonModel> selectedAddons,
    required int deltaQty,
  }) {
    if (deltaQty <= 0) return;

    final productId = product.id;
    if (productId == null) {
      throw const ValidationException('Produk tidak valid.');
    }

    final usedProductQty = consumedProductQuantity(currentCart, productId);
    if (usedProductQty + deltaQty > product.stock) {
      final remaining = (product.stock - usedProductQty).clamp(0, product.stock);
      throw StockException(
        'Stok "${product.name}" tidak mencukupi (tersisa $remaining).',
      );
    }

    for (final addon in selectedAddons) {
      final addonId = addon.id;
      if (addonId == null) continue;
      final usedAddonQty = consumedAddonQuantity(currentCart, addonId);
      if (usedAddonQty + deltaQty > addon.stock) {
        final remaining = (addon.stock - usedAddonQty).clamp(0, addon.stock);
        throw StockException(
          'Stok add-on "${addon.name}" tidak mencukupi (tersisa $remaining).',
        );
      }
    }
  }

  /// Validates every item in [cart] against live [productsById] and [addonsById].
  /// Used when resuming a held order or before committing checkout.
  static void validateEntireCart({
    required List<CartItemModel> cart,
    required Map<int, ProductModel> productsById,
    required Map<int, AddonModel> addonsById,
  }) {
    if (cart.isEmpty) {
      throw const ValidationException('Keranjang masih kosong.');
    }

    final productDemand = <int, int>{};
    final addonDemand = <int, int>{};

    for (final item in cart) {
      productDemand[item.productId] =
          (productDemand[item.productId] ?? 0) + item.quantity;
      for (final addon in item.addons) {
        addonDemand[addon.addonId] =
            (addonDemand[addon.addonId] ?? 0) + item.quantity;
      }
    }

    for (final entry in productDemand.entries) {
      final product = productsById[entry.key];
      if (product == null || product.isDeleted) {
        throw const StockException(
          'Ada produk di keranjang yang sudah tidak tersedia.',
        );
      }
      if (entry.value > product.stock) {
        throw StockException(
          'Stok "${product.name}" hanya tersisa ${product.stock}.',
        );
      }
    }

    for (final entry in addonDemand.entries) {
      final addon = addonsById[entry.key];
      if (addon == null || addon.isDeleted) {
        throw const StockException(
          'Ada add-on di keranjang yang sudah tidak tersedia.',
        );
      }
      if (entry.value > addon.stock) {
        throw StockException(
          'Stok add-on "${addon.name}" hanya tersisa ${addon.stock}.',
        );
      }
    }
  }
}

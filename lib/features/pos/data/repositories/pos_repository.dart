import '../../../../core/error/app_exception.dart';
import '../../../master_data/data/datasources/addon_local_datasource.dart';
import '../../../master_data/data/datasources/product_local_datasource.dart';
import '../../../master_data/data/models/addon_model.dart';
import '../../../master_data/data/models/product_model.dart';
import '../datasources/pos_local_datasource.dart';
import '../models/cart_item_model.dart';
import '../models/discount_model.dart';
import '../models/held_order_model.dart';
import '../models/transaction_receipt_model.dart';
import '../services/stock_validator.dart';

abstract class PosRepository {
  Future<TransactionReceiptModel> checkout({
    required int? cashierId,
    required String cashierName,
    required List<CartItemModel> items,
    required DiscountModel discount,
    required double cashReceived,
    int? heldOrderId,
  });

  Future<HeldOrderModel> holdOrder({
    required String label,
    required List<CartItemModel> items,
    required DiscountModel discount,
  });

  Future<List<HeldOrderModel>> getHeldOrders();
  Future<void> deleteHeldOrder(int id);
  Future<void> validateHeldOrderStock(HeldOrderModel order);
}

class PosRepositoryImpl implements PosRepository {
  PosRepositoryImpl({
    required PosLocalDataSource posLocalDataSource,
    required ProductLocalDataSource productLocalDataSource,
    required AddonLocalDataSource addonLocalDataSource,
  })  : _posLocalDataSource = posLocalDataSource,
        _productLocalDataSource = productLocalDataSource,
        _addonLocalDataSource = addonLocalDataSource;

  final PosLocalDataSource _posLocalDataSource;
  final ProductLocalDataSource _productLocalDataSource;
  final AddonLocalDataSource _addonLocalDataSource;

  @override
  Future<TransactionReceiptModel> checkout({
    required int? cashierId,
    required String cashierName,
    required List<CartItemModel> items,
    required DiscountModel discount,
    required double cashReceived,
    int? heldOrderId,
  }) {
    return _posLocalDataSource.checkoutTransaction(
      cashierId: cashierId,
      cashierName: cashierName,
      items: items,
      discount: discount,
      cashReceived: cashReceived,
      heldOrderId: heldOrderId,
    );
  }

  @override
  Future<HeldOrderModel> holdOrder({
    required String label,
    required List<CartItemModel> items,
    required DiscountModel discount,
  }) {
    if (items.isEmpty) {
      throw const ValidationException('Keranjang masih kosong.');
    }
    final cleanLabel = label.trim().isEmpty
        ? 'Bill ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'
        : label.trim();

    return _posLocalDataSource.saveHeldOrder(
      HeldOrderModel(
        label: cleanLabel,
        items: items,
        discount: discount,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<HeldOrderModel>> getHeldOrders() =>
      _posLocalDataSource.getHeldOrders();

  @override
  Future<void> deleteHeldOrder(int id) =>
      _posLocalDataSource.deleteHeldOrder(id);

  @override
  Future<void> validateHeldOrderStock(HeldOrderModel order) async {
    final products = await _productLocalDataSource.getProducts();
    final addons = await _addonLocalDataSource.getAddons();

    final productsById = <int, ProductModel>{
      for (final p in products)
        if (p.id != null) p.id!: p,
    };
    final addonsById = <int, AddonModel>{
      for (final a in addons)
        if (a.id != null) a.id!: a,
    };

    StockValidator.validateEntireCart(
      cart: order.items,
      productsById: productsById,
      addonsById: addonsById,
    );
  }
}

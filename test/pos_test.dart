import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos_system/core/error/app_exception.dart';
import 'package:mini_pos_system/features/master_data/data/models/addon_model.dart';
import 'package:mini_pos_system/features/master_data/data/models/product_model.dart';
import 'package:mini_pos_system/features/master_data/data/repositories/addon_repository.dart';
import 'package:mini_pos_system/features/master_data/data/repositories/product_repository.dart';
import 'package:mini_pos_system/features/pos/data/models/cart_item_model.dart';
import 'package:mini_pos_system/features/pos/data/models/discount_model.dart';
import 'package:mini_pos_system/features/pos/data/models/held_order_model.dart';
import 'package:mini_pos_system/features/pos/data/models/transaction_receipt_model.dart';
import 'package:mini_pos_system/features/pos/data/repositories/pos_repository.dart';
import 'package:mini_pos_system/features/pos/data/services/stock_validator.dart';
import 'package:mini_pos_system/features/pos/presentation/bloc/cart/cart_bloc.dart';

class _StubProductRepository implements ProductRepository {
  _StubProductRepository(this.items);
  final List<ProductModel> items;

  @override
  Future<ProductModel> createProduct({
    required int categoryId,
    required String name,
    required double price,
    required int stock,
    String? pickedImagePath,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(ProductModel product) =>
      throw UnimplementedError();

  @override
  Future<List<ProductModel>> getProducts({int? categoryId, String? query}) async =>
      items;

  @override
  Future<ProductModel> updateProduct({
    required ProductModel existing,
    required int categoryId,
    required String name,
    required double price,
    required int stock,
    String? pickedImagePath,
    bool removeImage = false,
  }) =>
      throw UnimplementedError();
}

class _StubAddonRepository implements AddonRepository {
  _StubAddonRepository(this.items);
  final List<AddonModel> items;

  @override
  Future<AddonModel> createAddon({
    required String name,
    required double price,
    required int stock,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAddon(int id) => throw UnimplementedError();

  @override
  Future<List<AddonModel>> getAddons() async => items;

  @override
  Future<AddonModel> updateAddon({
    required AddonModel existing,
    required String name,
    required double price,
    required int stock,
  }) =>
      throw UnimplementedError();
}

class _FakePosRepository implements PosRepository {
  final List<HeldOrderModel> held = [];
  int _nextHoldId = 1;

  @override
  Future<TransactionReceiptModel> checkout({
    required int? cashierId,
    required String cashierName,
    required List<CartItemModel> items,
    required DiscountModel discount,
    required double cashReceived,
    int? heldOrderId,
  }) async {
    final subtotal =
        items.fold<double>(0, (sum, item) => sum + item.lineSubtotal);
    discount.validateAgainstSubtotal(subtotal);
    final discountAmt = discount.computeDiscountAmount(subtotal);
    final total = discount.computeTotal(subtotal);

    return TransactionReceiptModel(
      id: 1,
      invoiceNumber: 'INV-TEST-001',
      cashierId: cashierId,
      cashierName: cashierName,
      subtotal: subtotal,
      discountType: discount.type,
      discountValue: discount.value,
      discountAmount: discountAmt,
      total: total,
      cashReceived: cashReceived,
      changeAmount: cashReceived - total,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteHeldOrder(int id) async {
    held.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<HeldOrderModel>> getHeldOrders() async => List.unmodifiable(held);

  @override
  Future<HeldOrderModel> holdOrder({
    required String label,
    required List<CartItemModel> items,
    required DiscountModel discount,
  }) async {
    final order = HeldOrderModel(
      id: _nextHoldId++,
      label: label,
      items: items,
      discount: discount,
      createdAt: DateTime.now(),
    );
    held.add(order);
    return order;
  }

  @override
  Future<void> validateHeldOrderStock(HeldOrderModel order) async {}
}

void main() {
  final now = DateTime(2026, 11, 12);
  final milkCoffee = ProductModel(
    id: 1,
    categoryId: 1,
    name: 'Milk Coffee',
    price: 18000,
    stock: 2,
    createdAt: now,
    updatedAt: now,
  );
  final latte = ProductModel(
    id: 2,
    categoryId: 1,
    name: 'Latte',
    price: 20000,
    stock: 5,
    createdAt: now,
    updatedAt: now,
  );
  final extraShot = AddonModel(
    id: 10,
    name: 'Extra Shot',
    price: 5000,
    stock: 2,
    createdAt: now,
    updatedAt: now,
  );

  group('Shared Stock Validation', () {
    test(
      'blocks adding 3rd Milk Coffee when 1x plain + 1x with Extra Shot exist (stock=2)',
      () {
        final cart = [
          CartItemModel(
            lineId: CartItemModel.buildLineId(1, const []),
            productId: 1,
            productName: 'Milk Coffee',
            unitPrice: 18000,
            quantity: 1,
          ),
          CartItemModel(
            lineId: CartItemModel.buildLineId(
              1,
              const [CartAddonModel(addonId: 10, name: 'Extra Shot', price: 5000)],
            ),
            productId: 1,
            productName: 'Milk Coffee',
            unitPrice: 18000,
            quantity: 1,
            addons: const [
              CartAddonModel(addonId: 10, name: 'Extra Shot', price: 5000),
            ],
          ),
        ];

        expect(StockValidator.consumedProductQuantity(cart, 1), 2);
        expect(
          () => StockValidator.validateAddition(
            currentCart: cart,
            product: milkCoffee,
            selectedAddons: const [],
            deltaQty: 1,
          ),
          throwsA(isA<StockException>()),
        );
      },
    );

    test(
      'blocks exceeding accumulated add-on stock across different products',
      () {
        final cart = [
          CartItemModel(
            lineId: CartItemModel.buildLineId(
              1,
              const [CartAddonModel(addonId: 10, name: 'Extra Shot', price: 5000)],
            ),
            productId: 1,
            productName: 'Milk Coffee',
            unitPrice: 18000,
            quantity: 1,
            addons: const [
              CartAddonModel(addonId: 10, name: 'Extra Shot', price: 5000),
            ],
          ),
          CartItemModel(
            lineId: CartItemModel.buildLineId(
              2,
              const [CartAddonModel(addonId: 10, name: 'Extra Shot', price: 5000)],
            ),
            productId: 2,
            productName: 'Latte',
            unitPrice: 20000,
            quantity: 1,
            addons: const [
              CartAddonModel(addonId: 10, name: 'Extra Shot', price: 5000),
            ],
          ),
        ];

        expect(StockValidator.consumedAddonQuantity(cart, 10), 2);
        expect(
          () => StockValidator.validateAddition(
            currentCart: cart,
            product: latte,
            selectedAddons: [extraShot],
            deltaQty: 1,
          ),
          throwsA(isA<StockException>()),
        );
      },
    );
  });

  group('Discount Calculation Protection', () {
    test('rejects negative, >100%, and fixed discount exceeding subtotal', () {
      expect(
        () => const DiscountModel(type: DiscountType.fixed, value: -1000)
            .validateAgainstSubtotal(20000),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => const DiscountModel(type: DiscountType.percent, value: 120)
            .validateAgainstSubtotal(20000),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => const DiscountModel(type: DiscountType.fixed, value: 25000)
            .validateAgainstSubtotal(20000),
        throwsA(isA<ValidationException>()),
      );
    });

    test('never produces negative total even if subtotal drops below fixed discount',
        () {
      const discount = DiscountModel(type: DiscountType.fixed, value: 15000);
      expect(discount.computeDiscountAmount(10000), 10000);
      expect(discount.computeTotal(10000), 0);
    });
  });

  group('CartBloc', () {
    late CartBloc bloc;

    setUp(() {
      bloc = CartBloc(
        posRepository: _FakePosRepository(),
        productRepository: _StubProductRepository([milkCoffee, latte]),
        addonRepository: _StubAddonRepository([extraShot]),
      );
    });

    tearDown(() async => bloc.close());

    test('enforces shared stock on add and increment', () async {
      bloc.add(CartAddItemRequested(product: milkCoffee));
      bloc.add(
        CartAddItemRequested(product: milkCoffee, addons: [extraShot]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.totalQuantity, 2);
      expect(bloc.state.items.length, 2);

      bloc.add(CartItemIncremented(bloc.state.items.first.lineId));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.totalQuantity, 2);
      expect(bloc.state.errorMessage, isNotNull);
    });

    test('supports Hold Bill save and resume', () async {
      bloc.add(CartAddItemRequested(product: latte, addons: [extraShot]));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.items.length, 1);

      bloc.add(const CartHoldOrderSaved(label: 'Meja 2'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.items, isEmpty);
      expect(bloc.state.heldOrders.length, 1);

      bloc.add(CartHoldOrderResumed(bloc.state.heldOrders.first));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.items.length, 1);
      expect(bloc.state.activeHeldOrderId, 1);
    });
  });
}

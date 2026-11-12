import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/app_exception.dart';
import '../../../../master_data/data/models/addon_model.dart';
import '../../../../master_data/data/models/product_model.dart';
import '../../../../master_data/data/repositories/addon_repository.dart';
import '../../../../master_data/data/repositories/product_repository.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/discount_model.dart';
import '../../../data/models/held_order_model.dart';
import '../../../data/models/transaction_receipt_model.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../data/services/stock_validator.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required PosRepository posRepository,
    required ProductRepository productRepository,
    required AddonRepository addonRepository,
  })  : _posRepository = posRepository,
        _productRepository = productRepository,
        _addonRepository = addonRepository,
        super(const CartState()) {
    on<CartAddItemRequested>(_onAddItem);
    on<CartItemIncremented>(_onIncrement);
    on<CartItemDecremented>(_onDecrement);
    on<CartItemRemoved>(_onRemove);
    on<CartCleared>(_onClear);
    on<CartDiscountApplied>(_onApplyDiscount);
    on<CartDiscountCleared>(_onClearDiscount);
    on<CartHeldOrdersLoaded>(_onLoadHeldOrders);
    on<CartHoldOrderSaved>(_onSaveHeldOrder);
    on<CartHoldOrderResumed>(_onResumeHeldOrder);
    on<CartHoldOrderDeleted>(_onDeleteHeldOrder);
    on<CartCheckoutSubmitted>(_onCheckout);
    on<CartFeedbackConsumed>(_onConsumeFeedback);
  }

  final PosRepository _posRepository;
  final ProductRepository _productRepository;
  final AddonRepository _addonRepository;

  void _onAddItem(
    CartAddItemRequested event,
    Emitter<CartState> emit,
  ) {
    try {
      StockValidator.validateAddition(
        currentCart: state.items,
        product: event.product,
        selectedAddons: event.addons,
        deltaQty: event.quantity,
      );

      final cartAddons = event.addons
          .where((a) => a.id != null)
          .map(
            (a) => CartAddonModel(
              addonId: a.id!,
              name: a.name,
              price: a.price,
            ),
          )
          .toList()
        ..sort((a, b) => a.addonId.compareTo(b.addonId));

      final lineId = CartItemModel.buildLineId(event.product.id!, cartAddons);
      final updated = List<CartItemModel>.from(state.items);
      final existingIdx = updated.indexWhere((e) => e.lineId == lineId);

      if (existingIdx != -1) {
        final current = updated[existingIdx];
        updated[existingIdx] = current.copyWith(
          quantity: current.quantity + event.quantity,
        );
      } else {
        updated.add(
          CartItemModel(
            lineId: lineId,
            productId: event.product.id!,
            productName: event.product.name,
            unitPrice: event.product.price,
            imagePath: event.product.imagePath,
            quantity: event.quantity,
            addons: cartAddons,
          ),
        );
      }

      emit(
        state.copyWith(
          items: updated,
          clearCompletedReceipt: true,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onIncrement(
    CartItemIncremented event,
    Emitter<CartState> emit,
  ) async {
    final idx = state.items.indexWhere((e) => e.lineId == event.lineId);
    if (idx == -1) return;

    final item = state.items[idx];
    try {
      final products = await _productRepository.getProducts();
      final addons = await _addonRepository.getAddons();

      final product = products.cast<ProductModel?>().firstWhere(
            (p) => p?.id == item.productId,
            orElse: () => null,
          );
      if (product == null) {
        throw const StockException('Produk sudah tidak tersedia.');
      }

      final addonIds = item.addons.map((a) => a.addonId).toSet();
      final matchedAddons =
          addons.where((a) => a.id != null && addonIds.contains(a.id)).toList();

      if (matchedAddons.length != addonIds.length) {
        throw const StockException('Ada add-on yang sudah tidak tersedia.');
      }

      StockValidator.validateAddition(
        currentCart: state.items,
        product: product,
        selectedAddons: matchedAddons,
        deltaQty: 1,
      );

      final updated = List<CartItemModel>.from(state.items);
      updated[idx] = item.copyWith(quantity: item.quantity + 1);
      emit(state.copyWith(items: updated));
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _onDecrement(
    CartItemDecremented event,
    Emitter<CartState> emit,
  ) {
    final idx = state.items.indexWhere((e) => e.lineId == event.lineId);
    if (idx == -1) return;

    final updated = List<CartItemModel>.from(state.items);
    final current = updated[idx];
    if (current.quantity <= 1) {
      updated.removeAt(idx);
    } else {
      updated[idx] = current.copyWith(quantity: current.quantity - 1);
    }

    emit(
      state.copyWith(
        items: updated,
        discount: updated.isEmpty ? const DiscountModel.none() : null,
      ),
    );
  }

  void _onRemove(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) {
    final updated =
        state.items.where((e) => e.lineId != event.lineId).toList();
    emit(
      state.copyWith(
        items: updated,
        discount: updated.isEmpty ? const DiscountModel.none() : null,
      ),
    );
  }

  void _onClear(CartCleared event, Emitter<CartState> emit) {
    emit(
      state.copyWith(
        items: const [],
        discount: const DiscountModel.none(),
        clearActiveHeldOrderId: true,
        clearCompletedReceipt: true,
      ),
    );
  }

  void _onApplyDiscount(
    CartDiscountApplied event,
    Emitter<CartState> emit,
  ) {
    try {
      event.discount.validateAgainstSubtotal(state.subtotal);
      emit(
        state.copyWith(
          discount: event.discount,
          infoMessage: 'Diskon diterapkan.',
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _onClearDiscount(
    CartDiscountCleared event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(discount: const DiscountModel.none()));
  }

  Future<void> _onLoadHeldOrders(
    CartHeldOrdersLoaded event,
    Emitter<CartState> emit,
  ) async {
    try {
      final list = await _posRepository.getHeldOrders();
      emit(state.copyWith(heldOrders: list));
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onSaveHeldOrder(
    CartHoldOrderSaved event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      await _posRepository.holdOrder(
        label: event.label,
        items: state.items,
        discount: state.discount,
      );
      final list = await _posRepository.getHeldOrders();
      emit(
        state.copyWith(
          isProcessing: false,
          items: const [],
          discount: const DiscountModel.none(),
          clearActiveHeldOrderId: true,
          heldOrders: list,
          infoMessage: 'Pesanan berhasil disimpan (Hold Bill).',
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.message));
    }
  }

  Future<void> _onResumeHeldOrder(
    CartHoldOrderResumed event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      await _posRepository.validateHeldOrderStock(event.order);
      emit(
        state.copyWith(
          isProcessing: false,
          items: event.order.items,
          discount: event.order.discount,
          activeHeldOrderId: event.order.id,
          infoMessage: 'Bill "${event.order.label}" dimuat ke keranjang.',
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.message));
    }
  }

  Future<void> _onDeleteHeldOrder(
    CartHoldOrderDeleted event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _posRepository.deleteHeldOrder(event.heldOrderId);
      final list = await _posRepository.getHeldOrders();
      emit(
        state.copyWith(
          heldOrders: list,
          clearActiveHeldOrderId:
              state.activeHeldOrderId == event.heldOrderId,
          infoMessage: 'Hold bill dihapus.',
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onCheckout(
    CartCheckoutSubmitted event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, clearCompletedReceipt: true));
    try {
      final receipt = await _posRepository.checkout(
        cashierId: event.cashierId,
        cashierName: event.cashierName,
        items: state.items,
        discount: state.discount,
        cashReceived: event.cashReceived,
        heldOrderId: state.activeHeldOrderId,
      );
      final heldOrders = await _posRepository.getHeldOrders();
      emit(
        state.copyWith(
          isProcessing: false,
          items: const [],
          discount: const DiscountModel.none(),
          clearActiveHeldOrderId: true,
          heldOrders: heldOrders,
          completedReceipt: receipt,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'Gagal memproses transaksi.',
        ),
      );
    }
  }

  void _onConsumeFeedback(
    CartFeedbackConsumed event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith());
  }
}

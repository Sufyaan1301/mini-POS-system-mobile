part of 'cart_bloc.dart';

class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.discount = const DiscountModel.none(),
    this.heldOrders = const [],
    this.activeHeldOrderId,
    this.isProcessing = false,
    this.errorMessage,
    this.infoMessage,
    this.completedReceipt,
  });

  final List<CartItemModel> items;
  final DiscountModel discount;
  final List<HeldOrderModel> heldOrders;
  final int? activeHeldOrderId;
  final bool isProcessing;
  final String? errorMessage;
  final String? infoMessage;
  final TransactionReceiptModel? completedReceipt;

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineSubtotal);

  double get discountAmount => discount.computeDiscountAmount(subtotal);

  double get total => discount.computeTotal(subtotal);

  int consumedProductStock(int productId) =>
      StockValidator.consumedProductQuantity(items, productId);

  int consumedAddonStock(int addonId) =>
      StockValidator.consumedAddonQuantity(items, addonId);

  CartState copyWith({
    List<CartItemModel>? items,
    DiscountModel? discount,
    List<HeldOrderModel>? heldOrders,
    int? activeHeldOrderId,
    bool clearActiveHeldOrderId = false,
    bool? isProcessing,
    String? errorMessage,
    String? infoMessage,
    TransactionReceiptModel? completedReceipt,
    bool clearCompletedReceipt = false,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      heldOrders: heldOrders ?? this.heldOrders,
      activeHeldOrderId: clearActiveHeldOrderId
          ? null
          : (activeHeldOrderId ?? this.activeHeldOrderId),
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      completedReceipt: clearCompletedReceipt
          ? null
          : (completedReceipt ?? this.completedReceipt),
    );
  }

  @override
  List<Object?> get props => [
        items,
        discount,
        heldOrders,
        activeHeldOrderId,
        isProcessing,
        errorMessage,
        infoMessage,
        completedReceipt,
      ];
}

part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

final class CartAddItemRequested extends CartEvent {
  const CartAddItemRequested({
    required this.product,
    this.addons = const [],
    this.quantity = 1,
  });

  final ProductModel product;
  final List<AddonModel> addons;
  final int quantity;

  @override
  List<Object?> get props => [product, addons, quantity];
}

final class CartItemIncremented extends CartEvent {
  const CartItemIncremented(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => [lineId];
}

final class CartItemDecremented extends CartEvent {
  const CartItemDecremented(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => [lineId];
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => [lineId];
}

final class CartCleared extends CartEvent {
  const CartCleared();
}

final class CartDiscountApplied extends CartEvent {
  const CartDiscountApplied(this.discount);

  final DiscountModel discount;

  @override
  List<Object?> get props => [discount];
}

final class CartDiscountCleared extends CartEvent {
  const CartDiscountCleared();
}

final class CartHeldOrdersLoaded extends CartEvent {
  const CartHeldOrdersLoaded();
}

final class CartHoldOrderSaved extends CartEvent {
  const CartHoldOrderSaved({required this.label});

  final String label;

  @override
  List<Object?> get props => [label];
}

final class CartHoldOrderResumed extends CartEvent {
  const CartHoldOrderResumed(this.order);

  final HeldOrderModel order;

  @override
  List<Object?> get props => [order];
}

final class CartHoldOrderDeleted extends CartEvent {
  const CartHoldOrderDeleted(this.heldOrderId);

  final int heldOrderId;

  @override
  List<Object?> get props => [heldOrderId];
}

final class CartCheckoutSubmitted extends CartEvent {
  const CartCheckoutSubmitted({
    required this.cashierId,
    required this.cashierName,
    required this.cashReceived,
  });

  final int? cashierId;
  final String cashierName;
  final double cashReceived;

  @override
  List<Object?> get props => [cashierId, cashierName, cashReceived];
}

final class CartFeedbackConsumed extends CartEvent {
  const CartFeedbackConsumed();
}

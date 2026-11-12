part of 'product_bloc.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

final class ProductsLoaded extends ProductEvent {
  const ProductsLoaded({
    this.categoryId,
    this.query,
    this.clearCategory = false,
  });

  final int? categoryId;
  final String? query;
  final bool clearCategory;

  @override
  List<Object?> get props => [categoryId, query, clearCategory];
}

final class ProductAdded extends ProductEvent {
  const ProductAdded({
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    this.pickedImagePath,
  });

  final int categoryId;
  final String name;
  final double price;
  final int stock;
  final String? pickedImagePath;

  @override
  List<Object?> get props => [categoryId, name, price, stock, pickedImagePath];
}

final class ProductUpdated extends ProductEvent {
  const ProductUpdated({
    required this.existing,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    this.pickedImagePath,
    this.removeImage = false,
  });

  final ProductModel existing;
  final int categoryId;
  final String name;
  final double price;
  final int stock;
  final String? pickedImagePath;
  final bool removeImage;

  @override
  List<Object?> get props => [
        existing,
        categoryId,
        name,
        price,
        stock,
        pickedImagePath,
        removeImage,
      ];
}

final class ProductDeleted extends ProductEvent {
  const ProductDeleted(this.product);

  final ProductModel product;

  @override
  List<Object?> get props => [product];
}

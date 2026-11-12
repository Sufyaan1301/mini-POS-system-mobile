part of 'product_bloc.dart';

enum ProductStatus { initial, loading, loaded, submitting }

class ProductState extends Equatable {
  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  final ProductStatus status;
  final List<ProductModel> products;
  final int? selectedCategoryId;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? products,
    int? selectedCategoryId,
    bool clearCategoryId = false,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedCategoryId: clearCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        selectedCategoryId,
        searchQuery,
        errorMessage,
        successMessage,
      ];
}

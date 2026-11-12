import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/app_exception.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({required ProductRepository repository})
      : _repository = repository,
        super(const ProductState()) {
    on<ProductsLoaded>(_onLoaded);
    on<ProductAdded>(_onAdded);
    on<ProductUpdated>(_onUpdated);
    on<ProductDeleted>(_onDeleted);
  }

  final ProductRepository _repository;

  Future<void> _onLoaded(
    ProductsLoaded event,
    Emitter<ProductState> emit,
  ) async {
    final nextCategoryId =
        event.clearCategory ? null : (event.categoryId ?? state.selectedCategoryId);
    final nextQuery = event.query ?? state.searchQuery;

    emit(
      state.copyWith(
        status: ProductStatus.loading,
        selectedCategoryId: nextCategoryId,
        clearCategoryId: event.clearCategory,
        searchQuery: nextQuery,
      ),
    );

    try {
      final list = await _repository.getProducts(
        categoryId: nextCategoryId,
        query: nextQuery,
      );
      emit(state.copyWith(status: ProductStatus.loaded, products: list));
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: ProductStatus.loaded,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onAdded(
    ProductAdded event,
    Emitter<ProductState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.createProduct(
        categoryId: event.categoryId,
        name: event.name,
        price: event.price,
        stock: event.stock,
        pickedImagePath: event.pickedImagePath,
      ),
      'Produk berhasil ditambahkan.',
    );
  }

  Future<void> _onUpdated(
    ProductUpdated event,
    Emitter<ProductState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.updateProduct(
        existing: event.existing,
        categoryId: event.categoryId,
        name: event.name,
        price: event.price,
        stock: event.stock,
        pickedImagePath: event.pickedImagePath,
        removeImage: event.removeImage,
      ),
      'Produk berhasil diperbarui.',
    );
  }

  Future<void> _onDeleted(
    ProductDeleted event,
    Emitter<ProductState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.deleteProduct(event.product),
      'Produk berhasil dihapus.',
    );
  }

  Future<void> _runMutation(
    Emitter<ProductState> emit,
    Future<void> Function() action,
    String successMessage,
  ) async {
    emit(state.copyWith(status: ProductStatus.submitting));
    try {
      await action();
      final list = await _repository.getProducts(
        categoryId: state.selectedCategoryId,
        query: state.searchQuery,
      );
      emit(
        state.copyWith(
          status: ProductStatus.loaded,
          products: list,
          successMessage: successMessage,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: ProductStatus.loaded,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProductStatus.loaded,
          errorMessage: 'Terjadi kesalahan saat memproses produk.',
        ),
      );
    }
  }
}

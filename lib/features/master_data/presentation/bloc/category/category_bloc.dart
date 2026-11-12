import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/app_exception.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({required CategoryRepository repository})
      : _repository = repository,
        super(const CategoryState()) {
    on<CategoriesLoaded>(_onLoaded);
    on<CategoryAdded>(_onAdded);
    on<CategoryUpdated>(_onUpdated);
    on<CategoryDeleted>(_onDeleted);
  }

  final CategoryRepository _repository;

  Future<void> _onLoaded(
    CategoriesLoaded event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    try {
      final list = await _repository.getCategories();
      emit(state.copyWith(status: CategoryStatus.loaded, categories: list));
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.loaded,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onAdded(
    CategoryAdded event,
    Emitter<CategoryState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.createCategory(event.name),
      'Kategori berhasil ditambahkan.',
    );
  }

  Future<void> _onUpdated(
    CategoryUpdated event,
    Emitter<CategoryState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.updateCategory(event.category, event.newName),
      'Kategori berhasil diperbarui.',
    );
  }

  Future<void> _onDeleted(
    CategoryDeleted event,
    Emitter<CategoryState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.deleteCategory(event.id),
      'Kategori berhasil dihapus.',
    );
  }

  Future<void> _runMutation(
    Emitter<CategoryState> emit,
    Future<void> Function() action,
    String successMessage,
  ) async {
    emit(state.copyWith(status: CategoryStatus.submitting));
    try {
      await action();
      final list = await _repository.getCategories();
      emit(
        state.copyWith(
          status: CategoryStatus.loaded,
          categories: list,
          successMessage: successMessage,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.loaded,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CategoryStatus.loaded,
          errorMessage: 'Terjadi kesalahan saat memproses kategori.',
        ),
      );
    }
  }
}

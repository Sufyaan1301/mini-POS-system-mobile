part of 'category_bloc.dart';

enum CategoryStatus { initial, loading, loaded, submitting }

class CategoryState extends Equatable {
  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.errorMessage,
    this.successMessage,
  });

  final CategoryStatus status;
  final List<CategoryModel> categories;
  final String? errorMessage;
  final String? successMessage;

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryModel>? categories,
    String? errorMessage,
    String? successMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, errorMessage, successMessage];
}

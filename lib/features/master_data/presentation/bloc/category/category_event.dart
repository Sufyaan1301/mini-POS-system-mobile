part of 'category_bloc.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

final class CategoriesLoaded extends CategoryEvent {
  const CategoriesLoaded();
}

final class CategoryAdded extends CategoryEvent {
  const CategoryAdded(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class CategoryUpdated extends CategoryEvent {
  const CategoryUpdated({
    required this.category,
    required this.newName,
  });

  final CategoryModel category;
  final String newName;

  @override
  List<Object?> get props => [category, newName];
}

final class CategoryDeleted extends CategoryEvent {
  const CategoryDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

import '../../../../core/error/app_exception.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(String name);
  Future<CategoryModel> updateCategory(CategoryModel category, String newName);
  Future<void> deleteCategory(int id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required CategoryLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final CategoryLocalDataSource _localDataSource;

  @override
  Future<List<CategoryModel>> getCategories() =>
      _localDataSource.getCategories();

  @override
  Future<CategoryModel> createCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Nama kategori tidak boleh kosong.');
    }
    return _localDataSource.createCategory(
      CategoryModel(name: trimmed, createdAt: DateTime.now()),
    );
  }

  @override
  Future<CategoryModel> updateCategory(
    CategoryModel category,
    String newName,
  ) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Nama kategori tidak boleh kosong.');
    }
    return _localDataSource.updateCategory(category.copyWith(name: trimmed));
  }

  @override
  Future<void> deleteCategory(int id) => _localDataSource.deleteCategory(id);
}

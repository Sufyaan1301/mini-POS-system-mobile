import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos_system/core/error/app_exception.dart';
import 'package:mini_pos_system/core/services/image_storage_service.dart';
import 'package:mini_pos_system/features/master_data/data/datasources/addon_local_datasource.dart';
import 'package:mini_pos_system/features/master_data/data/datasources/category_local_datasource.dart';
import 'package:mini_pos_system/features/master_data/data/datasources/product_local_datasource.dart';
import 'package:mini_pos_system/features/master_data/data/models/addon_model.dart';
import 'package:mini_pos_system/features/master_data/data/models/category_model.dart';
import 'package:mini_pos_system/features/master_data/data/models/product_model.dart';
import 'package:mini_pos_system/features/master_data/data/repositories/addon_repository.dart';
import 'package:mini_pos_system/features/master_data/data/repositories/category_repository.dart';
import 'package:mini_pos_system/features/master_data/data/repositories/product_repository.dart';
import 'package:mini_pos_system/features/master_data/presentation/bloc/category/category_bloc.dart';
import 'package:mini_pos_system/features/master_data/presentation/bloc/product/product_bloc.dart';

class _FakeCategoryDataSource implements CategoryLocalDataSource {
  final List<CategoryModel> items = [];
  int _nextId = 1;

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final created = category.copyWith(id: _nextId++);
    items.add(created);
    return created;
  }

  @override
  Future<void> deleteCategory(int id) async {
    items.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<CategoryModel>> getCategories() async => List.unmodifiable(items);

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final idx = items.indexWhere((c) => c.id == category.id);
    if (idx != -1) items[idx] = category;
    return category;
  }
}

class _FakeProductDataSource implements ProductLocalDataSource {
  final List<ProductModel> items = [];
  int _nextId = 1;

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final created = product.copyWith(id: _nextId++);
    items.add(created);
    return created;
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? query,
  }) async {
    return items.where((p) {
      if (p.isDeleted) return false;
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (query != null &&
          query.trim().isNotEmpty &&
          !p.name.toLowerCase().contains(query.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> softDeleteProduct(int id) async {
    final idx = items.indexWhere((p) => p.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(isDeleted: true);
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final idx = items.indexWhere((p) => p.id == product.id);
    if (idx != -1) items[idx] = product;
    return product;
  }
}

class _FakeAddonDataSource implements AddonLocalDataSource {
  final List<AddonModel> items = [];
  int _nextId = 1;

  @override
  Future<AddonModel> createAddon(AddonModel addon) async {
    final created = addon.copyWith(id: _nextId++);
    items.add(created);
    return created;
  }

  @override
  Future<List<AddonModel>> getAddons() async =>
      items.where((a) => !a.isDeleted).toList();

  @override
  Future<void> softDeleteAddon(int id) async {
    final idx = items.indexWhere((a) => a.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(isDeleted: true);
    }
  }

  @override
  Future<AddonModel> updateAddon(AddonModel addon) async {
    final idx = items.indexWhere((a) => a.id == addon.id);
    if (idx != -1) items[idx] = addon;
    return addon;
  }
}

class _FakeImageStorageService extends ImageStorageService {
  final List<String> savedSources = [];
  final List<String> deletedPaths = [];

  @override
  Future<String> saveProductImage(String sourceFilePath) async {
    savedSources.add(sourceFilePath);
    return '/app_docs/product_images/persisted_${savedSources.length}.jpg';
  }

  @override
  Future<void> deleteProductImage(String? imagePath) async {
    if (imagePath != null) deletedPaths.add(imagePath);
  }
}

void main() {
  group('CategoryRepositoryImpl', () {
    late CategoryRepositoryImpl repo;

    setUp(() {
      repo = CategoryRepositoryImpl(
        localDataSource: _FakeCategoryDataSource(),
      );
    });

    test('validates empty name and creates category', () async {
      expect(() => repo.createCategory('   '), throwsA(isA<ValidationException>()));

      final created = await repo.createCategory('Minuman');
      expect(created.id, 1);
      expect(created.name, 'Minuman');
    });
  });

  group('ProductRepositoryImpl', () {
    late _FakeProductDataSource dataSource;
    late _FakeImageStorageService imageService;
    late ProductRepositoryImpl repo;

    setUp(() {
      dataSource = _FakeProductDataSource();
      imageService = _FakeImageStorageService();
      repo = ProductRepositoryImpl(
        localDataSource: dataSource,
        imageStorageService: imageService,
      );
    });

    test('persists picked image into app storage and deletes old on replace',
        () async {
      final created = await repo.createProduct(
        categoryId: 1,
        name: 'Milk Coffee',
        price: 18000,
        stock: 10,
        pickedImagePath: '/cache/temp_camera.jpg',
      );

      expect(created.imagePath, '/app_docs/product_images/persisted_1.jpg');
      expect(imageService.savedSources, ['/cache/temp_camera.jpg']);

      final updated = await repo.updateProduct(
        existing: created,
        categoryId: 1,
        name: 'Milk Coffee Large',
        price: 22000,
        stock: 8,
        pickedImagePath: '/cache/temp_gallery.jpg',
      );

      expect(updated.imagePath, '/app_docs/product_images/persisted_2.jpg');
      expect(
        imageService.deletedPaths,
        ['/app_docs/product_images/persisted_1.jpg'],
      );
    });

    test('rejects negative price or stock', () {
      expect(
        () => repo.createProduct(
          categoryId: 1,
          name: 'Roti',
          price: -1000,
          stock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => repo.createProduct(
          categoryId: 1,
          name: 'Roti',
          price: 10000,
          stock: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('AddonRepositoryImpl', () {
    test('creates, updates, and soft-deletes add-on', () async {
      final repo = AddonRepositoryImpl(localDataSource: _FakeAddonDataSource());
      final addon = await repo.createAddon(
        name: 'Extra Shot',
        price: 5000,
        stock: 15,
      );
      expect((await repo.getAddons()).length, 1);

      final updated = await repo.updateAddon(
        existing: addon,
        name: 'Double Shot',
        price: 8000,
        stock: 12,
      );
      expect(updated.name, 'Double Shot');

      await repo.deleteAddon(updated.id!);
      expect(await repo.getAddons(), isEmpty);
    });
  });

  group('Master Data BLoCs', () {
    test('CategoryBloc emits submitting then loaded with new category', () async {
      final bloc = CategoryBloc(
        repository: CategoryRepositoryImpl(
          localDataSource: _FakeCategoryDataSource(),
        ),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CategoryState>().having(
            (s) => s.status,
            'status',
            CategoryStatus.submitting,
          ),
          isA<CategoryState>()
              .having((s) => s.status, 'status', CategoryStatus.loaded)
              .having((s) => s.categories.length, 'count', 1),
        ]),
      );

      bloc.add(const CategoryAdded('Kopi'));
      await expectation;
      await bloc.close();
    });

    test('ProductBloc filters products by category and query', () async {
      final ds = _FakeProductDataSource();
      final repo = ProductRepositoryImpl(
        localDataSource: ds,
        imageStorageService: _FakeImageStorageService(),
      );
      await repo.createProduct(
        categoryId: 1,
        name: 'Milk Coffee',
        price: 18000,
        stock: 5,
      );
      await repo.createProduct(
        categoryId: 2,
        name: 'Roti Bakar',
        price: 15000,
        stock: 5,
      );

      final bloc = ProductBloc(repository: repo);
      bloc.add(const ProductsLoaded(categoryId: 1, query: 'milk'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.products.length, 1);
      expect(bloc.state.products.first.name, 'Milk Coffee');
      await bloc.close();
    });
  });
}

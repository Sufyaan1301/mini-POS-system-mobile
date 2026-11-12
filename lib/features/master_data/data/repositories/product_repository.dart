import '../../../../core/error/app_exception.dart';
import '../../../../core/services/image_storage_service.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts({int? categoryId, String? query});
  Future<ProductModel> createProduct({
    required int categoryId,
    required String name,
    required double price,
    required int stock,
    String? pickedImagePath,
  });
  Future<ProductModel> updateProduct({
    required ProductModel existing,
    required int categoryId,
    required String name,
    required double price,
    required int stock,
    String? pickedImagePath,
    bool removeImage = false,
  });
  Future<void> deleteProduct(ProductModel product);
}

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required ProductLocalDataSource localDataSource,
    required ImageStorageService imageStorageService,
  })  : _localDataSource = localDataSource,
        _imageStorageService = imageStorageService;

  final ProductLocalDataSource _localDataSource;
  final ImageStorageService _imageStorageService;

  @override
  Future<List<ProductModel>> getProducts({int? categoryId, String? query}) =>
      _localDataSource.getProducts(categoryId: categoryId, query: query);

  @override
  Future<ProductModel> createProduct({
    required int categoryId,
    required String name,
    required double price,
    required int stock,
    String? pickedImagePath,
  }) async {
    final trimmedName = _validateProductInput(name, price, stock);

    String? savedImagePath;
    if (pickedImagePath != null && pickedImagePath.isNotEmpty) {
      savedImagePath = await _imageStorageService.saveProductImage(
        pickedImagePath,
      );
    }

    final now = DateTime.now();
    return _localDataSource.createProduct(
      ProductModel(
        categoryId: categoryId,
        name: trimmedName,
        price: price,
        stock: stock,
        imagePath: savedImagePath,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<ProductModel> updateProduct({
    required ProductModel existing,
    required int categoryId,
    required String name,
    required double price,
    required int stock,
    String? pickedImagePath,
    bool removeImage = false,
  }) async {
    final trimmedName = _validateProductInput(name, price, stock);

    var nextImagePath = existing.imagePath;
    if (removeImage) {
      await _imageStorageService.deleteProductImage(existing.imagePath);
      nextImagePath = null;
    } else if (pickedImagePath != null &&
        pickedImagePath.isNotEmpty &&
        pickedImagePath != existing.imagePath) {
      final saved = await _imageStorageService.saveProductImage(
        pickedImagePath,
      );
      await _imageStorageService.deleteProductImage(existing.imagePath);
      nextImagePath = saved;
    }

    return _localDataSource.updateProduct(
      existing.copyWith(
        categoryId: categoryId,
        name: trimmedName,
        price: price,
        stock: stock,
        imagePath: nextImagePath,
        clearImagePath: removeImage,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteProduct(ProductModel product) async {
    final id = product.id;
    if (id == null) return;
    await _localDataSource.softDeleteProduct(id);
    await _imageStorageService.deleteProductImage(product.imagePath);
  }

  String _validateProductInput(String name, double price, int stock) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Nama produk wajib diisi.');
    }
    if (price < 0) {
      throw const ValidationException('Harga produk tidak boleh negatif.');
    }
    if (stock < 0) {
      throw const ValidationException('Stok produk tidak boleh negatif.');
    }
    return trimmed;
  }
}

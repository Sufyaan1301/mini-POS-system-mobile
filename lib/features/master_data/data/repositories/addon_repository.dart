import '../../../../core/error/app_exception.dart';
import '../datasources/addon_local_datasource.dart';
import '../models/addon_model.dart';

abstract class AddonRepository {
  Future<List<AddonModel>> getAddons();
  Future<AddonModel> createAddon({
    required String name,
    required double price,
    required int stock,
  });
  Future<AddonModel> updateAddon({
    required AddonModel existing,
    required String name,
    required double price,
    required int stock,
  });
  Future<void> deleteAddon(int id);
}

class AddonRepositoryImpl implements AddonRepository {
  AddonRepositoryImpl({required AddonLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final AddonLocalDataSource _localDataSource;

  @override
  Future<List<AddonModel>> getAddons() => _localDataSource.getAddons();

  @override
  Future<AddonModel> createAddon({
    required String name,
    required double price,
    required int stock,
  }) {
    final trimmed = _validateInput(name, price, stock);
    final now = DateTime.now();
    return _localDataSource.createAddon(
      AddonModel(
        name: trimmed,
        price: price,
        stock: stock,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<AddonModel> updateAddon({
    required AddonModel existing,
    required String name,
    required double price,
    required int stock,
  }) {
    final trimmed = _validateInput(name, price, stock);
    return _localDataSource.updateAddon(
      existing.copyWith(
        name: trimmed,
        price: price,
        stock: stock,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteAddon(int id) => _localDataSource.softDeleteAddon(id);

  String _validateInput(String name, double price, int stock) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Nama add-on wajib diisi.');
    }
    if (price < 0) {
      throw const ValidationException('Harga add-on tidak boleh negatif.');
    }
    if (stock < 0) {
      throw const ValidationException('Stok add-on tidak boleh negatif.');
    }
    return trimmed;
  }
}

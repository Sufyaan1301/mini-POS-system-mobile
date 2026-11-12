import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide configuration values loaded from `.env`.
class AppConstants {
  AppConstants._();

  static String _env(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final value = dotenv.env[key];
    return (value == null || value.isEmpty) ? fallback : value;
  }

  static String get appName => _env('APP_NAME', 'Mini POS');

  static String get defaultStoreName =>
      _env('DEFAULT_STORE_NAME', 'Daya Cafe & Retail');

  static String get defaultStoreAddress => _env('DEFAULT_STORE_ADDRESS', '-');

  static String get defaultStorePhone => _env('DEFAULT_STORE_PHONE', '-');

  static int get lowStockThreshold =>
      int.tryParse(_env('LOW_STOCK_THRESHOLD', '5')) ?? 5;

  static String get dbName => _env('DB_NAME', 'mini_pos_system.db');

  static int get dbVersion => int.tryParse(_env('DB_VERSION', '1')) ?? 1;
}

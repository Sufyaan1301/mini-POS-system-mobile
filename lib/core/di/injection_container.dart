import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/master_data/data/datasources/addon_local_datasource.dart';
import '../../features/master_data/data/datasources/category_local_datasource.dart';
import '../../features/master_data/data/datasources/product_local_datasource.dart';
import '../../features/master_data/data/repositories/addon_repository.dart';
import '../../features/master_data/data/repositories/category_repository.dart';
import '../../features/master_data/data/repositories/product_repository.dart';
import '../../features/master_data/presentation/bloc/addon/addon_bloc.dart';
import '../../features/master_data/presentation/bloc/category/category_bloc.dart';
import '../../features/master_data/presentation/bloc/product/product_bloc.dart';
import '../../features/pos/data/datasources/pos_local_datasource.dart';
import '../../features/pos/data/repositories/pos_repository.dart';
import '../../features/pos/presentation/bloc/cart/cart_bloc.dart';
import '../../features/report/data/datasources/report_local_datasource.dart';
import '../../features/report/data/repositories/report_repository.dart';
import '../../features/report/presentation/bloc/report_bloc.dart';
import '../database/app_database.dart';
import '../services/image_storage_service.dart';
import '../services/secure_session_service.dart';

final GetIt sl = GetIt.instance;

/// Registers core services, datasources, repositories, and BLoCs.
Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);
  sl.registerLazySingleton<SecureSessionService>(() => SecureSessionService());
  sl.registerLazySingleton<ImageStorageService>(() => ImageStorageService());

  // Feature: Auth
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      sessionService: sl(),
    ),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl()),
  );

  // Feature: Master Data
  sl.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<AddonLocalDataSource>(
    () => AddonLocalDataSourceImpl(database: sl()),
  );

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      localDataSource: sl(),
      imageStorageService: sl(),
    ),
  );
  sl.registerLazySingleton<AddonRepository>(
    () => AddonRepositoryImpl(localDataSource: sl()),
  );

  sl.registerFactory<CategoryBloc>(() => CategoryBloc(repository: sl()));
  sl.registerFactory<ProductBloc>(() => ProductBloc(repository: sl()));
  sl.registerFactory<AddonBloc>(() => AddonBloc(repository: sl()));

  // Feature: POS
  sl.registerLazySingleton<PosLocalDataSource>(
    () => PosLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<PosRepository>(
    () => PosRepositoryImpl(
      posLocalDataSource: sl(),
      productLocalDataSource: sl(),
      addonLocalDataSource: sl(),
    ),
  );
  sl.registerFactory<CartBloc>(
    () => CartBloc(
      posRepository: sl(),
      productRepository: sl(),
      addonRepository: sl(),
    ),
  );

  // Feature: Report
  sl.registerLazySingleton<ReportLocalDataSource>(
    () => ReportLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(localDataSource: sl()),
  );
  sl.registerFactory<ReportBloc>(
    () => ReportBloc(repository: sl()),
  );
}

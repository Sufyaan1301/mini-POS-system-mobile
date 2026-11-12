import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/master_data/presentation/bloc/addon/addon_bloc.dart';
import 'features/master_data/presentation/bloc/category/category_bloc.dart';
import 'features/master_data/presentation/bloc/product/product_bloc.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/report/presentation/bloc/report_bloc.dart';

class MiniPosApp extends StatelessWidget {
  const MiniPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<CategoryBloc>(create: (_) => sl<CategoryBloc>()),
        BlocProvider<ProductBloc>(create: (_) => sl<ProductBloc>()),
        BlocProvider<AddonBloc>(create: (_) => sl<AddonBloc>()),
        BlocProvider<CartBloc>(create: (_) => sl<CartBloc>()),
        BlocProvider<ReportBloc>(create: (_) => sl<ReportBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}

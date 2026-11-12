import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/addon/addon_bloc.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/product/product_bloc.dart';
import '../widgets/addon_form_dialog.dart';
import '../widgets/addon_tab_view.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tab_view.dart';
import '../widgets/product_tab_view.dart';
import 'product_form_page.dart';

class MasterDataPage extends StatefulWidget {
  const MasterDataPage({super.key});

  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    context.read<CategoryBloc>().add(const CategoriesLoaded());
    context.read<ProductBloc>().add(const ProductsLoaded());
    context.read<AddonBloc>().add(const AddonsLoaded());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onFabPressed() async {
    switch (_tabController.index) {
      case 0:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductFormPage()),
        );
        break;
      case 1:
        final name = await showCategoryFormDialog(context);
        if (name == null || !mounted) return;
        context.read<CategoryBloc>().add(CategoryAdded(name));
        break;
      case 2:
        final result = await showAddonFormDialog(context);
        if (result == null || !mounted) return;
        context.read<AddonBloc>().add(
              AddonAdded(
                name: result.name,
                price: result.price,
                stock: result.stock,
              ),
            );
        break;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CategoryBloc, CategoryState>(
          listenWhen: (prev, curr) =>
              curr.errorMessage != null || curr.successMessage != null,
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnack(state.errorMessage!, isError: true);
            } else if (state.successMessage != null) {
              _showSnack(state.successMessage!);
            }
          },
        ),
        BlocListener<ProductBloc, ProductState>(
          listenWhen: (prev, curr) =>
              curr.errorMessage != null || curr.successMessage != null,
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnack(state.errorMessage!, isError: true);
            } else if (state.successMessage != null) {
              _showSnack(state.successMessage!);
            }
          },
        ),
        BlocListener<AddonBloc, AddonState>(
          listenWhen: (prev, curr) =>
              curr.errorMessage != null || curr.successMessage != null,
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnack(state.errorMessage!, isError: true);
            } else if (state.successMessage != null) {
              _showSnack(state.successMessage!);
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Master Data'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produk'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Kategori'),
              Tab(icon: Icon(Icons.extension_outlined), text: 'Add-on'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            ProductTabView(),
            CategoryTabView(),
            AddonTabView(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onFabPressed,
          icon: const Icon(Icons.add),
          label: Text(
            switch (_tabController.index) {
              0 => 'Produk',
              1 => 'Kategori',
              _ => 'Add-on',
            },
          ),
        ),
      ),
    );
  }
}

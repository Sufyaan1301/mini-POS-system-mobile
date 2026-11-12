import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../data/models/product_model.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/product/product_bloc.dart';
import '../pages/product_form_page.dart';
import 'product_image_widget.dart';
import 'stock_badge.dart';

class ProductTabView extends StatefulWidget {
  const ProductTabView({super.key});

  @override
  State<ProductTabView> createState() => _ProductTabViewState();
}

class _ProductTabViewState extends State<ProductTabView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(BuildContext context, ProductModel product) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Produk',
      message: 'Yakin ingin menghapus "${product.name}"? '
          'Riwayat transaksi lama tetap aman.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<ProductBloc>().add(ProductDeleted(product));
  }

  void _openEdit(BuildContext context, ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(existing: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state.status == ProductStatus.loading &&
                  state.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.products.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'Belum ada produk',
                  subtitle:
                      'Tambahkan kategori terlebih dahulu, lalu tekan tombol + untuk menambah produk.',
                );
              }

              final isTablet = ResponsiveLayout.isTablet(context);
              if (isTablet) {
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        ResponsiveLayout.isTabletLandscape(context) ? 3 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.3,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(context, state.products[index]),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: state.products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildProductCard(context, state.products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (query) =>
                context.read<ProductBloc>().add(ProductsLoaded(query: query)),
            decoration: InputDecoration(
              hintText: 'Cari nama produk...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<ProductBloc>()
                            .add(const ProductsLoaded(query: ''));
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, catState) {
              final selectedId =
                  context.watch<ProductBloc>().state.selectedCategoryId;

              return SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Semua'),
                        selected: selectedId == null,
                        onSelected: (_) => context
                            .read<ProductBloc>()
                            .add(const ProductsLoaded(clearCategory: true)),
                      ),
                    ),
                    ...catState.categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: selectedId == c.id,
                          onSelected: (_) => context
                              .read<ProductBloc>()
                              .add(ProductsLoaded(categoryId: c.id)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openEdit(context, product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductImageWidget(
                imagePath: product.imagePath,
                width: 64,
                height: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.categoryName ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        StockBadge(stock: product.stock, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _openEdit(context, product),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Hapus',
                onPressed: () => _deleteProduct(context, product),
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../master_data/data/models/addon_model.dart';
import '../../../master_data/data/models/product_model.dart';
import '../../../master_data/presentation/bloc/addon/addon_bloc.dart';
import '../../../master_data/presentation/bloc/category/category_bloc.dart';
import '../../../master_data/presentation/bloc/product/product_bloc.dart';
import '../../../master_data/presentation/widgets/product_image_widget.dart';
import '../../../master_data/presentation/widgets/stock_badge.dart';
import '../bloc/cart/cart_bloc.dart';
import '../widgets/addon_selector_sheet.dart';
import '../widgets/cart_panel.dart';
import '../widgets/held_orders_sheet.dart';
import 'payment_page.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoriesLoaded());
    context
        .read<ProductBloc>()
        .add(const ProductsLoaded(clearCategory: true, query: ''));
    context.read<AddonBloc>().add(const AddonsLoaded());
    context.read<CartBloc>().add(const CartHeldOrdersLoaded());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onProductTap(
    ProductModel product,
    List<AddonModel> addons,
  ) async {
    if (addons.isEmpty) {
      context.read<CartBloc>().add(CartAddItemRequested(product: product));
      return;
    }

    final result = await showAddonSelectorSheet(
      context,
      product: product,
      availableAddons: addons,
    );
    if (result == null || !mounted) return;

    context.read<CartBloc>().add(
          CartAddItemRequested(
            product: product,
            addons: result.addons,
            quantity: result.quantity,
          ),
        );
  }

  void _quickAddPlain(ProductModel product) {
    context.read<CartBloc>().add(CartAddItemRequested(product: product));
  }

  void _goToPayment({bool closeBottomSheetFirst = false}) {
    if (closeBottomSheetFirst) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentPage()),
    );
  }

  void _openMobileCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: CartPanel(
          onCheckoutPressed: () => _goToPayment(closeBottomSheetFirst: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return BlocListener<CartBloc, CartState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null || curr.infoMessage != null,
      listener: (context, state) {
        final msg = state.errorMessage ?? state.infoMessage;
        if (msg == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: state.errorMessage != null
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          );
        context.read<CartBloc>().add(const CartFeedbackConsumed());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kasir POS'),
          actions: [
            BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                final count = cartState.heldOrders.length;
                return IconButton(
                  tooltip: 'Hold Bills',
                  onPressed: () => showHeldOrdersSheet(context),
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.pause_circle_outline_rounded),
                  ),
                );
              },
            ),
          ],
        ),
        body: isTablet
            ? Row(
                children: [
                  Expanded(child: _buildCatalogArea()),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: ResponsiveLayout.isTabletLandscape(context)
                        ? 390
                        : 330,
                    child: CartPanel(onCheckoutPressed: _goToPayment),
                  ),
                ],
              )
            : _buildCatalogArea(),
        bottomNavigationBar: isTablet ? null : _buildMobileCartBar(),
      ),
    );
  }

  Widget _buildCatalogArea() {
    return Column(
      children: [
        _buildSearchAndCategories(),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              if (productState.status == ProductStatus.loading &&
                  productState.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productState.products.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.storefront_outlined,
                  title: 'Produk tidak ditemukan',
                  subtitle:
                      'Tambahkan produk di Master Data atau ubah kata kunci pencarian.',
                );
              }

              final addons = context.watch<AddonBloc>().state.addons;
              final cartState = context.watch<CartBloc>().state;
              final width = MediaQuery.sizeOf(context).width;
              final crossAxisCount = width >= 1100
                  ? 4
                  : width >= 850
                      ? 3
                      : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: productState.products.length,
                itemBuilder: (context, index) {
                  final product = productState.products[index];
                  final productId = product.id ?? -1;
                  final remaining =
                      (product.stock - cartState.consumedProductStock(productId))
                          .clamp(0, product.stock);
                  final isOut = remaining <= 0;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: isOut
                          ? () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Stok "${product.name}" habis.',
                                ),
                              ),
                            )
                          : () => _onProductTap(product, addons),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ProductImageWidget(
                                      imagePath: product.imagePath,
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: 10,
                                      iconSize: 34,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: StockBadge(
                                      stock: remaining,
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.categoryName ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    CurrencyFormatter.format(product.price),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: IconButton.filled(
                                    padding: EdgeInsets.zero,
                                    iconSize: 18,
                                    onPressed: isOut
                                        ? null
                                        : () => _quickAddPlain(product),
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndCategories() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (query) =>
                context.read<ProductBloc>().add(ProductsLoaded(query: query)),
            decoration: InputDecoration(
              hintText: 'Cari produk cepat...',
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
          const SizedBox(height: 8),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, catState) {
              final selectedId =
                  context.watch<ProductBloc>().state.selectedCategoryId;

              return SizedBox(
                height: 36,
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

  Widget _buildMobileCartBar() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _openMobileCartSheet,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.totalQuantity} item di keranjang',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(state.total),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _openMobileCartSheet,
                  child: const Text('Keranjang'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: state.items.isNotEmpty ? _goToPayment : null,
                  child: const Text('Bayar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

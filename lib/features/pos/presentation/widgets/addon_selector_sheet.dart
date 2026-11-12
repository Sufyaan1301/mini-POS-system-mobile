import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../master_data/data/models/addon_model.dart';
import '../../../master_data/data/models/product_model.dart';
import '../../../master_data/presentation/widgets/product_image_widget.dart';
import '../bloc/cart/cart_bloc.dart';

class AddonSelectionResult {
  const AddonSelectionResult({
    required this.addons,
    required this.quantity,
  });

  final List<AddonModel> addons;
  final int quantity;
}

/// Modal sheet for choosing add-ons and quantity before adding to cart.
Future<AddonSelectionResult?> showAddonSelectorSheet(
  BuildContext context, {
  required ProductModel product,
  required List<AddonModel> availableAddons,
}) {
  return showModalBottomSheet<AddonSelectionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddonSelectorSheet(
      product: product,
      availableAddons: availableAddons,
    ),
  );
}

class _AddonSelectorSheet extends StatefulWidget {
  const _AddonSelectorSheet({
    required this.product,
    required this.availableAddons,
  });

  final ProductModel product;
  final List<AddonModel> availableAddons;

  @override
  State<_AddonSelectorSheet> createState() => _AddonSelectorSheetState();
}

class _AddonSelectorSheetState extends State<_AddonSelectorSheet> {
  final Set<int> _selectedAddonIds = {};
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    final productId = widget.product.id ?? -1;
    final remainingProduct =
        (widget.product.stock - cartState.consumedProductStock(productId))
            .clamp(0, widget.product.stock);

    final selectedAddons = widget.availableAddons
        .where((a) => a.id != null && _selectedAddonIds.contains(a.id))
        .toList();

    var maxAllowedQty = remainingProduct;
    for (final addon in selectedAddons) {
      final remAddon =
          (addon.stock - cartState.consumedAddonStock(addon.id!))
              .clamp(0, addon.stock);
      if (remAddon < maxAllowedQty) {
        maxAllowedQty = remAddon;
      }
    }

    if (_quantity > maxAllowedQty && maxAllowedQty > 0) {
      _quantity = maxAllowedQty;
    }

    final unitAddonsTotal =
        selectedAddons.fold<double>(0, (sum, a) => sum + a.price);
    final totalPrice = (widget.product.price + unitAddonsTotal) * _quantity;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProductImageWidget(
                  imagePath: widget.product.imagePath,
                  width: 56,
                  height: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(widget.product.price)} • Tersisa $remainingProduct',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jumlah',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: _quantity < maxAllowedQty
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.availableAddons.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Pilih Add-on / Topping',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableAddons.length,
                  itemBuilder: (context, index) {
                    final addon = widget.availableAddons[index];
                    final id = addon.id;
                    if (id == null) return const SizedBox.shrink();

                    final remainingAddon =
                        (addon.stock - cartState.consumedAddonStock(id))
                            .clamp(0, addon.stock);
                    final isSelected = _selectedAddonIds.contains(id);
                    final canSelect = isSelected || remainingAddon >= _quantity;

                    return CheckboxListTile(
                      value: isSelected,
                      enabled: canSelect && remainingAddon > 0,
                      contentPadding: EdgeInsets.zero,
                      title: Text(addon.name),
                      subtitle: Text(
                        '+ ${CurrencyFormatter.format(addon.price)} • Sisa $remainingAddon',
                      ),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedAddonIds.add(id);
                          } else {
                            _selectedAddonIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Tambah • ${CurrencyFormatter.format(totalPrice)}',
              icon: Icons.add_shopping_cart_rounded,
              onPressed: maxAllowedQty > 0
                  ? () => Navigator.of(context).pop(
                        AddonSelectionResult(
                          addons: selectedAddons,
                          quantity: _quantity,
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

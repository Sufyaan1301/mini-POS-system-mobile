import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../data/models/discount_model.dart';
import '../bloc/cart/cart_bloc.dart';
import 'discount_dialog.dart';

/// Reusable cart panel used in both Tablet split-screen and Mobile bottom sheet.
class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.onCheckoutPressed,
  });

  final VoidCallback onCheckoutPressed;

  Future<void> _openDiscountDialog(
    BuildContext context,
    CartState state,
  ) async {
    final result = await showDiscountDialog(
      context,
      subtotal: state.subtotal,
      currentDiscount: state.discount,
    );
    if (result == null || !context.mounted) return;
    if (result.type == DiscountType.none) {
      context.read<CartBloc>().add(const CartDiscountCleared());
    } else {
      context.read<CartBloc>().add(CartDiscountApplied(result));
    }
  }

  Future<void> _promptHoldBill(BuildContext context) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => const _HoldBillDialog(),
    );
    if (label == null || !context.mounted) return;
    context.read<CartBloc>().add(CartHoldOrderSaved(label: label));
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Kosongkan Keranjang',
      message: 'Hapus semua item di keranjang saat ini?',
      confirmLabel: 'Kosongkan',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    context.read<CartBloc>().add(const CartCleared());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, state),
            const Divider(height: 1),
            Expanded(
              child: state.items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Keranjang kosong',
                      subtitle: 'Tap produk untuk menambahkan ke pesanan.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(
                                              item.unitPrice,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => context
                                          .read<CartBloc>()
                                          .add(CartItemRemoved(item.lineId)),
                                      icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.addons.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: item.addons
                                        .map(
                                          (a) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '+ ${a.name} (${CurrencyFormatter.format(a.price)})',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _qtyButton(
                                          icon: Icons.remove,
                                          onTap: () => context
                                              .read<CartBloc>()
                                              .add(
                                                CartItemDecremented(
                                                  item.lineId,
                                                ),
                                              ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        _qtyButton(
                                          icon: Icons.add,
                                          onTap: () => context
                                              .read<CartBloc>()
                                              .add(
                                                CartItemIncremented(
                                                  item.lineId,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                        item.lineSubtotal,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            _buildFooter(context, state),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CartState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keranjang (${state.totalQuantity})',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (state.items.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () => _promptHoldBill(context),
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: const Text('Hold'),
            ),
            IconButton(
              tooltip: 'Kosongkan',
              onPressed: () => _confirmClearCart(context),
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, CartState state) {
    final hasItems = state.items.isNotEmpty;
    final hasDiscount = state.discount.type != DiscountType.none;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(
                CurrencyFormatter.format(state.subtotal),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap:
                    hasItems ? () => _openDiscountDialog(context, state) : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.discount_outlined,
                      size: 16,
                      color: hasItems
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasDiscount
                          ? (state.discount.type == DiscountType.percent
                              ? 'Diskon (${state.discount.value.toStringAsFixed(0)}%)'
                              : 'Diskon (Rp)')
                          : 'Tambah Diskon',
                      style: TextStyle(
                        color: hasItems
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                state.discountAmount > 0
                    ? '- ${CurrencyFormatter.format(state.discountAmount)}'
                    : 'Rp 0',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: state.discountAmount > 0
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                CurrencyFormatter.format(state.total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Bayar',
            icon: Icons.payments_rounded,
            onPressed: hasItems ? onCheckoutPressed : null,
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }
}

class _HoldBillDialog extends StatefulWidget {
  const _HoldBillDialog();

  @override
  State<_HoldBillDialog> createState() => _HoldBillDialogState();
}

class _HoldBillDialogState extends State<_HoldBillDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Simpan Bill (Hold)'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Label / Nama Pelanggan (opsional)',
          hintText: 'Contoh: Meja 4 / Pak Budi',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

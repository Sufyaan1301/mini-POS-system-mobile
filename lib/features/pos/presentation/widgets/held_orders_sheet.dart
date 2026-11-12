import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../bloc/cart/cart_bloc.dart';

/// Displays temporarily saved bills (Hold / Save Bill) to resume or delete.
Future<void> showHeldOrdersSheet(BuildContext context) {
  context.read<CartBloc>().add(const CartHeldOrdersLoaded());
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _HeldOrdersSheet(),
  );
}

class _HeldOrdersSheet extends StatelessWidget {
  const _HeldOrdersSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bill Tersimpan (Hold Bill)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  if (state.heldOrders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: EmptyStateWidget(
                        icon: Icons.pause_circle_outline_rounded,
                        title: 'Belum ada bill tersimpan',
                        subtitle:
                            'Gunakan tombol Hold di keranjang untuk menyimpan pesanan sementara.',
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.heldOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = state.heldOrders[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            order.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${order.totalItems} item • ${CurrencyFormatter.format(order.subtotal)}\n'
                            '${DateFormatter.formatReceipt(order.createdAt)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  context
                                      .read<CartBloc>()
                                      .add(CartHoldOrderResumed(order));
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Muat'),
                              ),
                              IconButton(
                                onPressed: order.id == null
                                    ? null
                                    : () => context
                                        .read<CartBloc>()
                                        .add(CartHoldOrderDeleted(order.id!)),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

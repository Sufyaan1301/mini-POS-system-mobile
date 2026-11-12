import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../data/models/addon_model.dart';
import '../bloc/addon/addon_bloc.dart';
import 'addon_form_dialog.dart';
import 'stock_badge.dart';

class AddonTabView extends StatelessWidget {
  const AddonTabView({super.key});

  Future<void> _editAddon(BuildContext context, AddonModel addon) async {
    final result = await showAddonFormDialog(context, existing: addon);
    if (result == null || !context.mounted) return;
    context.read<AddonBloc>().add(
          AddonUpdated(
            existing: addon,
            name: result.name,
            price: result.price,
            stock: result.stock,
          ),
        );
  }

  Future<void> _deleteAddon(BuildContext context, AddonModel addon) async {
    final id = addon.id;
    if (id == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Add-on',
      message: 'Yakin ingin menghapus add-on "${addon.name}"?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<AddonBloc>().add(AddonDeleted(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddonBloc, AddonState>(
      builder: (context, state) {
        if (state.status == AddonStatus.loading && state.addons.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.addons.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.add_box_outlined,
            title: 'Belum ada add-on / topping',
            subtitle:
                'Tekan tombol + di kanan bawah untuk menambahkan add-on seperti Extra Shot atau Boba.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: state.addons.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final addon = state.addons[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.extension_outlined),
                ),
                title: Text(
                  addon.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '+ ${CurrencyFormatter.format(addon.price)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      StockBadge(stock: addon.stock, compact: true),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _editAddon(context, addon),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: () => _deleteAddon(context, addon),
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
    );
  }
}

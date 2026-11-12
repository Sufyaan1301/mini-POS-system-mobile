import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/product/product_bloc.dart';
import 'category_form_dialog.dart';

class CategoryTabView extends StatelessWidget {
  const CategoryTabView({super.key});

  Future<void> _editCategory(BuildContext context, dynamic category) async {
    final newName = await showCategoryFormDialog(context, existing: category);
    if (newName == null || !context.mounted) return;
    context.read<CategoryBloc>().add(
          CategoryUpdated(category: category, newName: newName),
        );
    // Refresh product list in case joined category names changed.
    context.read<ProductBloc>().add(const ProductsLoaded());
  }

  Future<void> _deleteCategory(
    BuildContext context,
    int id,
    String name,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Kategori',
      message: 'Yakin ingin menghapus kategori "$name"?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<CategoryBloc>().add(CategoryDeleted(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state.status == CategoryStatus.loading &&
            state.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.categories.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.category_outlined,
            title: 'Belum ada kategori',
            subtitle: 'Tekan tombol + di kanan bawah untuk membuat kategori.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: state.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final category = state.categories[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.label_outline),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Dibuat: ${DateFormatter.formatDateOnly(category.createdAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _editCategory(context, category),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: category.id == null
                          ? null
                          : () => _deleteCategory(
                                context,
                                category.id!,
                                category.name,
                              ),
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

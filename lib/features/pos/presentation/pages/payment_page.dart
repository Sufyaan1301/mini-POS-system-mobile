import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../master_data/presentation/bloc/addon/addon_bloc.dart';
import '../../../master_data/presentation/bloc/product/product_bloc.dart';
import '../bloc/cart/cart_bloc.dart';
import 'receipt_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _cashController = TextEditingController();
  double _cashReceived = 0;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setCash(double amount) {
    final intAmount = amount.round();
    _cashController.text = intAmount.toString();
    setState(() => _cashReceived = intAmount.toDouble());
  }

  List<double> _buildQuickCashOptions(double total) {
    final presets = <double>{
      total.ceilToDouble(),
      10000,
      20000,
      50000,
      100000,
    }.where((amt) => amt >= total).toList()
      ..sort();
    return presets.take(5).toList();
  }

  void _submitPayment(BuildContext context, CartState cartState) {
    if (_cashReceived < cartState.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal tunai kurang dari total tagihan.'),
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final cashier =
        authState is AuthAuthenticated ? authState.cashier : null;

    context.read<CartBloc>().add(
          CartCheckoutSubmitted(
            cashierId: cashier?.id,
            cashierName: cashier?.name ?? 'Kasir',
            cashReceived: _cashReceived,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          context.read<CartBloc>().add(const CartFeedbackConsumed());
        } else if (state.completedReceipt != null) {
          final receipt = state.completedReceipt!;
          // Refresh catalog stock after atomic stock deduction.
          context.read<ProductBloc>().add(const ProductsLoaded());
          context.read<AddonBloc>().add(const AddonsLoaded());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ReceiptPage(receipt: receipt),
            ),
          );
        }
      },
      builder: (context, state) {
        final total = state.total;
        final change = _cashReceived - total;
        final isEnough = _cashReceived >= total && state.items.isNotEmpty;
        final quickAmounts = _buildQuickCashOptions(total);

        return Scaffold(
          appBar: AppBar(title: const Text('Pembayaran')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _summaryRow(
                              'Total Item',
                              '${state.totalQuantity} item',
                            ),
                            const SizedBox(height: 6),
                            _summaryRow(
                              'Subtotal',
                              CurrencyFormatter.format(state.subtotal),
                            ),
                            if (state.discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              _summaryRow(
                                'Diskon',
                                '- ${CurrencyFormatter.format(state.discountAmount)}',
                                valueColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            ],
                            const Divider(height: 22),
                            _summaryRow(
                              'Total Tagihan',
                              CurrencyFormatter.format(total),
                              isBold: true,
                              fontSize: 18,
                              valueColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _cashController,
                              label: 'Uang Tunai Diterima (Rp)',
                              hint: 'Masukkan nominal bayar',
                              prefixIcon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _cashReceived =
                                      double.tryParse(value.trim()) ?? 0;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Quick Cash',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: quickAmounts.map((amt) {
                                final isExact = amt == total.ceilToDouble();
                                return ActionChip(
                                  label: Text(
                                    isExact
                                        ? 'Uang Pas'
                                        : CurrencyFormatter.format(amt),
                                  ),
                                  onPressed: () => _setCash(amt),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 24),
                            _summaryRow(
                              'Kembalian',
                              change >= 0
                                  ? CurrencyFormatter.format(change)
                                  : 'Kurang ${CurrencyFormatter.format(change.abs())}',
                              isBold: true,
                              fontSize: 16,
                              valueColor: change >= 0
                                  ? AppTheme.successColor
                                  : AppTheme.dangerColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Proses Pembayaran',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: state.isProcessing,
                      onPressed: isEnough
                          ? () => _submitPayment(context, state)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

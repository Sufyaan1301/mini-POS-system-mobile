import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pos/presentation/widgets/receipt_preview_card.dart';
import '../bloc/report_bloc.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    required this.invoiceNumber,
  });

  final int transactionId;
  final String invoiceNumber;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<ReportBloc>()
        .add(ReportTransactionDetailRequested(widget.transactionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.invoiceNumber)),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          if (state.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = state.selectedDetail;
          if (detail == null) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Detail transaksi tidak tersedia.',
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ReceiptPreviewCard(receipt: detail),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../bloc/report_bloc.dart';
import '../widgets/revenue_bar_chart.dart';
import '../widgets/sales_summary_cards.dart';
import '../widgets/top_products_card.dart';
import 'transaction_detail_page.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(const ReportLoaded());
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: context.read<ReportBloc>().state.customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
    );
    if (picked == null || !mounted) return;
    context.read<ReportBloc>().add(
          ReportLoaded(
            preset: ReportDatePreset.custom,
            customRange: picked,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analitik Penjualan'),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            onPressed: () => context.read<ReportBloc>().add(const ReportLoaded()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          final report = state.report;

          return Column(
            children: [
              _buildFilterBar(state),
              Expanded(
                child: state.status == ReportStatus.loading && report == null
                    ? const Center(child: CircularProgressIndicator())
                    : report == null
                        ? Center(
                            child: Text(
                              state.errorMessage ?? 'Gagal memuat laporan.',
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => context
                                .read<ReportBloc>()
                                .add(const ReportLoaded()),
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                SalesSummaryCards(report: report),
                                const SizedBox(height: 14),
                                if (isTablet)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: RevenueBarChart(
                                          points: report.dailySeries,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: TopProductsCard(
                                          products: report.topProducts,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  RevenueBarChart(points: report.dailySeries),
                                  const SizedBox(height: 14),
                                  TopProductsCard(products: report.topProducts),
                                ],
                                const SizedBox(height: 18),
                                const Text(
                                  'Riwayat Transaksi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (report.transactions.isEmpty)
                                  const Card(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 24),
                                      child: EmptyStateWidget(
                                        icon: Icons.receipt_outlined,
                                        title: 'Belum ada transaksi',
                                        subtitle:
                                            'Transaksi yang berhasil diproses akan muncul di sini.',
                                      ),
                                    ),
                                  )
                                else
                                  ...report.transactions.map(
                                    (tx) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            child: Icon(Icons.receipt_long),
                                          ),
                                          title: Text(
                                            tx.invoiceNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${DateFormatter.formatReceipt(tx.createdAt)} • Kasir: ${tx.cashierName}',
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(
                                                  tx.total,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                              const Text(
                                                'Lihat Struk',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          onTap: tx.id == null
                                              ? null
                                              : () => Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          TransactionDetailPage(
                                                        transactionId: tx.id!,
                                                        invoiceNumber:
                                                            tx.invoiceNumber,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(ReportState state) {
    final presets = <(ReportDatePreset, String)>[
      (ReportDatePreset.today, 'Hari Ini'),
      (ReportDatePreset.last7Days, '7 Hari'),
      (ReportDatePreset.last30Days, '30 Hari'),
      (ReportDatePreset.all, 'Semua'),
    ];

    final customLabel = state.preset == ReportDatePreset.custom &&
            state.customRange != null
        ? '${DateFormatter.formatDateOnly(state.customRange!.start)} - '
            '${DateFormatter.formatDateOnly(state.customRange!.end)}'
        : 'Pilih Tanggal';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...presets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.$2),
                  selected: state.preset == item.$1,
                  onSelected: (_) => context
                      .read<ReportBloc>()
                      .add(ReportLoaded(preset: item.$1)),
                ),
              ),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.date_range, size: 16),
              label: Text(customLabel),
              selected: state.preset == ReportDatePreset.custom,
              onSelected: (_) => _pickCustomRange(),
            ),
          ],
        ),
      ),
    );
  }
}

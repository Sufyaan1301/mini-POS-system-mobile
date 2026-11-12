import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/data/models/cashier_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../master_data/presentation/pages/master_data_page.dart';
import '../../../report/presentation/pages/sales_dashboard_page.dart';
import 'cashier_page.dart';

/// Main authenticated shell hosting Kasir, Master Data, and Report navigation.
class HomeShellPage extends StatelessWidget {
  const HomeShellPage({
    super.key,
    required this.cashier,
  });

  final CashierModel cashier;

  Future<void> _onLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar Akun',
      message: 'Yakin ingin logout dari akun ${cashier.name}?',
      confirmLabel: 'Logout',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.defaultStoreName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Kasir: ${cashier.name} (@${cashier.username})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () => _onLogout(context),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: ResponsiveLayout.isTabletLandscape(context)
                    ? 3
                    : (isTablet ? 2 : 1),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isTablet ? 2.1 : 2.6,
                children: [
                  _MenuCard(
                    icon: Icons.point_of_sale_rounded,
                    color: AppTheme.primaryColor,
                    title: 'Kasir / Transaksi',
                    subtitle: 'Catat pesanan, add-on, diskon & cetak struk',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CashierPage()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF2563EB),
                    title: 'Master Data',
                    subtitle: 'Kelola Kategori, Produk, Foto & Add-on',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MasterDataPage()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.bar_chart_rounded,
                    color: AppTheme.secondaryColor,
                    title: 'Laporan Penjualan',
                    subtitle: 'Ringkasan omzet, grafik & riwayat transaksi',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SalesDashboardPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

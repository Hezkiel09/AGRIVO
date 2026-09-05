import 'package:flutter/material.dart';

import '../../core/app_routes.dart';
import '../../services/api_service.dart';

import 'package:agrivo/screens/umkm/umkm_orders_screen.dart';
import 'package:agrivo/screens/profile/petani_orders_screen.dart';

import 'edit_profile_screen.dart';
import 'financial_detail_screen.dart';
import 'my_products_screen.dart';
import 'scan_history_screen.dart';
import 'auction_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final profile = await ApiService.getProfile();
    final role = (profile?['role'] ?? '').toString().toLowerCase();

    Map<String, dynamic>? dashboard;
    if (role == 'umkm') {
      dashboard = await ApiService.getUmkmDashboard();
    } else {
      dashboard = await ApiService.getFarmerDashboard();
    }

    if (mounted) {
      setState(() {
        _profileData = profile;
        _dashboardData = dashboard;
        _isLoading = false;
      });
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
  }

  String _formatRupiah(int number) {
    String str = number.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      result = str[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    String fullName = _profileData?['full_name'] ?? 'Pengguna';
    String role = _profileData?['role'] ?? '';
    bool isUmkm = role.toLowerCase() == 'umkm';
    String displayRole = isUmkm ? 'Mitra UMKM' : 'Petani';
    String initials = _getInitials(fullName);

    String formattedSales = _dashboardData?['formatted_sales'] ?? 'Rp 0';
    String activeOrders = _dashboardData?['active_orders']?.toString() ?? '0';
    String totalProducts = _dashboardData?['total_products']?.toString() ?? '0';
    String totalOrders = _dashboardData?['total_orders']?.toString() ?? '0';
    final int saldo =
        (_profileData?['saldo'] as num?)?.toInt() ??
        (_dashboardData?['saldo'] as num?)?.toInt() ??
        0;
    final String formattedSaldo = _formatRupiah(saldo);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'PROFIL SAYA',
          style: TextStyle(
            color: Color(0xFF1B4F1E),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        actions: [
          if (!_isLoading && _profileData != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1B4F1E)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(currentData: _profileData!),
                  ),
                ).then((_) => _fetchData());
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: 20,
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF1B4F1E),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayRole,
                          style: const TextStyle(
                            color: Color(0xFF1B4F1E),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: isUmkm
                        ? [
                            // Tampilan khusus UMKM: Saldo (dapat di-tap untuk Top Up / cek keuangan), Pesanan Aktif, Total Pesanan
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_profileData != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FinancialDetailScreen(
                                          initialProfileData: _profileData!,
                                        ),
                                      ),
                                    ).then((_) => _fetchData());
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: _buildStatCard(formattedSaldo, 'Saldo'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UmkmOrdersScreen(),
                                    ),
                                  ).then((_) => _fetchData());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: _buildStatCard(
                                  activeOrders,
                                  'Pesanan Aktif',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                totalOrders,
                                'Total Pesanan',
                              ),
                            ),
                          ]
                        : [
                            // Tampilan khusus Petani: Total Omset, Pesanan Aktif, Total Produk
                            Expanded(
                              child: _buildStatCard(
                                formattedSales,
                                'Total Omset',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PetaniOrdersScreen(),
                                    ),
                                  ).then((_) => _fetchData());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: _buildStatCard(
                                  activeOrders,
                                  'Pesanan Aktif',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                totalProducts,
                                'Total Produk',
                              ),
                            ),
                          ],
                  ),
                  const SizedBox(height: 24),

                  // Menu Options: Berbeda untuk Petani vs UMKM
                  if (!isUmkm) ...[
                    _buildMenuOption(
                      Icons.local_shipping_outlined,
                      'Pesanan Masuk',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PetaniOrdersScreen(),
                          ),
                        ).then((_) => _fetchData());
                      },
                    ),
                    _buildMenuOption(
                      Icons.shopping_bag_outlined,
                      'Dagangan Saya',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyProductsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      Icons.history,
                      'Riwayat Scan & Grade',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      Icons.gavel,
                      'Penawaran Masuk',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuctionHistoryScreen(
                              initialRole: 'petani',
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    _buildMenuOption(
                      Icons.receipt_long_outlined,
                      'Pesanan Saya',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UmkmOrdersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      Icons.gavel,
                      'Tawaran Saya',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AuctionHistoryScreen(initialRole: 'umkm'),
                          ),
                        );
                      },
                    ),
                  ],

                  const Divider(),
                  _buildMenuOption(
                    Icons.logout,
                    'Keluar',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1B4F1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String text, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: color ?? const Color(0xFF1B4F1E)),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }
}

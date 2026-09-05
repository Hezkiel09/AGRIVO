import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';
import 'package:agrivo/widgets/umkm/umkm_header.dart';
import 'package:agrivo/widgets/umkm/umkm_order_status_card.dart';
import 'package:agrivo/widgets/umkm/umkm_quick_menu.dart';
import 'package:agrivo/widgets/umkm/umkm_live_auction_card.dart';
import 'package:agrivo/widgets/umkm/umkm_recommendation_card.dart';
import 'package:agrivo/screens/umkm/umkm_orders_screen.dart';
import 'package:agrivo/screens/market/product_detail_screen.dart';

class UmkmHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const UmkmHomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<UmkmHomeScreen> createState() => _UmkmHomeScreenState();
}

class _UmkmHomeScreenState extends State<UmkmHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUmkmDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUmkmDashboard() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getUmkmDashboard();
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B4F1E)),
      );
    }

    final businessName = _dashboardData?['business_name']?.toString() ??
        _dashboardData?['full_name']?.toString() ??
        'Toko Buah Sehat';
    final activeOrders = (_dashboardData?['active_orders'] as num?)?.toInt() ?? 0;
    final featuredAuction = _dashboardData?['featured_auction'] as Map<String, dynamic>?;
    final recommendations = _dashboardData?['recommendations'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _fetchUmkmDashboard,
      color: const Color(0xFF1B4F1E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Avatar, Greeting, Store Name, Notification Bell)
            UmkmHeader(
              businessName: businessName,
              onNotificationTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Belum ada notifikasi baru.')),
                );
              },
            ),
            const SizedBox(height: 18),

            // 2. Search Bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade500, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari produk / buah...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13.5),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (query) {
                        widget.onNavigateTab?.call(1); // Pindah ke tab Pasar
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Status Pesanan Card
            UmkmOrderStatusCard(
              activeOrders: activeOrders,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UmkmOrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // 4. Quick Menu (Marketplace, Pesanan, Live Bid, Komunitas)
            UmkmQuickMenu(
              onMarketplaceTap: () => widget.onNavigateTab?.call(1),
              onPesananTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UmkmOrdersScreen()),
                );
              },
              onLiveBidTap: () => widget.onNavigateTab?.call(1),
              onKomunitasTap: () => widget.onNavigateTab?.call(3),
            ),
            const SizedBox(height: 24),

            // 5. Featured Live Auction Card
            UmkmLiveAuctionCard(
              product: featuredAuction,
              onBidTap: () {
                if (featuredAuction != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: featuredAuction),
                    ),
                  );
                } else {
                  widget.onNavigateTab?.call(1);
                }
              },
            ),
            const SizedBox(height: 26),

            // 6. Rekomendasi Untukmu Section
            UmkmRecommendationSection(
              recommendations: recommendations,
              onSeeAllTap: () => widget.onNavigateTab?.call(1),
              onProductTap: (product) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

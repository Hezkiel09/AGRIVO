import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';
import 'package:agrivo/services/cart_service.dart';
import 'package:agrivo/widgets/market_promo_banner.dart';
import 'package:agrivo/widgets/live_bid_card.dart';
import 'package:agrivo/widgets/market_product_card.dart';
import 'cart_screen.dart';
import 'create_product_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final CartService _cartService = CartService();

  List<dynamic> _liveBids = [];
  List<dynamic> _directBuys = [];
  List<dynamic> _allProducts = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    String? categoryFilter;
    if (_selectedCategory == 'Buah') {
      categoryFilter = 'Buah';
    } else if (_selectedCategory == 'Sayur') {
      categoryFilter = 'Sayuran';
    }

    final products = await ApiService.getProducts(
      category: categoryFilter,
      search: _searchController.text.trim(),
    );

    _liveBids = [];
    _directBuys = [];

    for (var product in products) {
      if (product['sales_mode'] == 'live_bid') {
        _liveBids.add(product);
      } else {
        _directBuys.add(product);
      }
    }

    if (_selectedCategory == 'Live Bid') {
      _allProducts = List.from(_liveBids);
    } else if (_selectedCategory == 'Beli Langsung') {
      _allProducts = List.from(_directBuys);
    } else {
      _allProducts = List.from(products);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchingOrFiltered =
        _selectedCategory != 'Semua' || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar (Matching Mockup)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pasar AGRIVO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4F1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      // Cart Icon with Dynamic Badge
                      ListenableBuilder(
                        listenable: _cartService,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Color(0xFF1B4F1E),
                                  size: 26,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                              if (_cartService.totalItemCount > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE53935),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      '${_cartService.totalItemCount}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      // Profile Avatar Circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1B4F1E),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Field (Matching Mockup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchProducts(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari buah atau hasil bumi segar...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchProducts();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Category Filter Chips (Semua, Live Bid, Beli Langsung, Buah, Sayur)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildPillChip('Semua', icon: Icons.grid_view_rounded),
                  const SizedBox(width: 8),
                  _buildPillChip('Live Bid', icon: Icons.sensors, iconColor: const Color(0xFFE53935)),
                  const SizedBox(width: 8),
                  _buildPillChip('Beli Langsung', icon: Icons.shopping_cart_outlined, iconColor: const Color(0xFF1B4F1E)),
                  const SizedBox(width: 8),
                  _buildPillChip('Buah', icon: Icons.apple_rounded),
                  const SizedBox(width: 8),
                  _buildPillChip('Sayur', icon: Icons.eco_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Main Body Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchProducts,
                color: const Color(0xFF1B4F1E),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4F1E)))
                    : isSearchingOrFiltered
                        ? _buildFilteredGridView()
                        : _buildMainMarketFeed(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip(String label, {IconData? icon, Color? iconColor}) {
    final bool isSelected = _selectedCategory == label;
    final Color activeIconColor = isSelected ? Colors.white : (iconColor ?? const Color(0xFF2E7D32));
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
        _fetchProducts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4F1E) : const Color(0xFFF1F5F0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4F1E) : const Color(0xFFE2E8E0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: activeIconColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View when not searching: Full rich marketplace home feed
  Widget _buildMainMarketFeed() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      children: [
        // Promo Panen Raya Banner
        MarketPromoBanner(
          onShopNow: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voucher diskon 15% Panen Raya otomatis diterapkan di Keranjang!'),
                backgroundColor: Color(0xFF1B4F1E),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Live Bid Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Row(
              children: const [
                Text(
                  'Live Bid',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.sensors, color: Color(0xFFE53935), size: 18),
              ],
            ),
            GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = 'Live Bid');
                _fetchProducts();
              },
              child: const Text(
                'Selengkapnya',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Dapatkan harga terbaik secara live, tawar sekarang, kirim langsung!',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),

        // Horizontal Live Bid Carousel
        if (_liveBids.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Belum ada produk Live Bid aktif saat ini',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 245,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _liveBids.length,
              itemBuilder: (context, index) {
                final item = _liveBids[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: LiveBidCard(product: item),
                );
              },
            ),
          ),
        const SizedBox(height: 26),

        // Beli Langsung Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Row(
              children: const [
                Text(
                  'Beli Langsung',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.shopping_cart_outlined, color: Color(0xFF1B4F1E), size: 18),
              ],
            ),
            GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = 'Beli Langsung');
                _fetchProducts();
              },
              child: const Text(
                'Selengkapnya',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Beli langsung dari petani terbaik',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),

        // 2-Column Direct Buy Grid
        if (_directBuys.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Belum ada produk Beli Langsung saat ini',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _directBuys.length,
            itemBuilder: (context, index) {
              final item = _directBuys[index] as Map<String, dynamic>;
              return MarketProductCard(product: item);
            },
          ),
      ],
    );
  }

  // View when searching or filtered
  Widget _buildFilteredGridView() {
    if (_allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil untuk "$_selectedCategory"',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba kata kunci lain atau pilih Semua.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_selectedCategory == 'Live Bid') {
      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _allProducts.length,
        itemBuilder: (context, index) {
          final item = _allProducts[index] as Map<String, dynamic>;
          return LiveBidCard(product: item);
        },
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        final item = _allProducts[index] as Map<String, dynamic>;
        return MarketProductCard(product: item);
      },
    );
  }
}

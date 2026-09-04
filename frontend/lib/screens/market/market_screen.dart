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

  // Demo fallback items for rich visual showcase matching mockup
  final List<Map<String, dynamic>> _demoLiveBids = [
    {
      'id': 'demo_live_1',
      'name': 'Nanas Madu Pemalang',
      'image_path': 'assets/images/boxscanfruit.png',
      'grade': 'Grade A',
      'price': '505.000',
      'seller_name': 'Petani Subur Jaya',
      'location': 'Pemalang, Jawa Tengah',
      'stock': 50,
      'unit': 'kg',
      'sales_mode': 'live_bid',
      'expiry_time': DateTime.now().add(const Duration(hours: 1, minutes: 15)).toIso8601String(),
      'description': 'Nanas madu asli Pemalang dengan rasa manis legit dan kadar air tinggi. Dipetik pada tingkat kematangan optimal.',
    },
    {
      'id': 'demo_live_2',
      'name': 'Anggur Ciwidey Super',
      'image_path': 'assets/images/apel1.png',
      'grade': 'Grade A',
      'price': '42.000',
      'seller_name': 'Kebun Berkah Jaya',
      'location': 'Ciwidey, Bandung',
      'stock': 30,
      'unit': 'kg',
      'sales_mode': 'live_bid',
      'expiry_time': DateTime.now().add(const Duration(hours: 1, minutes: 15)).toIso8601String(),
      'description': 'Anggur segar perkebunan Ciwidey dengan bulir besar, renyah, dan manis segar tanpa biji berlebih.',
    },
  ];

  final List<Map<String, dynamic>> _demoDirectBuys = [
    {
      'id': 'demo_direct_1',
      'name': 'Manggis Super Wanayasa',
      'image_path': 'assets/images/boxscanfruit.png',
      'grade': 'Grade A',
      'price': '35.000',
      'seller_name': 'Lahan Makmur',
      'location': 'Depok',
      'stock': 40,
      'unit': 'kg',
      'sales_mode': 'market',
      'description': 'Manggis ratu buah kualitas ekspor dengan daging putih bersih tebal, asam manis segar sempurna.',
    },
    {
      'id': 'demo_direct_2',
      'name': 'Alpukat Mentega Jumbo',
      'image_path': 'assets/images/apel1.png',
      'grade': 'Grade A',
      'price': '48.000',
      'seller_name': 'Kelompok Tani Sejahtera',
      'location': 'Lembang',
      'stock': 25,
      'unit': 'kg',
      'sales_mode': 'market',
      'description': 'Alpukat mentega daging tebal tanpa serat, rasa gurih legit creamy dan kaya nutrisi sehat.',
    },
    {
      'id': 'demo_direct_3',
      'name': 'Tomat Beef Hidroponik',
      'image_path': 'assets/images/boxscanfruit.png',
      'grade': 'Grade A',
      'price': '18.000',
      'seller_name': 'Agro Mandiri',
      'location': 'Bogor',
      'stock': 60,
      'unit': 'kg',
      'sales_mode': 'market',
      'description': 'Tomat beef segar ditanam hidroponik modern, kulit kencang mulus dan daging padat berair.',
    },
    {
      'id': 'demo_direct_4',
      'name': 'Jeruk Sunkist Fresh',
      'image_path': 'assets/images/apel1.png',
      'grade': 'Grade A',
      'price': '26.000',
      'seller_name': 'Kebun Berkah Jaya',
      'location': 'Malang',
      'stock': 35,
      'unit': 'kg',
      'sales_mode': 'market',
      'description': 'Jeruk manis segar kaya vitamin C, kulit mulus mudah dikupas dan sari buah melimpah.',
    },
  ];

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
    _allProducts = products;

    for (var product in products) {
      if (product['sales_mode'] == 'live_bid') {
        _liveBids.add(product);
      } else {
        _directBuys.add(product);
      }
    }

    // If backend has no data yet, merge demo items so UI is rich and never empty
    if (_liveBids.isEmpty && _searchController.text.isEmpty && _selectedCategory == 'Semua') {
      _liveBids = List.from(_demoLiveBids);
    }
    if (_directBuys.isEmpty && _searchController.text.isEmpty && _selectedCategory == 'Semua') {
      _directBuys = List.from(_demoDirectBuys);
    }
    if (_allProducts.isEmpty && _searchController.text.isEmpty && _selectedCategory == 'Semua') {
      _allProducts = [..._demoLiveBids, ..._demoDirectBuys];
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

            // 3. Category Filter Chips (Matching Mockup: Semua, Buah, Sayur)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildPillChip('Semua'),
                  const SizedBox(width: 10),
                  _buildPillChip('Buah'),
                  const SizedBox(width: 10),
                  _buildPillChip('Sayur'),
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

  Widget _buildPillChip(String label) {
    final bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
        _fetchProducts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4F1E) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
          ),
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
                setState(() => _selectedCategory = 'Buah');
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
                setState(() => _selectedCategory = 'Sayur');
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

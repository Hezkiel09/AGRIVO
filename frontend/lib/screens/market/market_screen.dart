import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _liveBids = [];
  List<dynamic> _directBuys = [];
  List<dynamic> _allProducts = []; // Used for grid view

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    // Update UI every minute to refresh the countdown
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
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
    setState(() {
      _isLoading = true;
    });

    final products = await ApiService.getProducts(
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
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

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimeLeft(String? expiryTimeIso) {
    if (expiryTimeIso == null) return "Tidak diketahui";
    try {
      DateTime expiry = DateTime.parse(expiryTimeIso);
      Duration diff = expiry.difference(DateTime.now());
      if (diff.isNegative) return "Kadaluarsa";
      int hours = diff.inHours;
      int minutes = diff.inMinutes.remainder(60);
      return "${hours.toString().padLeft(2, '0')}j ${minutes.toString().padLeft(2, '0')}m";
    } catch (e) {
      return "Format salah";
    }
  }

  bool _isExpired(String? expiryTimeIso) {
    if (expiryTimeIso == null) return false;
    try {
      DateTime expiry = DateTime.parse(expiryTimeIso);
      return expiry.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    if (imagePath.startsWith("http")) return imagePath;
    return "${ApiService.baseUrl}/$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchingOrFiltered =
        _selectedCategory != 'Semua' ||
        _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'PASAR TANI',
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
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchProducts(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari hasil panen, lelang, sayuran...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('Semua'),
                      _buildCategoryChip('Sayuran'),
                      _buildCategoryChip('Buah-buahan'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Listings
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : isSearchingOrFiltered
                ? _buildGridView()
                : _buildCarouselView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String text) {
    bool isSelected = _selectedCategory == text;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = text;
            });
            _fetchProducts();
          }
        },
        selectedColor: const Color(0xFF1B4F1E),
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildGridView() {
    if (_allProducts.isEmpty) {
      return const Center(
        child: Text("Belum ada produk di pencarian/kategori ini."),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Adjust for card height
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_allProducts[index]);
      },
    );
  }

  Widget _buildCarouselView() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        // Live Bid Section
        if (_liveBids.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Lelang Sedang Berlangsung 🔥',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4F1E),
                  ),
                ),
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250, // Fixed height for carousel cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: _liveBids.length,
              itemBuilder: (context, index) {
                var product = _liveBids[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: _buildProductCard(product),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Direct Buy Section (Now also a carousel)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Beli Langsung dari Kebun 🥬',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F1E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_directBuys.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Belum ada produk di bagian ini.",
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: _directBuys.length,
              itemBuilder: (context, index) {
                var product = _directBuys[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: _buildProductCard(product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(dynamic product) {
    String name = product['name'] ?? 'Tanpa Nama';
    String imgUrl = _getFullImageUrl(product['image_path']);
    String grade = product['grade'] ?? 'A';
    String price = product['price']?.toString() ?? '0';
    String shopName = product['seller_name'] ?? 'Petani Agrivo';
    bool isLiveBid = product['sales_mode'] == 'live_bid';
    String timeStr = isLiveBid ? _formatTimeLeft(product['expiry_time']) : '';
    bool expired = isLiveBid && _isExpired(product['expiry_time']);

    return Opacity(
      opacity: expired ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with AI Grade Overlay
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: imgUrl.isNotEmpty
                        ? Image.network(
                            imgUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  // AI Grade Overlay Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4F1E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI $grade',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expired or Live Bid Timer Badge
                  if (isLiveBid)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: expired
                              ? Colors.red.withOpacity(0.9)
                              : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Text Content Area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Rp $price',
                          style: const TextStyle(
                            color: Color(0xFF1B4F1E),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Plus Button
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Color(0xFF1B4F1E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

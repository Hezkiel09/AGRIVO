import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';
import '../market/create_product_screen.dart';
import '../market/product_detail_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMyProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyProducts() async {
    setState(() => _isLoading = true);
    final products = await ApiService.getMyProducts();
    if (mounted) {
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    }
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    if (imagePath.startsWith("http")) return imagePath;
    if (imagePath.startsWith("assets/")) return imagePath;
    return "${ApiService.baseUrl}/$imagePath";
  }

  bool _isExpired(String? expiryTimeIso) {
    if (expiryTimeIso == null) return false;
    try {
      DateTime expiry = DateTime.parse(expiryTimeIso);
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatTimeLeft(String? expiryTimeIso) {
    if (expiryTimeIso == null) return "Waktu tidak ditentukan";
    try {
      DateTime expiry = DateTime.parse(expiryTimeIso);
      Duration diff = expiry.difference(DateTime.now());
      if (diff.isNegative) return "Live Bid Selesai";
      int hours = diff.inHours;
      int minutes = diff.inMinutes.remainder(60);
      return "$hours jam $minutes menit tersisa";
    } catch (_) {
      return "-";
    }
  }

  void _showExtendDialog(Map<String, dynamic> product) {
    int selectedHours = 6;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Perpanjang Live Bid',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produk: ${product['name']}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih durasi tambahan waktu penawaran live bid:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [1, 6, 12, 24].map((h) {
                  final bool isSelected = selectedHours == h;
                  return ChoiceChip(
                    label: Text('$h Jam'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B4F1E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedHours = h);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final productId = product['id'] is int ? product['id'] : int.tryParse(product['id'].toString()) ?? 0;
                      final success = await ApiService.extendLiveBid(productId, selectedHours);
                      setDialogState(() => isSubmitting = false);

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Waktu Live Bid berhasil diperpanjang $selectedHours jam!'
                                  : 'Gagal memperpanjang waktu.',
                            ),
                            backgroundColor: success ? const Color(0xFF1B4F1E) : Colors.red,
                          ),
                        );
                        if (success) _fetchMyProducts();
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F1E)),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Perpanjang', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text('Produk ini akan dihapus dari pasar dan tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteProduct(productId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Produk berhasil dihapus' : 'Gagal menghapus produk'),
                    backgroundColor: success ? const Color(0xFF1B4F1E) : Colors.red,
                  ),
                );
                if (success) _fetchMyProducts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Dagangan Saya',
          style: TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1B4F1E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1B4F1E),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Beli Langsung'),
            Tab(text: 'Live Bid'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4F1E)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_allProducts),
                _buildProductList(_allProducts.where((p) => p['sales_mode'] != 'live_bid').toList()),
                _buildProductList(_allProducts.where((p) => p['sales_mode'] == 'live_bid').toList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          );
          _fetchMyProducts();
        },
        backgroundColor: const Color(0xFF1B4F1E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Jual Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Belum ada produk di kategori ini',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan tombol + Jual Produk untuk menambahkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyProducts,
      color: const Color(0xFF1B4F1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final p = items[index] as Map<String, dynamic>;
          final bool isLiveBid = p['sales_mode'] == 'live_bid';
          final bool expired = isLiveBid && _isExpired(p['expiry_time']);
          final String imagePath = p['image_path'] ?? '';
          final int productId = p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFFF3F7F2),
                          child: imagePath.isNotEmpty
                              ? Image.network(
                                  _getFullImageUrl(imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.eco, color: Colors.green, size: 30),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.eco, color: Colors.green, size: 30),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p['name'] ?? 'Produk',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isLiveBid
                                        ? (expired ? Colors.grey.shade200 : const Color(0xFFFFEBEE))
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isLiveBid ? (expired ? 'Live Selesai' : 'Live Bid') : 'Beli Langsung',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isLiveBid
                                          ? (expired ? Colors.grey.shade700 : const Color(0xFFE53935))
                                          : const Color(0xFF1B4F1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Harga: Rp ${p['price']} / ${p['unit'] ?? 'kg'}',
                              style: const TextStyle(
                                color: Color(0xFF1B4F1E),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stok: ${p['stock']} ${p['unit'] ?? 'kg'} • Grade: ${p['grade'] ?? 'Grade A'}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                            ),
                            if (isLiveBid) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                                    size: 13,
                                    color: expired ? Colors.red : Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimeLeft(p['expiry_time']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: expired ? Colors.red : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Lihat Detail di Pasar
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B4F1E)),
                      ),
                      // Perpanjang Waktu jika Live Bid
                      if (isLiveBid) ...[
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () => _showExtendDialog(p),
                          icon: const Icon(Icons.more_time, size: 15, color: Colors.white),
                          label: const Text('Perpanjang', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: expired ? const Color(0xFFE53935) : const Color(0xFF1B4F1E),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      // Hapus Produk
                      IconButton(
                        onPressed: () => _confirmDelete(productId),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Hapus Produk',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

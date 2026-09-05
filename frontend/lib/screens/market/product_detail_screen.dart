import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';
import 'package:agrivo/services/cart_service.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  final CartService _cartService = CartService();

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    if (imagePath.startsWith("http")) return imagePath;
    if (imagePath.startsWith("assets/")) return imagePath;
    return "${ApiService.baseUrl}/$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final String name = product['name'] ?? 'Hasil Panen';
    final String imagePath = product['image_path'] ?? '';
    final String grade = product['grade'] ?? 'Grade A';
    final String priceStr = product['price']?.toString() ?? '0';
    final int priceNum = CartService.parsePrice(priceStr);
    final String unit = product['unit'] ?? 'kg';
    final int stock = product['stock'] is int ? product['stock'] : (int.tryParse(product['stock']?.toString() ?? '10') ?? 10);
    final String category = product['category'] ?? 'Sayuran & Buah';
    final String description = product['description'] != null && product['description'].toString().isNotEmpty
        ? product['description']
        : 'Hasil panen segar langsung dipetik dari kebun petani mitra Agrivo. Diproses dengan standar mutu terbaik, bebas pestisida berlebih, dan terverifikasi grade kualitasnya menggunakan kecerdasan buatan computer vision Agrivo.';
    final String sellerName = product['seller_name'] ?? product['farm_name'] ?? 'Petani Subur Jaya';
    final String location = product['location'] ?? 'Depok, Jawa Barat';
    final bool isLiveBid = product['sales_mode'] == 'live_bid';
    bool isExpired = false;
    if (isLiveBid && product['expiry_time'] != null) {
      try {
        isExpired = DateTime.parse(product['expiry_time']).isBefore(DateTime.now());
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isLiveBid ? 'Detail Lelang Live Bid' : 'Detail Produk',
          style: const TextStyle(
            color: Color(0xFF1B4F1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // Cart Icon with Badge
          ListenableBuilder(
            listenable: _cartService,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1B4F1E), size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (_cartService.totalItemCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Banner Area
            Container(
              width: double.infinity,
              height: 280,
              color: const Color(0xFFF1F5F0),
              child: Stack(
                children: [
                  Center(
                    child: imagePath.startsWith('assets/')
                        ? Image.asset(
                            imagePath,
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.eco, size: 80, color: Colors.green),
                          )
                        : imagePath.isNotEmpty
                            ? Image.network(
                                _getFullImageUrl(imagePath),
                                width: double.infinity,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.eco, size: 80, color: Colors.green),
                              )
                            : const Icon(Icons.eco, size: 80, color: Colors.green),
                  ),
                  // Grade Pill Overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4F1E).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, color: Color(0xFF76FF03), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'AI $grade • Terverifikasi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status Mode Pill Overlay
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLiveBid ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isLiveBid ? Icons.sensors : Icons.check_circle_outline, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            isLiveBid ? 'Live Bid Lelang' : 'Beli Langsung',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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

            // 2. Product Title & Price Card
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLiveBid && isExpired)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.timer_off_outlined, color: Color(0xFFE11D48), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lelang Live Bid untuk produk ini telah selesai.',
                              style: TextStyle(
                                color: Color(0xFF9F1239),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceStr.startsWith('Rp') ? priceStr : 'Rp $priceStr',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F1E),
                        ),
                      ),
                      Text(
                        ' / $unit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '4.9',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(98 Ulasan)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Text(
                        'Stok: $stock $unit',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Seller / Farmer Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF1B4F1E), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sellerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka profil kebun $sellerName...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1B4F1E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Lihat Kebun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F1E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Description & Panen Info Card
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi & Deskripsi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade700,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Specification Pills Row
                  Row(
                    children: [
                      _buildSpecItem(Icons.eco_outlined, 'Metode', 'Organik Alami'),
                      _buildSpecItem(Icons.inventory_2_outlined, 'Kualitas', 'Grade Super'),
                      _buildSpecItem(Icons.local_shipping_outlined, 'Pengiriman', 'Langsung'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120), // Bottom padding for sticky bar
          ],
        ),
      ),

      // 5. Bottom Sticky Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Stepper (if Direct Buy)
              if (!isLiveBid) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        color: const Color(0xFF1B4F1E),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _quantity < stock ? () => setState(() => _quantity++) : null,
                        color: const Color(0xFF1B4F1E),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Add to Cart Button (Icon / Outline)
              if (!isLiveBid)
                InkWell(
                  onTap: () {
                    _cartService.addToCart(product, quantity: _quantity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text('$_quantity $unit $name ditambahkan ke keranjang!')),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1B4F1E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF1B4F1E), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_shopping_cart, color: Color(0xFF1B4F1E)),
                  ),
                ),
              if (!isLiveBid) const SizedBox(width: 12),

              // Main Action Button (Beli Sekarang or Tawar Lelang)
              Expanded(
                child: ElevatedButton(
                  onPressed: (isLiveBid && isExpired)
                      ? null
                      : () {
                          if (isLiveBid) {
                            _showBidDialog(context, product, name, priceNum);
                          } else {
                            _cartService.addToCart(product, quantity: _quantity);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isLiveBid && isExpired) ? const Color(0xFF94A3B8) : const Color(0xFF1B4F1E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    disabledForegroundColor: const Color(0xFF64748B),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isLiveBid
                        ? (isExpired ? 'Live Bid Selesai' : 'Tawar Sekarang (Bid)')
                        : 'Beli Langsung',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1B4F1E)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, Map<String, dynamic> product, String productName, int currentPrice) {
    final TextEditingController bidController = TextEditingController(text: '${currentPrice + 10000}');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Ajukan Tawaran $productName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Harga dasar / tawaran saat ini:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(
                'Rp $currentPrice',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4F1E)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Tawaran Anda',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tawaran Anda akan masuk ke daftar penawaran petani dan dapat disetujui selama live bid berlangsung.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                      final int bidAmount = int.tryParse(bidController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      if (bidAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Masukkan nominal tawaran yang valid!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (bidAmount <= currentPrice) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tawaran harus lebih tinggi dari harga saat ini!'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final productId = product['id'] is int ? product['id'] : int.tryParse(product['id'].toString()) ?? 0;
                      final res = await ApiService.createBid(productId, bidAmount);
                      setDialogState(() => isSubmitting = false);

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Tawaran diajukan'),
                            backgroundColor: res['success'] == true ? const Color(0xFF1B4F1E) : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F1E)),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kirim Tawaran', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}


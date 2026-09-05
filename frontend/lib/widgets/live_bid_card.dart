import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';
import '../screens/market/product_detail_screen.dart';

class LiveBidCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onBidTap;

  const LiveBidCard({
    super.key,
    required this.product,
    this.onBidTap,
  });

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
    if (expiryTimeIso == null) return "1h 15m left";
    try {
      DateTime expiry = DateTime.parse(expiryTimeIso);
      Duration diff = expiry.difference(DateTime.now());
      if (diff.isNegative) return "Selesai";
      int hours = diff.inHours;
      int minutes = diff.inMinutes.remainder(60);
      return "${hours}h ${minutes}m left";
    } catch (e) {
      return "1h 15m left";
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = product['name'] ?? 'Hasil Panen';
    String imagePath = product['image_path'] ?? '';
    String grade = product['grade'] ?? 'Grade A';
    String price = product['price']?.toString() ?? '0';
    String sellerName = product['seller_name'] ?? product['farm_name'] ?? 'Petani Subur Jaya';
    String weight = product['unit'] != null ? '${product['stock'] ?? 50}${product['unit']}' : '50kg';
    bool expired = _isExpired(product['expiry_time']);
    String timerStr = _formatTimeLeft(product['expiry_time']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: const Color(0xFFF3F7F2),
                    child: imagePath.startsWith('assets/')
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.eco, color: Colors.green, size: 40),
                            ),
                          )
                        : imagePath.isNotEmpty
                            ? Image.network(
                                _getFullImageUrl(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.eco, color: Colors.green, size: 40),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.eco, color: Colors.green, size: 40),
                              ),
                  ),
                ),
                // AI Grade Badge Top Left
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4F1E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF76FF03), size: 11),
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
                // Timer & Live Pill Bottom of Image
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: expired
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.timer_off_outlined, color: Colors.white70, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Live Bid Selesai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timer Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                timerStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Live Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.circle, color: Colors.white, size: 6),
                                  SizedBox(width: 3),
                                  Text(
                                    'Live',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            // Content info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farmer and Weight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sellerName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.scale, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            weight,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Product Title
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Price and Bid Now Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price.startsWith('Rp') ? price : 'Rp $price',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F1E),
                        ),
                      ),
                      GestureDetector(
                        onTap: expired
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lelang Live Bid untuk produk ini sudah selesai.'),
                                    backgroundColor: Color(0xFF64748B),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : (onBidTap ??
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(product: product),
                                    ),
                                  );
                                }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: expired ? const Color(0xFFE2E8F0) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            expired ? 'Selesai' : 'Bid Now',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: expired ? const Color(0xFF64748B) : const Color(0xFF1B4F1E),
                            ),
                          ),
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

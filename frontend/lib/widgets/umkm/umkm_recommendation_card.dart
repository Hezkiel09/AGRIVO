import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agrivo/services/api_service.dart';

class UmkmRecommendationSection extends StatelessWidget {
  final List<dynamic> recommendations;
  final VoidCallback? onSeeAllTap;
  final Function(Map<String, dynamic>)? onProductTap;

  const UmkmRecommendationSection({
    super.key,
    required this.recommendations,
    this.onSeeAllTap,
    this.onProductTap,
  });

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return "Rp 0/kg";
    String pStr = rawPrice.toString();
    if (pStr.startsWith('Rp')) return pStr;
    int? val = int.tryParse(pStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (val != null) {
      return "Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/kg";
    }
    return "Rp $pStr/kg";
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    if (imagePath.startsWith("http")) return imagePath;
    if (imagePath.startsWith("assets/")) return imagePath;
    return "${ApiService.baseUrl}/$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rekomendasi Untukmu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F1E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
            ),
            child: Center(
              child: Text(
                'Belum ada produk beli langsung tersedia saat ini.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ...recommendations.take(3).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildSingleCard(context, product: p as Map<String, dynamic>),
              )),
      ],
    );
  }

  Widget _buildSingleCard(BuildContext context, {required Map<String, dynamic> product}) {
    final name = product['name'] ?? 'Produk';
    final category = product['category'] ?? 'Beli Langsung';
    final priceStr = _formatPrice(product['price']);
    final imagePath = product['image_path'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: _buildImage(imagePath),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          priceStr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F1E),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F5E8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Kualitas Terjamin',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4F1E),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: () => onProductTap?.call(product),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B4F1E),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Lihat Produk',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? path) {
    final fullUrl = _getFullImageUrl(path);
    if (fullUrl.isNotEmpty) {
      if (fullUrl.startsWith('http')) {
        return Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      if (fullUrl.startsWith('assets/')) {
        return Image.asset(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      if (!kIsWeb && File(fullUrl).existsSync()) {
        return Image.file(File(fullUrl), fit: BoxFit.cover);
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF3F7F2),
      child: const Center(
        child: Icon(Icons.eco, color: Color(0xFF1B4F1E), size: 28),
      ),
    );
  }
}

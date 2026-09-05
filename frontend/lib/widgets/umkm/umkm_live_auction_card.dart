import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agrivo/services/api_service.dart';

class UmkmLiveAuctionCard extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback? onBidTap;

  const UmkmLiveAuctionCard({
    super.key,
    this.product,
    this.onBidTap,
  });

  @override
  State<UmkmLiveAuctionCard> createState() => _UmkmLiveAuctionCardState();
}

class _UmkmLiveAuctionCardState extends State<UmkmLiveAuctionCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calculateRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant UmkmLiveAuctionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateRemaining();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    final expiryStr = widget.product?['expiry_time'] as String?;
    if (expiryStr != null) {
      try {
        final expiry = DateTime.parse(expiryStr).toUtc();
        final now = DateTime.now().toUtc();
        final diff = expiry.difference(now);
        setState(() {
          _remaining = diff.isNegative ? Duration.zero : diff;
        });
        return;
      } catch (_) {}
    }
    setState(() {
      _remaining = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return "Selesai";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return "Rp 0 /kg";
    String pStr = rawPrice.toString();
    if (pStr.startsWith('Rp')) return "$pStr /kg";
    int? val = int.tryParse(pStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (val != null) {
      return "Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} /kg";
    }
    return "Rp $pStr /kg";
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    if (imagePath.startsWith("http")) return imagePath;
    if (imagePath.startsWith("assets/")) return imagePath;
    return "${ApiService.baseUrl}/$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(Icons.gavel_outlined, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'Belum Ada Lelang Aktif',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Produk lelang Live Bid terbaru dari petani akan muncul di sini.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final productName = widget.product?['name'] ?? 'Produk Live Bid';
    final priceDisplay = _formatPrice(widget.product?['price']);
    final imagePath = widget.product?['image_path'] as String?;
    final isExpired = _remaining == Duration.zero;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B4F1E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Section: Image & Title without the red Live Auction badge
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: SizedBox(
              height: 145,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(imagePath),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Text(
                      productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lower Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Bid',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          priceDisplay,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F1E),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Berakhir dalam',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.grey.shade200 : const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(_remaining),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.grey.shade700 : const Color(0xFFD32F2F),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isExpired ? null : widget.onBidTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F1E),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pan_tool_outlined,
                          size: 20,
                          color: isExpired ? Colors.grey.shade600 : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired ? 'Lelang Selesai' : 'Ikuti Bid',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isExpired ? Colors.grey.shade600 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? path) {
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
      color: const Color(0xFF2E5E32),
      child: Center(
        child: Icon(
          Icons.agriculture,
          size: 60,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

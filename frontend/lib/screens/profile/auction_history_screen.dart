import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';
import '../market/product_detail_screen.dart';

class AuctionHistoryScreen extends StatefulWidget {
  final String? initialRole;

  const AuctionHistoryScreen({super.key, this.initialRole});

  @override
  State<AuctionHistoryScreen> createState() => _AuctionHistoryScreenState();
}

class _AuctionHistoryScreenState extends State<AuctionHistoryScreen> {
  bool _isLoading = true;
  String _userRole = 'petani';
  List<dynamic> _myBids = [];
  List<dynamic> _farmerLiveBids = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await ApiService.getProfile();
    final role = (profile?['role'] ?? widget.initialRole ?? 'petani').toString().toLowerCase();

    _userRole = role;
    if (_userRole == 'petani') {
      _farmerLiveBids = await ApiService.getFarmerLiveBids();
    } else {
      _myBids = await ApiService.getMyBids();
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
    if (expiryTimeIso == null) return "-";
    try {
      DateTime expiry = DateTime.parse(expiryTimeIso);
      Duration diff = expiry.difference(DateTime.now());
      if (diff.isNegative) return "Live Bid Selesai";
      int hours = diff.inHours;
      int minutes = diff.inMinutes.remainder(60);
      return "$hours jam $minutes menit";
    } catch (_) {
      return "-";
    }
  }

  Future<void> _handleBidAction(int bidId, String status) async {
    final success = await ApiService.updateBidStatus(bidId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Tawaran berhasil ${status == 'accepted' ? 'disetujui' : 'ditolak'}!'
                : 'Gagal memperbarui status tawaran.',
          ),
          backgroundColor: status == 'accepted' ? const Color(0xFF1B4F1E) : Colors.red,
        ),
      );
      if (success) _loadData();
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
          title: const Text('Perpanjang Live Bid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Produk: ${product['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Pilih durasi tambahan waktu:', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
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
            TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text('Batal')),
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
                            content: Text(success ? 'Waktu Live Bid diperpanjang $selectedHours jam!' : 'Gagal memperpanjang waktu'),
                            backgroundColor: success ? const Color(0xFF1B4F1E) : Colors.red,
                          ),
                        );
                        if (success) _loadData();
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

  @override
  Widget build(BuildContext context) {
    final bool isPetani = _userRole == 'petani';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          isPetani ? 'Penawaran Masuk' : 'Tawaran Saya',
          style: const TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4F1E)))
          : isPetani
              ? _buildFarmerAuctionView()
              : _buildBuyerBidsView(),
    );
  }

  // View untuk Petani: Melihat lelang miliknya beserta daftar tawaran masuk dari user
  Widget _buildFarmerAuctionView() {
    if (_farmerLiveBids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Belum ada produk Live Bid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Buat produk dengan mode Live Bid di pasar untuk mulai lelang.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF1B4F1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _farmerLiveBids.length,
        itemBuilder: (context, index) {
          final prod = _farmerLiveBids[index] as Map<String, dynamic>;
          final bool expired = _isExpired(prod['expiry_time']);
          final List<dynamic> bids = prod['bids'] ?? [];
          final String imagePath = prod['image_path'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 65,
                          height: 65,
                          color: const Color(0xFFF3F7F2),
                          child: imagePath.isNotEmpty
                              ? Image.network(
                                  _getFullImageUrl(imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.green),
                                )
                              : const Icon(Icons.eco, color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod['name'] ?? 'Produk Live Bid',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Harga Saat Ini: Rp ${prod['price']}',
                              style: const TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                                  size: 13,
                                  color: expired ? Colors.red : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeLeft(prod['expiry_time']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: expired ? Colors.red : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Tombol Perpanjang jika lelang habis
                      if (expired)
                        ElevatedButton.icon(
                          onPressed: () => _showExtendDialog(prod),
                          icon: const Icon(Icons.more_time, size: 14, color: Colors.white),
                          label: const Text('Perpanjang', style: TextStyle(fontSize: 11, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 22),

                  // Section Daftar Penawaran Masuk
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Penawaran Masuk (${bids.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        expired ? 'Lelang Selesai' : 'Sedang Berlangsung',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: expired ? Colors.grey : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (bids.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'Belum ada tawaran masuk dari pembeli.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  else
                    ...bids.map((b) {
                      final int bidId = b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0;
                      final String status = b['status'] ?? 'pending';
                      final bool isPending = status == 'pending';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: status == 'accepted'
                              ? const Color(0xFFE8F5E9)
                              : status == 'rejected'
                                  ? const Color(0xFFFFF1F2)
                                  : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: status == 'accepted'
                                ? const Color(0xFFC8E6C9)
                                : status == 'rejected'
                                    ? const Color(0xFFFECDD3)
                                    : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1B4F1E),
                              child: Text(
                                (b['bidder_name'] ?? 'P')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['bidder_name'] ?? 'Pembeli',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Tawaran: Rp ${b['bid_amount']}',
                                    style: const TextStyle(
                                      color: Color(0xFF1B4F1E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Badge or Action Buttons
                            if (isPending) ...[
                              // Tombol Tolak
                              OutlinedButton(
                                onPressed: () => _handleBidAction(bidId, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Tolak', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 6),
                              // Tombol Setuju
                              ElevatedButton(
                                onPressed: () => _handleBidAction(bidId, 'accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4F1E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Setuju', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'accepted' ? Colors.green.shade700 : Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status == 'accepted' ? 'Disetujui' : 'Ditolak',
                                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // View untuk Buyer/UMKM: Melihat daftar tawaran lelang yang telah diajukan
  Widget _buildBuyerBidsView() {
    if (_myBids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Belum mengikuti lelang apapun',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Kunjungi tab Pasar dan pilih kategori Live Bid untuk mulai menawar.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF1B4F1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myBids.length,
        itemBuilder: (context, index) {
          final bid = _myBids[index] as Map<String, dynamic>;
          final String imagePath = bid['product_image'] ?? '';
          final String status = bid['status'] ?? 'pending';
          final bool isExpired = bid['is_expired'] == true;

          Color statusColor;
          String statusText;
          if (status == 'accepted') {
            statusColor = const Color(0xFF2E7D32);
            statusText = 'Tawaran Diterima Petani!';
          } else if (status == 'rejected') {
            statusColor = const Color(0xFFE53935);
            statusText = 'Tawaran Ditolak';
          } else {
            statusColor = Colors.orange.shade800;
            statusText = 'Menunggu Keputusan Petani';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 75,
                      height: 75,
                      color: const Color(0xFFF3F7F2),
                      child: imagePath.isNotEmpty
                          ? Image.network(
                              _getFullImageUrl(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.green),
                            )
                          : const Icon(Icons.eco, color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bid['product_name'] ?? 'Produk Live Bid',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tawaran Anda: Rp ${bid['bid_amount']}',
                          style: const TextStyle(
                            color: Color(0xFF1B4F1E),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Harga Awal: Rp ${bid['product_price']}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Selesai',
                                  style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
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
        },
      ),
    );
  }
}

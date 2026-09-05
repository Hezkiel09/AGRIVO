import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';

class PetaniOrdersScreen extends StatefulWidget {
  const PetaniOrdersScreen({super.key});

  @override
  State<PetaniOrdersScreen> createState() => _PetaniOrdersScreenState();
}

class _PetaniOrdersScreenState extends State<PetaniOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final orders = await ApiService.getOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus, String actionLabel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          newStatus == 'dikirim'
              ? 'Pastikan produk panen telah dikemas rapi dan diserahkan ke jasa kurir/pengiriman. Status pengiriman ini akan otomatis menaikkan grafik tren pasar komoditas hari ini!'
              : 'Apakah Anda yakin ingin memperbarui pesanan ini ke tahap $newStatus?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4F1E))),
    );

    final success = await ApiService.updateOrderStatus(orderId, newStatus);
    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'dikirim'
                ? 'Pesanan berhasil dikirim! Tren pasar komoditas hari ini terupdate.'
                : 'Status pesanan berhasil diperbarui menjadi $newStatus',
          ),
          backgroundColor: const Color(0xFF1B4F1E),
        ),
      );
      _fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status pesanan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _cleanDisplayName(dynamic raw, {String fallback = 'Pembeli'}) {
    if (raw == null) return fallback;
    String s = raw.toString().trim();
    if (s.isEmpty) return fallback;
    if (s.contains('@')) {
      s = s.split('@')[0];
      s = s.replaceAll(RegExp(r'[._\-]+'), ' ');
      s = s.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
    }
    final words = s.split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
    return words.isEmpty ? fallback : words.join(' ');
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return "Rp 0";
    String pStr = rawPrice.toString();
    if (pStr.startsWith('Rp')) return pStr;
    int? val = int.tryParse(pStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (val != null) {
      return "Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    }
    return "Rp $pStr";
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final month = months[dt.month - 1];
      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} $month ${dt.year}, $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 28),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    }
    if (!kIsWeb) {
      try {
        final f = File(imagePath);
        if (f.existsSync()) return Image.file(f, fit: BoxFit.cover);
      } catch (_) {}
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'pending').toList();
    final diprosesOrders = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'diproses').toList();
    final dikirimOrders = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'dikirim').toList();
    final selesaiOrders = _orders.where((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      return s == 'selesai' || s == 'completed';
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pesanan Masuk Tani',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          labelColor: const Color(0xFF1B4F1E),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1B4F1E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Semua (${_orders.length})'),
            Tab(text: 'Masuk (${pendingOrders.length})'),
            Tab(text: 'Diproses (${diprosesOrders.length})'),
            Tab(text: 'Dikirim (${dikirimOrders.length})'),
            Tab(text: 'Selesai (${selesaiOrders.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4F1E)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_orders),
                _buildOrderList(pendingOrders),
                _buildOrderList(diprosesOrders),
                _buildOrderList(dikirimOrders),
                _buildOrderList(selesaiOrders),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pesanan langsung dari UMKM dan pembeli akan muncul di sini.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: const Color(0xFF1B4F1E),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = items[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final int orderId = order['id'] is int ? order['id'] : int.tryParse(order['id'].toString()) ?? 0;
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final productName = order['product_name'] ?? 'Produk Hasil Panen';
    final buyerName = _cleanDisplayName(order['buyer_name'], fallback: 'Pembeli / UMKM');
    final qty = order['quantity'] ?? 1;
    final totalPrice = _formatPrice(order['total_price']);
    final dateStr = _formatDate(order['created_at']);
    final imagePath = order['product_image'] as String?;

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'dikirim':
        statusColor = const Color(0xFF1976D2);
        statusBg = const Color(0xFFE3F2FD);
        statusLabel = 'Dalam Pengiriman';
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'diproses':
        statusColor = const Color(0xFFE65100);
        statusBg = const Color(0xFFFFF3E0);
        statusLabel = 'Sedang Diproses';
        statusIcon = Icons.autorenew;
        break;
      case 'selesai':
      case 'completed':
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        statusLabel = 'Selesai';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'dibatalkan':
        statusColor = const Color(0xFFC62828);
        statusBg = const Color(0xFFFFEBEE);
        statusLabel = 'Dibatalkan';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFF57C00);
        statusBg = const Color(0xFFFFF8E1);
        statusLabel = 'Pesanan Masuk';
        statusIcon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Buyer & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    buyerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const Divider(height: 20),

          // Product details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: _buildImage(imagePath),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kuantitas: $qty kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4F1E),
                    ),
                  ),
                ],
              ),

              // Action buttons based on status
              if (status == 'pending') ...[
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(orderId, 'diproses', 'Proses Pesanan'),
                  icon: const Icon(Icons.autorenew, size: 16, color: Colors.white),
                  label: const Text('Proses Pesanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ] else if (status == 'diproses') ...[
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(orderId, 'dikirim', 'Kirim Pesanan'),
                  icon: const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                  label: const Text('Kirim Pesanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ] else if (status == 'dikirim') ...[
                OutlinedButton.icon(
                  onPressed: () => _updateStatus(orderId, 'selesai', 'Selesaikan Pesanan'),
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2E7D32)),
                  label: const Text('Tandai Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ] else if (status == 'selesai' || status == 'completed') ...[
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Transaksi Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

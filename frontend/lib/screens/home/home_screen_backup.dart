import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api_service.dart';
import '../../core/app_routes.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Starts at Beranda

  // Scanner state variables
  XFile? _imageFile;
  List<dynamic>? _detections;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final List<String> _titles = [
    'AGRIVO',
    'PASAR TANI',
    'AGRISCAN',
    'KOMUNITAS',
    'PROFIL SAYA',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _detections = null; // Reset deteksi saat gambar baru dipilih
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  Future<void> _uploadAndDetect() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final results = await ApiService.uploadAndDetect(_imageFile!);
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        if (results == null || results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada sayuran yang terdeteksi.')),
          );
        } else {
          // Langsung pindah ke ResultScreen jika deteksi berhasil
          Navigator.pushNamed(
            context,
            AppRoutes.result,
            arguments: {
              'imageFile': _imageFile!,
              'detections': results,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildBerandaTab();
      case 1:
        return _buildPasarTab();
      case 2:
        return _buildScanTab();
      case 3:
        return _buildKomunitasTab();
      case 4:
        return _buildAkunTab();
      default:
        return const SizedBox();
    }
  }

  // --- BERANDA TAB ---
  Widget _buildBerandaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Greetings
          const Text(
            'Hai Adit!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4F1E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Optimalkan hasil panen dengan\nkecerdasan komputer vision.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A4A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // Card 1: Total Penjualan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEBEB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Penjualan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Image.asset(
                      'assets/icon/moneyicon.png',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF1B4F1E),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rp. 500,450',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4F1E),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+12% vs bulan lalu',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildTimeFilterPill('1B', isSelected: true),
                    const SizedBox(width: 8),
                    _buildTimeFilterPill('3B', isSelected: false),
                    const SizedBox(width: 8),
                    _buildTimeFilterPill('1T', isSelected: false),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Pesanan Aktif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEBEB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesanan Aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Image.asset(
                      'assets/icon/cartIcon.png',
                      width: 22,
                      height: 22,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4F1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menunggu pemenuhan',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 3: Tren Pasar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEBEB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tren Pasar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4F1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Indeks harga komoditas regional',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: _MarketChartPainter(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCommodityMetric('GANDUM', '+2.4%', isPositive: true),
                    _buildCommodityMetric('JAGUNG', '-0.5%', isPositive: false),
                    _buildCommodityMetric('KEDELAI', '+1.8%', isPositive: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterPill(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1B4F1E) : const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCommodityMetric(String name, String change, {required bool isPositive}) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          change,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isPositive ? const Color(0xFF1B4F1E) : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  // --- PASAR TAB ---
  Widget _buildPasarTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
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
                    _buildCategoryChip('Semua', true),
                    _buildCategoryChip('Sayuran', false),
                    _buildCategoryChip('Buah-buahan', false),
                    _buildCategoryChip('Lelang Aktif', false),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Lelang Sedang Berlangsung 🔥', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F1E))),
                    Text('Lihat Semua', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  children: [
                    _buildLiveBidCard('Apel Manalagi', 'assets/images/apel1.png', 'Grade A', 'Rp 22.000/kg', '01j 42m'),
                    _buildLiveBidCard('Tomat Beef', 'assets/images/boxscanfruit.png', 'Grade A', 'Rp 14.500/kg', '45m'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Beli Langsung dari Kebun 🥬', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F1E))),
                    Text('Lihat Semua', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildDirectBuyCard('Sawi Hijau Organik', 'assets/images/boxscanfruit.png', 'Rp 8.000 / ikat', 'Toko Tani Makmur');
                  }
                  return _buildDirectBuyCard('Jeruk Sunkist Fresh', 'assets/images/apel1.png', 'Rp 25.000 / kg', 'Petani Berkah Jaya');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        onSelected: (_) {},
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

  Widget _buildLiveBidCard(String name, String imgPath, String grade, String bid, String time) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(imgPath, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(grade, style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Bid Tertinggi: $bid', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectBuyCard(String name, String imgPath, String price, String shopName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(imgPath, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.store, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(shopName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Beli', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- SCAN TAB ---
  Widget _buildScanTab() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _imageFile != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: kIsWeb
                                    ? Image.network(
                                        _imageFile!.path,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                            if (_detections != null)
                              ..._detections!.map((d) {
                                if (d['x'] == null ||
                                    d['y'] == null ||
                                    d['width'] == null ||
                                    d['height'] == null ||
                                    d['image_width'] == null ||
                                    d['image_height'] == null ||
                                    d['image_width'] == 0) {
                                  return const SizedBox();
                                }

                                double imgW = d['image_width'].toDouble();
                                double imgH = d['image_height'].toDouble();
                                double cw = constraints.maxWidth;
                                double ch = constraints.maxHeight;

                                double scale = min(cw / imgW, ch / imgH);
                                double renderedW = imgW * scale;
                                double renderedH = imgH * scale;
                                double offsetX = (cw - renderedW) / 2;
                                double offsetY = (ch - renderedH) / 2;

                                double boxW = d['width'].toDouble() * scale;
                                double boxH = d['height'].toDouble() * scale;
                                double left = offsetX + (d['x'].toDouble() * scale) - (boxW / 2);
                                double top = offsetY + (d['y'].toDouble() * scale) - (boxH / 2);

                                String className = d['class']?.toString() ?? 'Object';

                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: boxW,
                                  height: boxH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.redAccent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        color: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          className,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                        );
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada foto',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.liveScan,
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.green, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.green, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_imageFile == null || _isUploading) ? null : _uploadAndDetect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Deteksi Sekarang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- KOMUNITAS TAB ---
  Widget _buildKomunitasTab() {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1B4F1E),
                child: Text('BH', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tanya harga pasar atau bagikan tips tani...',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.photo_library_outlined, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPostCard(
          'Pak Joko',
          'Petani Tomat',
          'Alhamdulillah panen tomat kali ini melimpah. Hasil scan rata-rata masuk Grade A dengan harga pasaran Rp 18k - 20k. Ada yang mau borong?',
          'assets/images/boxscanfruit.png',
          '15 Suka',
          '5 Komentar',
        ),
        _buildPostCard(
          'Dr. Ir. Hermawan',
          'Pakar Pertanian',
          'Tips menjaga kualitas sayuran hijau agar tetap segar saat pengiriman: pastikan kelembaban terjaga dan gunakan wadah berventilasi.',
          null,
          '42 Suka',
          '12 Komentar',
        ),
      ],
    );
  }

  Widget _buildPostCard(String author, String role, String content, String? imgPath, String likes, String comments) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Text(author[0], style: const TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(role, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
          if (imgPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imgPath, width: double.infinity, height: 150, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(likes, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(comments, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- AKUN TAB ---
  Widget _buildAkunTab() {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 100),
      children: [
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1B4F1E),
                child: Text('BH', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              const Text('Budi Harsono', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Petani Premium', style: TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard('Rp 4.2M', 'Total Omset'),
            _buildStatCard('4.9/5', 'Rating Toko'),
            _buildStatCard('42', 'Scanner Hit'),
          ],
        ),
        const SizedBox(height: 24),
        _buildMenuOption(Icons.shopping_bag_outlined, 'Dagangan Saya'),
        _buildMenuOption(Icons.history, 'Riwayat Scan & Grade'),
        _buildMenuOption(Icons.gavel, 'Lelang Diikuti'),
        _buildMenuOption(Icons.settings_outlined, 'Pengaturan Akun'),
        const Divider(),
        _buildMenuOption(
          Icons.logout,
          'Keluar',
          color: Colors.red,
          onTap: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B4F1E))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String text, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: color ?? const Color(0xFF1B4F1E)),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(
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
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _MarketChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw smooth primary green curve
    final greenPaint = Paint()
      ..color = const Color(0xFF1B4F1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.7);
    greenPath.cubicTo(
      size.width * 0.35, size.height * 0.45,
      size.width * 0.45, size.height * 0.35,
      size.width * 0.55, size.height * 0.45,
    );
    greenPath.cubicTo(
      size.width * 0.65, size.height * 0.55,
      size.width * 0.75, size.height * 0.85,
      size.width * 0.85, size.height * 0.65,
    );
    greenPath.lineTo(size.width, size.height * 0.15);

    canvas.drawPath(greenPath, greenPaint);

    // 2. Draw secondary light gray dashed/dotted curve
    final grayPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final grayPath = Path();
    grayPath.moveTo(0, size.height * 0.75);
    grayPath.cubicTo(
      size.width * 0.35, size.height * 0.75,
      size.width * 0.55, size.height * 0.45,
      size.width * 0.7, size.height * 0.75,
    );
    grayPath.cubicTo(
      size.width * 0.8, size.height * 0.85,
      size.width * 0.9, size.height * 0.6,
      size.width, size.height * 0.35,
    );

    canvas.drawPath(grayPath, grayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

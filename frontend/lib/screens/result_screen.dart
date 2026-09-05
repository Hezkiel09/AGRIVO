import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:agrivo/screens/market/create_product_screen.dart';
import 'package:agrivo/services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final XFile imageFile;
  final List<dynamic> detections;

  const ResultScreen({
    Key? key,
    required this.imageFile,
    required this.detections,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    _autoSaveScanHistory();
  }

  String _getCommodityName() {
    if (widget.detections.isEmpty) return "Komoditas";

    // 1. Cari deteksi dengan tanda is_classname
    for (var d in widget.detections) {
      if (d is Map && d['is_classname'] == true) {
        String name = d['class']?.toString() ?? "";
        if (name.isNotEmpty) return _formatCommodityName(name);
      }
    }

    // 2. Cari deteksi yang bukan Grade (misal nama sayuran/buah)
    for (var d in widget.detections) {
      if (d is Map) {
        String c = d['class']?.toString() ?? "";
        if (!c.toLowerCase().contains("grade") && c.isNotEmpty) {
          return _formatCommodityName(c);
        }
      }
    }

    return "Komoditas";
  }

  String _formatCommodityName(String name) {
    if (name.isEmpty) return "Komoditas";
    return name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');
  }

  String _calculateMajorityGrade() {
    if (widget.detections.isEmpty) return "Grade Unknown";

    // Saring agar hanya menghitung Grade, bukan Classname (nama buah)
    var gradeDetections = widget.detections
        .where((d) => d['is_classname'] != true)
        .toList();
    if (gradeDetections.isEmpty) return "Grade Unknown";

    Map<String, int> counts = {};
    for (var d in gradeDetections) {
      String grade = d['class']?.toString() ?? "Grade Unknown";
      counts[grade] = (counts[grade] ?? 0) + 1;
    }

    // Find the class with the maximum count
    String majorityGrade = counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    if (majorityGrade.toLowerCase() == "grade b") {
      majorityGrade = "Grade B";
    } else if (majorityGrade.toLowerCase() == "grade a") {
      majorityGrade = "Grade A";
    } else if (majorityGrade.toLowerCase() == "grade c") {
      majorityGrade = "Grade C";
    }
    return majorityGrade;
  }

  double _calculateConfidence() {
    if (widget.detections.isEmpty) return 0.85;
    double total = 0;
    int count = 0;
    for (var d in widget.detections) {
      if (d is Map && d['confidence'] != null) {
        total += (d['confidence'] as num).toDouble();
        count++;
      }
    }
    return count > 0 ? (total / count) : 0.88;
  }

  Future<void> _autoSaveScanHistory() async {
    if (_historySaved) return;
    _historySaved = true;

    try {
      final commodity = _getCommodityName();
      final grade = _calculateMajorityGrade();
      final confidence = _calculateConfidence();

      await ApiService.saveScanHistory(
        commodity: commodity,
        grade: grade,
        confidence: confidence,
        imagePath: widget.imageFile.path,
      );
    } catch (e) {
      debugPrint('Auto-save scan history error: $e');
    }
  }

  String _getGradeDescription(String grade) {
    String lowerGrade = grade.toLowerCase();
    if (lowerGrade.contains("grade a")) {
      return "• Fisik: Bentuk sempurna, mulus, dan tidak ada cacat atau memar sama sekali.\n• Warna: Seragam, cerah, dan menunjukkan tingkat kematangan yang optimal.\n• Ukuran: Besar dan seragam dalam satu kemasan.\n• Tekstur: Sangat renyah, padat, dan segar (kadar air maksimal).\n• Pasar: Supermarket kelas atas, hotel berbintang, restoran mewah, dan komoditas ekspor.";
    } else if (lowerGrade.contains("grade b")) {
      return "• Fisik: Ada sedikit cacat fisik minor pada kulit (seperti goresan kecil atau sedikit bercak) tetapi tidak merusak daging.\n• Warna: Cukup seragam, mungkin sedikit kurang cerah dibanding Grade A.\n• Ukuran: Sedang, variasi ukuran dalam satu wadah sedikit terlihat.\n• Tekstur: Tetap bagus, segar, dan layak konsumsi langsung.\n• Pasar: Supermarket lokal, pasar modern, catering, dan konsumsi rumah tangga harian.";
    } else if (lowerGrade.contains("grade c")) {
      return "• Fisik: Bentuk tidak beraturan (bengkok, asimetris) dan memiliki cacat visual yang jelas.\n• Warna: Kurang merata atau terlalu matang.\n• Ukuran: Cenderung kecil atau sangat beragam (tidak disortir berdasarkan ukuran).\n• Tekstur: Masih aman dikonsumsi, namun estetika visualnya rendah.\n• Pasar: Bahan baku industri olahan (selai, saus, jus, keripik) atau dijual murah di pasar tradisional.";
    }
    return "Deskripsi untuk grade ini belum tersedia.";
  }

  @override
  Widget build(BuildContext context) {
    String majorityGrade = _calculateMajorityGrade();
    String commodityName = _getCommodityName();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.30),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AGRISCAN',
          style: TextStyle(
            color: Color(0xFF1B4F1E), // Dark green color
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gambar Hasil Scan
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(widget.imageFile.path, fit: BoxFit.contain)
                    : Image.file(File(widget.imageFile.path), fit: BoxFit.contain),
              ),
            ),
          ),

          // Container Informasi Hasil
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8EE), // Light green background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hasil Scan :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4F1E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            commodityName,
                            style: const TextStyle(
                              color: Color(0xFF1B4F1E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Card Grade
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_outlined,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grade $commodityName',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                majorityGrade,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Keterangan :',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getGradeDescription(majorityGrade),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                _buildSalesModeSheet(context, majorityGrade, commodityName),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF146C18,
                          ), // Dark Green Button
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Selanjutnya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesModeSheet(BuildContext context, String majorityGrade, String commodityName) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text(
            'Hasil Scan Selesai! Pilih Cara Jualanmu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Icon(Icons.shopping_cart, size: 80, color: Colors.black87),
          const SizedBox(height: 30),
          _buildModeOption(
            context,
            title: 'Live Bid ⚡',
            description: 'Laku cepat dalam beberapa jam! Cocok untuk panen segar hari ini agar tidak keburu membusuk.',
            salesMode: 'live_bid',
            majorityGrade: majorityGrade,
            commodityName: commodityName,
          ),
          const SizedBox(height: 16),
          _buildModeOption(
            context,
            title: 'Market',
            description: 'Tentukan harga pas dari kamu. Produk masuk ke katalog dan pembeli bisa langsung transaksi.',
            salesMode: 'market',
            majorityGrade: majorityGrade,
            commodityName: commodityName,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String description,
    required String salesMode,
    required String majorityGrade,
    required String commodityName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateProductScreen(
              salesMode: salesMode,
              imageFile: widget.imageFile,
              grade: majorityGrade,
              commodity: commodityName != "Komoditas" ? commodityName : null,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F2E6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

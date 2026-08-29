import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:agrivo/screens/market/create_product_screen.dart';

class ResultScreen extends StatelessWidget {
  final XFile imageFile;
  final List<dynamic> detections;

  const ResultScreen({
    Key? key,
    required this.imageFile,
    required this.detections,
  }) : super(key: key);

  String _calculateMajorityGrade() {
    if (detections.isEmpty) return "Grade Unknown";

    // Saring agar hanya menghitung Grade, bukan Classname (nama buah)
    var gradeDetections = detections
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
    if (majorityGrade == "Grade b") {
      majorityGrade = "Grade B";
    }
    return majorityGrade;
  }

  @override
  Widget build(BuildContext context) {
    String majorityGrade = _calculateMajorityGrade();

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
                    ? Image.network(imageFile.path, fit: BoxFit.contain)
                    : Image.file(File(imageFile.path), fit: BoxFit.contain),
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
                    const Text(
                      'Hasil Scan :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
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
                                'Grade',
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

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'informasi grade',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                    const Text(
                      'Torem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Harga Pasaran :',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RP 20.000 - 25.000/kg',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                            builder: (context) => _buildSalesModeSheet(context, majorityGrade),
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

  Widget _buildSalesModeSheet(BuildContext context, String majorityGrade) {
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.shopping_cart,
            size: 80,
            color: Colors.black87,
          ),
          const SizedBox(height: 30),
          _buildModeOption(
            context,
            title: 'Live Bid ⚡',
            description:
                'Laku cepat dalam beberapa jam! Cocok untuk panen segar hari ini agar tidak keburu membusuk.',
            salesMode: 'live_bid',
            majorityGrade: majorityGrade,
          ),
          const SizedBox(height: 16),
          _buildModeOption(
            context,
            title: 'Market',
            description:
                'Tentukan harga pas dari kamu. Produk masuk ke katalog dan pembeli bisa langsung transaksi.',
            salesMode: 'market',
            majorityGrade: majorityGrade,
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
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateProductScreen(
              salesMode: salesMode,
              imageFile: imageFile,
              grade: majorityGrade,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

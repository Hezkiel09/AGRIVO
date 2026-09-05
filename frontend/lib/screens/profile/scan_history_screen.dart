import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrivo/services/api_service.dart';
import '../market/create_product_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _scanHistories = [];

  @override
  void initState() {
    super.initState();
    _fetchScanHistories();
  }

  Future<void> _fetchScanHistories() async {
    setState(() => _isLoading = true);
    final results = await ApiService.getScanHistories();
    if (mounted) {
      setState(() {
        _scanHistories = results;
        _isLoading = false;
      });
    }
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

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    if (imagePath.startsWith("http")) return imagePath;
    if (imagePath.startsWith("assets/")) return imagePath;
    return "${ApiService.baseUrl}/$imagePath";
  }

  Color _getGradeColor(String grade) {
    final lower = grade.toLowerCase();
    if (lower.contains('grade a')) return const Color(0xFF2E7D32);
    if (lower.contains('grade b')) return const Color(0xFF1565C0);
    if (lower.contains('grade c')) return const Color(0xFFE65100);
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Scan & Grade',
          style: TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold, fontSize: 18),
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
          : _scanHistories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 68, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      const Text(
                        'Belum ada riwayat scan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gunakan fitur Scanner kamera untuk memindai mutu panen dengan AI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchScanHistories,
                  color: const Color(0xFF1B4F1E),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scanHistories.length,
                    itemBuilder: (context, index) {
                      final item = _scanHistories[index] as Map<String, dynamic>;
                      final String grade = item['grade'] ?? 'Grade A';
                      final String commodity = item['commodity'] ?? 'Komoditas';
                      final String dateStr = _formatDate(item['created_at']);
                      final String imagePath = item['image_path'] ?? '';
                      final Color gradeColor = _getGradeColor(grade);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image Thumbnail or Icon
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  color: const Color(0xFFF1F8EE),
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
                              const SizedBox(width: 14),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          commodity,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: gradeColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: gradeColor.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            grade,
                                            style: TextStyle(
                                              color: gradeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Waktu Scan: $dateStr',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                                    ),
                                    const SizedBox(height: 8),
                                    // Action to sell product
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateProductScreen(
                                                salesMode: 'market',
                                                imageFile: XFile(imagePath),
                                                grade: grade,
                                                commodity: commodity,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.storefront, size: 15),
                                        label: const Text('Jual Produk Ini', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF1B4F1E),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                      ),
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
                ),
    );
  }
}

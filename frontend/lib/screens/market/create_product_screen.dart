import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:agrivo/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class CreateProductScreen extends StatefulWidget {
  final String salesMode;
  final XFile imageFile;
  final String grade;

  const CreateProductScreen({
    super.key,
    required this.salesMode,
    required this.imageFile,
    required this.grade,
  });

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _expiryHoursController = TextEditingController(text: '6');
  String _category = 'Sayuran';

  bool _isLoading = false;
  List<String> _slugs = [];
  String? _selectedSlug;
  Map<String, dynamic>? _trendData;

  @override
  void initState() {
    super.initState();
    _fetchSlugs();
  }

  Future<void> _fetchSlugs() async {
    final slugs = await ApiService.getKomoditasSlugs();
    if (mounted) {
      setState(() {
        _slugs = slugs;
      });
    }
  }

  Future<void> _fetchTrendHarga(String slug) async {
    final data = await ApiService.getTrendHarga(slug);
    if (mounted) {
      setState(() {
        _trendData = data;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedSlug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap lengkapi nama produk, harga, dan pilih komoditas (slug).',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = await ApiService.createProduct(
      name: _nameController.text,
      slug: _selectedSlug!,
      salesMode: widget.salesMode,
      grade: widget.grade,
      category: _category,
      description: _descriptionController.text,
      price: _priceController.text,
      stock: int.tryParse(_stockController.text) ?? 10,
      expiryHours: widget.salesMode == 'live_bid'
          ? int.tryParse(_expiryHoursController.text)
          : null,
      unit: 'kg',
      imageFile: widget.imageFile,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diunggah!')),
        );
        Navigator.pop(context); // Kembali ke Home/Dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah produk. Coba lagi.')),
        );
      }
    }
  }

  Widget _buildTrendChart() {
    if (_trendData == null) return const SizedBox.shrink();

    List<dynamic> trend = _trendData!['trend'] ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    double minPrice = double.infinity;
    double maxPrice = 0;

    for (int i = 0; i < trend.length; i++) {
      double price = (trend[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      if (price < minPrice) minPrice = price;
      if (price > maxPrice) maxPrice = price;
    }

    // Add padding to Y axis
    minPrice = minPrice - 1000;
    maxPrice = maxPrice + 1000;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 24, bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Harga Pasar ($_selectedSlug)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minPrice,
                maxY: maxPrice,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < trend.length) {
                          String day = trend[index]['day'].toString();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              day,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          (value / 1000).toStringAsFixed(0) + 'k',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.salesMode == 'live_bid' ? 'Jual Live Bid ⚡' : 'Jual di Market',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: kIsWeb
                    ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                    : Image.file(
                        File(widget.imageFile.path),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Auto detected Grade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Grade Otomatis: ${widget.grade}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Autocomplete Slug
            const Text(
              'Pilih Komoditas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _slugs.where((String option) {
                  return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedSlug = selection;
                });
                _fetchTrendHarga(selection);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        hintText: 'Cari komoditas (contoh: Mangga)',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
            ),

            // Chart (Appears after slug is selected)
            _buildTrendChart(),

            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Produk',
                hintText: 'Contoh: Mangga Harum Manis Segar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stok (Kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Sayuran', child: Text('Sayuran')),
                DropdownMenuItem(
                  value: 'Buah-buahan',
                  child: Text('Buah-buahan'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                  });
                }
              },
            ),
            if (widget.salesMode == 'live_bid') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _expiryHoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Durasi Lelang (Jam)',
                  hintText: 'Contoh: 6',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Deskripsi Tambahan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Unggah Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

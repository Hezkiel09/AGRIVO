import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:agrivo/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class CreateProductScreen extends StatefulWidget {
  final String salesMode;
  final XFile? imageFile;
  final String grade;
  final String? commodity;

  const CreateProductScreen({
    super.key,
    this.salesMode = 'market',
    this.imageFile,
    this.grade = 'Grade A',
    this.commodity,
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

  XFile? _currentImageFile;
  bool _isLoading = false;
  List<String> _slugs = [];
  String? _selectedSlug;
  Map<String, dynamic>? _trendData;

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
    if (widget.commodity != null && widget.commodity!.isNotEmpty) {
      _nameController.text = '${widget.commodity!} ${widget.grade}';
    }
    _fetchSlugs();
  }

  Future<void> _fetchSlugs() async {
    final slugs = await ApiService.getKomoditasSlugs();
    if (mounted) {
      setState(() {
        _slugs = slugs;
        if (widget.commodity != null && widget.commodity!.isNotEmpty && _selectedSlug == null) {
          final norm = widget.commodity!.toLowerCase().trim();
          final match = slugs.firstWhere(
            (s) {
              final sn = s.toLowerCase();
              return sn == norm || norm.contains(sn) || sn.contains(norm);
            },
            orElse: () => widget.commodity!.trim().replaceAll(' ', '_'),
          );
          _selectedSlug = match;
          _fetchTrendHarga(match);
        }
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _currentImageFile = picked;
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

    if (_currentImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap sertakan foto produk dengan mengetuk area foto.'),
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
      imageFile: _currentImageFile!,
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

    final String displayName = _trendData!['commodity_name']?.toString() ??
        (_selectedSlug ?? 'Komoditas').replaceAll('_', ' ');
    final dynamic curPriceRaw = _trendData!['current_price'];
    final int currentPrice = (curPriceRaw is num) ? curPriceRaw.toInt() : 0;
    final bool hasData = _trendData!['has_data'] != false && currentPrice > 0;
    List<dynamic> trend = _trendData!['trend'] ?? [];

    // Jika komoditas belum ada data riwayat harga sama sekali (contoh: Jeruk Bali)
    if (!hasData || trend.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_outlined, color: Color(0xFF1B4F1E), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum Ada Riwayat Pasar: $displayName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B4F1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Komoditas ini belum memiliki transaksi atau acuan harga pasar di AGRIVO. Silakan tentukan harga terbaikmu sendiri sesuai mutu dan kualitas panen.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String trendStatus = _trendData!['trend_status']?.toString() ?? 'Stabil';

    List<FlSpot> spots = [];
    double minPrice = double.infinity;
    double maxPrice = 0;

    for (int i = 0; i < trend.length; i++) {
      double price = (trend[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      if (price < minPrice) minPrice = price;
      if (price > maxPrice) maxPrice = price;
    }

    bool isFlat = spots.every((s) => s.y == spots.first.y);
    if (isFlat) {
      double base = spots.first.y;
      minPrice = base > 0 ? base * 0.8 : 0;
      maxPrice = base > 0 ? base * 1.2 : 20000;
    } else {
      double pad = (maxPrice - minPrice) * 0.15;
      minPrice -= pad;
      maxPrice += pad;
    }

    String formattedCurPrice = currentPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEAD9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Pasar: $displayName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1B4F1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acuan Pasar: Rp $formattedCurPrice / kg',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendStatus.contains('Naik')
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: trendStatus.contains('Naik')
                        ? const Color(0xFF81C784)
                        : Colors.grey.shade400,
                  ),
                ),
                child: Text(
                  trendStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: trendStatus.contains('Naik')
                        ? const Color(0xFF2E7D32)
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minPrice,
                maxY: maxPrice,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              day,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: !isFlat,
                    color: const Color(0xFF1B4F1E),
                    barWidth: 2.8,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1B4F1E).withValues(alpha: 0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1B4F1E),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final idx = spot.x.toInt();
                      final day = (idx >= 0 && idx < trend.length)
                          ? trend[idx]['day'].toString()
                          : '';
                      final price = spot.y.toInt();
                      final formatted = price.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]}.',
                      );
                      return LineTooltipItem(
                        '$day\nRp $formatted/kg',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '👆 Sentuh grafik untuk melihat harga pada hari tertentu',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500,
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
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: _currentImageFile != null
                      ? (kIsWeb
                          ? Image.network(_currentImageFile!.path, fit: BoxFit.cover)
                          : Image.file(
                              File(_currentImageFile!.path),
                              fit: BoxFit.cover,
                            ))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Ketuk untuk pilih foto produk',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
              initialValue: TextEditingValue(text: widget.commodity ?? _selectedSlug ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return _slugs.where((String option) {
                  return option.toLowerCase().contains(query);
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
                    if (controller.text.isEmpty && _selectedSlug != null && _selectedSlug!.isNotEmpty) {
                      controller.text = _selectedSlug!.replaceAll('_', ' ');
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      onChanged: (val) {
                        final q = val.trim();
                        if (q.isNotEmpty) {
                          final match = _slugs.firstWhere(
                            (s) => s.toLowerCase().contains(q.toLowerCase()) || q.toLowerCase().contains(s.toLowerCase()),
                            orElse: () => q.replaceAll(' ', '_'),
                          );
                          setState(() {
                            _selectedSlug = match;
                          });
                          _fetchTrendHarga(match);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari komoditas (contoh: Mangga, Pisang, Tomat)',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4F1E)),
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

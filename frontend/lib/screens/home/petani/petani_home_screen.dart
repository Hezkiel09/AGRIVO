import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agrivo/services/api_service.dart';
import 'package:agrivo/screens/profile/petani_orders_screen.dart';

class PetaniHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const PetaniHomeScreen({super.key, this.onNavigateTab});

  @override
  State<PetaniHomeScreen> createState() => _PetaniHomeScreenState();
}

class _PetaniHomeScreenState extends State<PetaniHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _selectedPeriod = '1B';

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getFarmerDashboard();
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  String _getDisplayName() {
    final rawUsername = _dashboardData?['username']?.toString() ?? 'Petani';
    if (rawUsername.contains('@')) {
      final namePart = rawUsername.split('@')[0];
      return namePart[0].toUpperCase() + namePart.substring(1);
    }
    return rawUsername.isNotEmpty
        ? rawUsername[0].toUpperCase() + rawUsername.substring(1)
        : 'Petani';
  }

  Widget _buildTimeFilterPill(String label) {
    final isSelected = _selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
      },
      child: Container(
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
      ),
    );
  }

  Color _parseHexColor(dynamic hexStr, {Color fallback = const Color(0xFF1B4F1E)}) {
    if (hexStr == null) return fallback;
    String s = hexStr.toString().replaceAll('#', '').trim();
    if (s.length == 6) s = 'FF$s';
    int? val = int.tryParse(s, radix: 16);
    return val != null ? Color(val) : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      color: const Color(0xFF1B4F1E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Greetings
            Text(
              'Hai ${_getDisplayName()}!',
              style: const TextStyle(
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
                  Text(
                    _isLoading
                        ? 'Memuat...'
                        : (_dashboardData?['formatted_sales'] ?? 'Rp. 0'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4F1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_dashboardData?['sales_growth'] ?? "+0%"} vs bulan lalu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildTimeFilterPill('1B'),
                      const SizedBox(width: 8),
                      _buildTimeFilterPill('3B'),
                      const SizedBox(width: 8),
                      _buildTimeFilterPill('1T'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Pesanan Aktif (Dapat diklik untuk kelola pesanan masuk)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PetaniOrdersScreen()),
                ).then((_) => _fetchDashboard());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
                        Row(
                          children: [
                            Text(
                              'Pesanan Aktif',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                          ],
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
                    Text(
                      _isLoading
                          ? '...'
                          : '${_dashboardData?['active_orders'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menunggu pemenuhan (Ketuk untuk kelola)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Tren Pasar (Data dinamis multi-line berbasis komoditas ngetren)
            Builder(
              builder: (context) {
                final trendData = _dashboardData?['market_trend'] as Map<String, dynamic>?;
                final List<dynamic> linesData = (trendData?['lines'] as List<dynamic>?) ?? [];
                final List<dynamic> days = (trendData?['days'] as List<dynamic>?) ?? [];

                // Fallback default jika linesData belum ada — flat di 0.20 sesuai logika backend
                // (backend juga return flat 0.20 saat total_7d_shipped == 0)
                final List<Map<String, dynamic>> multiLines = linesData.isNotEmpty
                    ? linesData.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                    : [
                        {
                          "name": "PASAR",
                          "color": "#2E7D32",
                          "points": [0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20],
                          "volume_label": "Belum ada transaksi",
                        },
                      ];

                return Container(
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
                          const Text(
                            'Tren Pasar Seluruh Petani',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4F1E),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pasar Nasional',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👆 Sentuh grafik untuk lihat komoditas yang lagi tren',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),

                      // Legenda Komoditas Ngetren di Pasar
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: multiLines.map((line) {
                          final color = _parseHexColor(line['color']);
                          final name = line['name']?.toString() ?? 'Komoditas';
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Interactive Multi-line LineChart (Menampilkan apa yang ngetren saat di-hover/sentuh)
                      Container(
                        height: 140,
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 10, bottom: 4, left: 6, right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EFE8)),
                        ),
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: 6,
                            minY: 0.05,
                            maxY: 1.0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 0.3,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx % 2 == 0 && idx < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          days[idx].toString(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) => const Color(0xFF1B4F1E),
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final barIdx = spot.barIndex;
                                    if (barIdx < 0 || barIdx >= multiLines.length) return null;
                                    final line = multiLines[barIdx];
                                    final dayIdx = spot.x.toInt();
                                    final dayLabel = (dayIdx >= 0 && dayIdx < days.length)
                                        ? days[dayIdx].toString()
                                        : '';
                                    final name = line['name']?.toString() ?? 'Komoditas';
                                    final volLabel = line['volume_label']?.toString() ?? '';
                                    return LineTooltipItem(
                                      '$name (Lagi Tren)\n$dayLabel • $volLabel',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: multiLines.map((line) {
                              final color = _parseHexColor(line['color']);
                              final List<dynamic> pts = (line['points'] as List<dynamic>?) ?? [];
                              final List<FlSpot> spots = [];
                              for (int i = 0; i < pts.length; i++) {
                                double yVal = (pts[i] as num).toDouble();
                                spots.add(FlSpot(i.toDouble(), yVal));
                              }
                              return LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: color,
                                barWidth: 2.8,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: index == (spots.length - 1) ? 4.0 : 2.5,
                                      color: color,
                                      strokeWidth: 1.5,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(show: false),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

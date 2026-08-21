import 'package:flutter/material.dart';

import '../../widgets/custom_bottom_nav_bar.dart';
import '../community/community_screen.dart';
import '../market/market_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildBerandaTab();
      case 1:
        return const MarketScreen();
      case 2:
        return const ScanScreen();
      case 3:
        return const CommunityScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  // --- BERANDA VIEW ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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

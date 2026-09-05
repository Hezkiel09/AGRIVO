import 'package:flutter/material.dart';
import 'package:agrivo/core/local_storage.dart';
import 'package:agrivo/services/api_service.dart';

import '../../widgets/custom_bottom_nav_bar.dart';
import '../community_screen.dart';
import '../market/market_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';
import 'package:agrivo/screens/umkm/umkm_orders_screen.dart';

import 'petani/petani_home_screen.dart';
import 'umkm/umkm_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _role = 'petani';

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final localRole = await LocalStorage.getRole();
    String currentRole = localRole ?? 'petani';

    Map<String, dynamic>? data;
    if (currentRole.toLowerCase() == 'umkm') {
      data = await ApiService.getUmkmDashboard();
    } else {
      data = await ApiService.getFarmerDashboard();
    }

    if (data != null && data['role'] != null) {
      currentRole = data['role'].toString().toLowerCase();
      await LocalStorage.setRole(currentRole);
    }

    if (mounted) {
      setState(() {
        _role = currentRole;
      });
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _role == 'umkm'
            ? UmkmHomeScreen(
                onNavigateTab: (index) {
                  setState(() => _currentIndex = index);
                },
              )
            : PetaniHomeScreen(
                onNavigateTab: (index) {
                  setState(() => _currentIndex = index);
                },
              );
      case 1:
        return const MarketScreen();
      case 2:
        return _role == 'umkm' ? const UmkmOrdersScreen() : const ScanScreen();
      case 3:
        return const CommunityScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
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
        role: _role,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

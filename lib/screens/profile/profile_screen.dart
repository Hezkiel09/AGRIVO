import 'package:flutter/material.dart';
import '../../core/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'PROFIL SAYA',
          style: TextStyle(
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
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 20),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF1B4F1E),
                  child: Text(
                    'BH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Budi Harsono',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Petani Premium',
                  style: TextStyle(
                    color: Color(0xFF1B4F1E),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
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
      ),
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
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1B4F1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String text, {
    Color? color,
    VoidCallback? onTap,
  }) {
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
}

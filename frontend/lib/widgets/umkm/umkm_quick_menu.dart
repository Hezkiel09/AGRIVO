import 'package:flutter/material.dart';

class UmkmQuickMenu extends StatelessWidget {
  final VoidCallback onMarketplaceTap;
  final VoidCallback onPesananTap;
  final VoidCallback onLiveBidTap;
  final VoidCallback onKomunitasTap;

  const UmkmQuickMenu({
    super.key,
    required this.onMarketplaceTap,
    required this.onPesananTap,
    required this.onLiveBidTap,
    required this.onKomunitasTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMenuItem(
          icon: Icons.storefront_outlined,
          label: 'Marketplace',
          onTap: onMarketplaceTap,
        ),
        _buildMenuItem(
          icon: Icons.receipt_long_outlined,
          label: 'Pesanan',
          onTap: onPesananTap,
        ),
        _buildMenuItem(
          icon: Icons.gavel_outlined,
          label: 'Live Bid',
          onTap: onLiveBidTap,
        ),
        _buildMenuItem(
          icon: Icons.groups_outlined,
          label: 'Komunitas',
          onTap: onKomunitasTap,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B4F1E),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

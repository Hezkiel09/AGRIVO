import 'package:flutter/material.dart';
import '../../core/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? email = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4F1E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/agrivo_logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, size: 80, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'AGRIVO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F1E),
                ),
              ),
              const Text(
                'Yuk! pilih profesi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F1E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pilih profesi yang sesuai dengan profesi anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildRoleCard(
                context,
                title: 'Petani',
                description: 'Kelola buah anda, lacak hasil buah dan terhubung dengan pasar buah modern.',
                iconData: Icons.eco_outlined,
                iconColor: Colors.green,
                iconBgColor: Colors.green.shade100,
                roleValue: 'petani',
                email: email,
              ),
              
              const SizedBox(height: 20),
              
              _buildRoleCard(
                context,
                title: 'UMKM',
                description: 'Dapatkan hasil panen berkualitas premium dan kelola UMKM anda.',
                iconData: Icons.storefront_outlined,
                iconColor: Colors.blue.shade700,
                iconBgColor: Colors.blue.shade100,
                roleValue: 'umkm',
                email: email,
              ),

              const SizedBox(height: 40),
              
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: 'Bingung pilih peran yang mana? ',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Pelajari lebih lanjut tentang peran ini',
                      style: TextStyle(
                        color: Color(0xFF1B4F1E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {
    required String title,
    required String description,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String roleValue,
    String? email,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.register, arguments: {
          'role': roleValue,
          'email': email,
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

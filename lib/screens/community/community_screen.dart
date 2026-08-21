import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'KOMUNITAS',
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
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF1B4F1E),
                  child: Text('BH', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tanya harga pasar atau bagikan tips tani...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPostCard(
            'Pak Joko',
            'Petani Tomat',
            'Alhamdulillah panen tomat kali ini melimpah. Hasil scan rata-rata masuk Grade A dengan harga pasaran Rp 18k - 20k. Ada yang mau borong?',
            'assets/images/boxscanfruit.png',
            '15 Suka',
            '5 Komentar',
          ),
          _buildPostCard(
            'Dr. Ir. Hermawan',
            'Pakar Pertanian',
            'Tips menjaga kualitas sayuran hijau agar tetap segar saat pengiriman: pastikan kelembaban terjaga dan gunakan wadah berventilasi.',
            null,
            '42 Suka',
            '12 Komentar',
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
    String author,
    String role,
    String content,
    String? imgPath,
    String likes,
    String comments,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Text(
                  author[0],
                  style: const TextStyle(
                    color: Color(0xFF1B4F1E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    role,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
          if (imgPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imgPath,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(likes, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(comments, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

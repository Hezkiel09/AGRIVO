import 'package:flutter/material.dart';
import 'package:agrivo/services/api_service.dart';

class ArticleDetailScreen extends StatelessWidget {
  final dynamic article;

  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = article['title'] ?? 'Tanpa Judul';
    String content = article['content'] ?? 'Tidak ada deskripsi.';
    String imagePath = article['image_path']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4F1E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Komunitas',
          style: TextStyle(
            color: Color(0xFF1B4F1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gambar Artikel
          Expanded(
            flex: 2,
            child: imagePath.isNotEmpty
                ? Image.network(
                    '${ApiService.baseUrl}/$imagePath',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),

          // Konten Detail
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8EE), // Light green background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Judul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Card Judul
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_outlined,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    const Text(
                      'Rincian:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Card Rincian
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.grey,
        ),
      ),
    );
  }
}

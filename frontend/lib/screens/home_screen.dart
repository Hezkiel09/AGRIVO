import 'dart:io';
import 'dart:math';

import 'package:agrivo/screens/live_scan_screen.dart';
import 'package:agrivo/screens/result_screen.dart';
import 'package:agrivo/screens/community_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _imageFile;
  List<dynamic>? _detections;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _detections = null; // Reset deteksi saat gambar baru dipilih
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  Future<void> _uploadAndDetect() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final results = await ApiService.uploadAndDetect(_imageFile!);
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        if (results == null || results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada sayuran yang terdeteksi.')),
          );
        } else {
          // Langsung pindah ke ResultScreen jika deteksi berhasil
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultScreen(imageFile: _imageFile!, detections: results),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'AGRISCAN',
          style: TextStyle(
            color: Color(0xFF1B4F1E), // Dark green color
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.30),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt, color: Color(0xFF1B4F1E)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageFile != null
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // 1. Gambar Asli
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: kIsWeb
                                        ? Image.network(
                                            _imageFile!.path,
                                            fit: BoxFit.contain, // Harus contain agar tidak kepotong
                                          )
                                        : Image.file(
                                            File(_imageFile!.path),
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                                // 2. Bounding Boxes
                                if (_detections != null)
                                  ..._detections!.map((d) {
                                    // Pastikan data x,y,width,height ada
                                    if (d['x'] == null ||
                                        d['y'] == null ||
                                        d['width'] == null ||
                                        d['height'] == null ||
                                        d['image_width'] == null ||
                                        d['image_height'] == null ||
                                        d['image_width'] == 0) {
                                      return const SizedBox(); // Jika data tidak lengkap, jangan gambar
                                    }

                                    double imgW = d['image_width'].toDouble();
                                    double imgH = d['image_height'].toDouble();
                                    double cw = constraints.maxWidth;
                                    double ch = constraints.maxHeight;

                                    // Hitung skala dan posisi persis (BoxFit.contain logic)
                                    double scale = min(cw / imgW, ch / imgH);
                                    double renderedW = imgW * scale;
                                    double renderedH = imgH * scale;
                                    double offsetX = (cw - renderedW) / 2;
                                    double offsetY = (ch - renderedH) / 2;

                                    // Koordinat kotak (x dan y dari Roboflow adalah titik TENGAH kotak)
                                    double boxW = d['width'].toDouble() * scale;
                                    double boxH =
                                        d['height'].toDouble() * scale;
                                    double left =
                                        offsetX +
                                        (d['x'].toDouble() * scale) -
                                        (boxW / 2);
                                    double top =
                                        offsetY +
                                        (d['y'].toDouble() * scale) -
                                        (boxH / 2);

                                    // Ambil nama kelas
                                    String className =
                                        d['class']?.toString() ?? 'Object';

                                    return Positioned(
                                      left: left,
                                      top: top,
                                      width: boxW,
                                      height: boxH,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.redAccent,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            color: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              className,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              ],
                            );
                          },
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 80,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada foto',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LiveScanScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.green, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.green, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_imageFile == null || _isUploading)
                    ? null
                    : _uploadAndDetect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Deteksi Sekarang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

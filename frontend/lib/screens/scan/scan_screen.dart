import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agrivo/services/api_service.dart';
import '../../core/app_routes.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
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
          Navigator.pushNamed(
            context,
            AppRoutes.result,
            arguments: {
              'imageFile': _imageFile!,
              'detections': results,
            },
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
      body: Padding(
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
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: kIsWeb
                                      ? Image.network(
                                          _imageFile!.path,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.file(
                                          File(_imageFile!.path),
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              if (_detections != null)
                                ..._detections!.map((d) {
                                  if (d['x'] == null ||
                                      d['y'] == null ||
                                      d['width'] == null ||
                                      d['height'] == null ||
                                      d['image_width'] == null ||
                                      d['image_height'] == null ||
                                      d['image_width'] == 0) {
                                    return const SizedBox();
                                  }

                                  double imgW = d['image_width'].toDouble();
                                  double imgH = d['image_height'].toDouble();
                                  double cw = constraints.maxWidth;
                                  double ch = constraints.maxHeight;

                                  double scale = min(cw / imgW, ch / imgH);
                                  double renderedW = imgW * scale;
                                  double renderedH = imgH * scale;
                                  double offsetX = (cw - renderedW) / 2;
                                  double offsetY = (ch - renderedH) / 2;

                                  double boxW = d['width'].toDouble() * scale;
                                  double boxH = d['height'].toDouble() * scale;
                                  double left =
                                      offsetX + (d['x'].toDouble() * scale) - (boxW / 2);
                                  double top =
                                      offsetY + (d['y'].toDouble() * scale) - (boxH / 2);

                                  String className = d['class']?.toString() ?? 'Object';

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
                                }),
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
                      Navigator.pushNamed(
                        context,
                        AppRoutes.liveScan,
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
              onPressed: (_imageFile == null || _isUploading) ? null : _uploadAndDetect,
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
    );
  }
}

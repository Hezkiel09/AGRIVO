import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:agrivo/services/api_service.dart';
import '../../core/app_routes.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({Key? key}) : super(key: key);

  @override
  _LiveScanScreenState createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isDetecting = false;
  Timer? _timer;
  List<dynamic>? _currentDetections;
  XFile? _lastCapturedFile;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Gunakan kamera belakang (biasanya index 0)
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _controller!.initialize();
        if (!mounted) return;
        
        setState(() {
          _isInitializing = false;
        });
        
        _startDetectionTimer();
      }
    } catch (e) {
      print("Gagal menginisialisasi kamera: $e");
    }
  }

  void _startDetectionTimer() {
    // Ambil gambar setiap 1.5 detik
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _captureAndDetect();
    });
  }

  Future<void> _captureAndDetect() async {
    if (_isDetecting || _controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      // Ambil foto secara diam-diam
      final XFile file = await _controller!.takePicture();
      _lastCapturedFile = file; // Simpan foto terakhir untuk dipakai saat menekan tombol potret
      
      // Kirim ke backend
      final results = await ApiService.uploadAndDetect(file);
      
      if (mounted) {
        setState(() {
          _currentDetections = results;
          _isDetecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    // Mendapatkan aspect ratio kamera
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    
    // Perbaikan aspect ratio untuk mode portrait
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview (Layar Penuh)
          Center(
            child: Transform.scale(
              scale: scale,
              child: CameraPreview(_controller!),
            ),
          ),
          
          // 2. Bounding Boxes Overlay
          if (_currentDetections != null)
             ..._buildBoundingBoxes(context),

          // 3. UI Overlays (Tombol Back)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          
          // 4. Status Indikator
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDetecting)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      Text(
                        _isDetecting ? 'Menganalisis AI...' : 'Arahkan ke target',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 5. Tombol Potret (Shutter Button)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_lastCapturedFile != null && _currentDetections != null) {
                    _timer?.cancel(); // Hentikan live scan
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.result,
                      arguments: {
                        'imageFile': _lastCapturedFile!,
                        'detections': _currentDetections!,
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tunggu AI mendeteksi objek terlebih dahulu...')),
                    );
                  }
                },
                child: Container(
                  height: 75,
                  width: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildBoundingBoxes(BuildContext context) {
    List<Widget> boxes = [];
    final size = MediaQuery.of(context).size;
    
    // Karena CameraPreview kita di-scale agar full screen (Transform.scale),
    // mapping bounding box secara 100% presisi sedikit rumit tanpa AspectRatio murni.
    // Namun kita bisa menggunakan BoxFit.cover logic untuk menskalakan x,y.

    for (var d in _currentDetections!) {
      if (d['x'] == null || d['image_width'] == null || d['is_classname'] == true) {
        continue; // Lewati classname atau data yang tidak lengkap
      }

      double imgW = d['image_width'].toDouble();
      double imgH = d['image_height'].toDouble();
      double screenW = size.width;
      double screenH = size.height;

      // Kalkulasi skala BoxFit.cover 
      // (karena Transform.scale di atas meniru behavior BoxFit.cover)
      double scale = max(screenW / imgW, screenH / imgH);
      double renderedW = imgW * scale;
      double renderedH = imgH * scale;
      double offsetX = (screenW - renderedW) / 2;
      double offsetY = (screenH - renderedH) / 2;

      double boxW = d['width'].toDouble() * scale;
      double boxH = d['height'].toDouble() * scale;
      double left = offsetX + (d['x'].toDouble() * scale) - (boxW / 2);
      double top = offsetY + (d['y'].toDouble() * scale) - (boxH / 2);
      
      String className = d['class']?.toString() ?? 'Object';
      String confStr = ((d['confidence'] ?? 0.0) * 100).toStringAsFixed(0);

      boxes.add(
        Positioned(
          left: left,
          top: top,
          width: boxW,
          height: boxH,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  '$className ($confStr%)',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return boxes;
  }
}

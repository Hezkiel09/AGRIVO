import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  // Gunakan 127.0.0.1 untuk Web/Desktop, dan 10.0.2.2 untuk Emulator Android
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000";
    return "http://10.0.2.2:8000";
  }

  // ==========================================
  // FITUR 1: AUTHENTICATION (LOGIN & REGISTER)
  // ==========================================
  static Future<bool> register(String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
      print("Register Gagal: ${response.body}");
      return false;
    } catch (e) {
      print("Error Jaringan: $e");
      return false;
    }
  }
  static Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Token diterima: ${data['token']}");
        return true;
      }
      print("Login Gagal: ${response.body}");
      return false;
    } catch (e) {
      print("Error Jaringan: $e");
      return false;
    }
  }

  // ==========================================
  // FITUR 2: DETEKSI SAYURAN VIA KAMERA/GALERI
  // ==========================================
  static Future<List<dynamic>?> uploadAndDetect(XFile imageFile) async {
    final url = Uri.parse('$baseUrl/api/detect');
    
    try {
      var request = http.MultipartRequest('POST', url);
      
      // Gunakan fromBytes agar mendukung Web dan Mobile
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: imageFile.name
        )
      );

      print("Sedang memproses AI, mohon tunggu...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        
        // Logika Ekstraksi Data dari JSON
        print("Status: ${jsonResult['status']}");
        
        // Parsing kembali menggunakan List
        var roboflowData = jsonResult['roboflow_data'];
        List<dynamic> extractedDetections = [];
        
        if (roboflowData != null && roboflowData.isNotEmpty) {
          var firstElement = roboflowData[0];
          
          // Unwrap jika data dibungkus di dalam array "outputs"
          if (firstElement is Map && firstElement.containsKey('outputs')) {
             var outputsList = firstElement['outputs'];
             if (outputsList is List && outputsList.isNotEmpty) {
                firstElement = outputsList[0];
             }
          }
          
          if (firstElement is Map) {
             double? imageW;
             double? imageH;

             // 1. Ekstrak dari blok "Prediction" (jika model grading/deteksi utama ada di sini)
             if (firstElement.containsKey('Prediction')) {
                var predBlock = firstElement['Prediction'];
                if (predBlock is Map) {
                   if (predBlock.containsKey('image')) {
                      var imgInfo = predBlock['image'];
                      if (imgInfo is Map) {
                         imageW = (imgInfo['width'] ?? 0).toDouble();
                         imageH = (imgInfo['height'] ?? 0).toDouble();
                      }
                   }
                   if (predBlock.containsKey('predictions')) {
                      var preds = predBlock['predictions'] as List;
                      for (var p in preds) {
                         var pMap = Map<String, dynamic>.from(p);
                         pMap['image_width'] = imageW;
                         pMap['image_height'] = imageH;
                         extractedDetections.add(pMap);
                      }
                   }
                }
             } else if (firstElement.containsKey('predictions')) {
                // Fallback untuk format standar
                var preds = firstElement['predictions'] as List;
                for (var p in preds) {
                   var pMap = Map<String, dynamic>.from(p);
                   pMap['image_width'] = imageW;
                   pMap['image_height'] = imageH;
                   extractedDetections.add(pMap);
                }
             }

             // 2. Ekstrak dari array "Name" (hasil klasifikasi atau deteksi ekstra)
             if (firstElement.containsKey('Name')) {
                var names = firstElement['Name'] as List;
                for (var name in names) {
                   // Jangan tambahkan jika namanya sudah ada dari blok predictions
                   bool exists = extractedDetections.any((item) => item['class'].toString().toLowerCase() == name.toString().toLowerCase());
                   if (!exists) {
                      extractedDetections.add({
                        'class': name.toString(),
                        'confidence': 1.0, // Default 100% karena array Name tidak memuat confidence
                        'is_classname': true, // Penanda bahwa ini adalah classname, bukan grade
                      });
                   }
                }
             }
          }
        }

        if (extractedDetections.isNotEmpty) {
          print("Total Terdeteksi: ${extractedDetections.length}");
          for (var item in extractedDetections) {
             print("Class: ${item['class']} | Confidence:${item['confidence']}");
          }
          return extractedDetections;
        }

        print("Tidak ada data yang berhasil diekstrak.");
        print("Isi JSON Mentah: $jsonResult");
        return null;

      } else {
        print("Gagal deteksi. HTTP Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error Upload Foto: $e");
      return null;
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrivo/core/local_storage.dart';

class ApiService {
  // Gunakan 127.0.0.1 untuk Web/Desktop, dan 10.0.2.2 untuk Emulator Android
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000";
    return "http://10.0.2.2:8000";
  }

  // ==========================================
  // FITUR 1: AUTHENTICATION (LOGIN & REGISTER)
  // ==========================================
  static Future<bool> register(
    String email,
    String password,
    String role,
    String fullName,
    String? farmName,
    String? location,
  ) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
          'role': role,
          'full_name': fullName,
          'farm_name': farmName,
          'location': location,
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
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Token diterima: ${data['token']}");
        await LocalStorage.setToken(data['token']);
        
        if (data['role'] != null) {
          await LocalStorage.setRole(data['role']);
        }
        
        return true;
      }
      print("Login Gagal: ${response.body}");
      return false;
    } catch (e) {
      print("Error Jaringan: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final url = Uri.parse('$baseUrl/api/profile');
    final token = await LocalStorage.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error Fetch Profile: $e");
    }
    return null;
  }

  static Future<bool> updateProfile(String fullName, String farmName, String location) async {
    final url = Uri.parse('$baseUrl/api/profile');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': fullName,
          'farm_name': farmName,
          'location': location,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Profile: $e");
      return false;
    }
  }

  static Future<bool> checkEmail(String email) async {
    final url = Uri.parse('$baseUrl/api/check-email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error Check Email: $e");
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
        http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
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
                bool exists = extractedDetections.any(
                  (item) =>
                      item['class'].toString().toLowerCase() ==
                      name.toString().toLowerCase(),
                );
                if (!exists) {
                  extractedDetections.add({
                    'class': name.toString(),
                    'confidence': 1.0, // Default 100% karena array Name tidak memuat confidence
                    'is_classname':
                        true, // Penanda bahwa ini adalah classname, bukan grade
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

  // --- KOMUNITAS API ---
  static Future<List<dynamic>> getKomunitas() async {
    final url = Uri.parse('$baseUrl/api/komunitas');
    final token = await LocalStorage.getToken();
    try {
      final response = await http.get(
        url,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Komunitas: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getMyCommunities() async {
    final url = Uri.parse('$baseUrl/api/komunitas/me');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error Fetch My Komunitas: $e");
    }
    return [];
  }

  static Future<bool> joinCommunity(int id) async {
    final url = Uri.parse('$baseUrl/api/komunitas/$id/join');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Join Komunitas: $e");
      return false;
    }
  }

  static Future<bool> createKomunitas(
      String name, String category, String privacy, String description, XFile? image) async {
    final url = Uri.parse('$baseUrl/api/komunitas');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['category'] = category
        ..fields['privacy'] = privacy
        ..fields['description'] = description;

      if (image != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }
      }

      var response = await request.send().timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Create Komunitas: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getChatMessages(int komunitasId) async {
    final url = Uri.parse('$baseUrl/api/komunitas/$komunitasId/chat');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Chat Messages: $e");
    }
    return [];
  }

  static Future<bool> sendChatMessage(int komunitasId, String content) async {
    final url = Uri.parse('$baseUrl/api/komunitas/$komunitasId/chat');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Send Chat Message: $e");
      return false;
    }
  }

  // --- BERITA API ---
  static Future<List<dynamic>> getBerita() async {
    final url = Uri.parse('$baseUrl/api/berita');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Berita: $e");
    }
    return [];
  }

  static Future<bool> createBerita(
      String title, String category, String content, String refSource, String refUrl, XFile? image) async {
    final url = Uri.parse('$baseUrl/api/berita');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title
        ..fields['category'] = category
        ..fields['content'] = content
        ..fields['reference_source'] = refSource
        ..fields['reference_url'] = refUrl;

      if (image != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }
      }

      var response = await request.send().timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Create Berita: $e");
      return false;
    }
  }

  // ==========================================
  // FITUR 5: PRODUCT API (MARKETPLACE & DETAIL)
  // ==========================================
  static Future<List<dynamic>> getProducts({
    String? category,
    String? grade,
    String? search,
  }) async {
    Map<String, String> queryParams = {};
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'semua') {
      queryParams['category'] = category;
    }
    if (grade != null && grade.isNotEmpty) {
      queryParams['grade'] = grade;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Products: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getProductDetail(int productId) async {
    final url = Uri.parse('$baseUrl/api/products/$productId');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error Fetch Product Detail: $e");
    }
    return null;
  }

  static Future<List<dynamic>> getMyProducts() async {
    final url = Uri.parse('$baseUrl/api/my-products');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch My Products: $e");
    }
    return [];
  }

  static Future<bool> createProduct({
    required String name,
    required String slug,
    required String salesMode,
    String grade = 'Grade A',
    String category = 'Sayuran',
    String description = '',
    required String price,
    String unit = 'kg',
    int stock = 10,
    int? expiryHours,
    String? imagePath,
    XFile? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/api/products');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['slug'] = slug
        ..fields['sales_mode'] = salesMode
        ..fields['grade'] = grade
        ..fields['category'] = category
        ..fields['description'] = description
        ..fields['price'] = price
        ..fields['unit'] = unit
        ..fields['stock'] = stock.toString();

      if (expiryHours != null) {
        request.fields['expiry_hours'] = expiryHours.toString();
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        request.fields['image_path'] = imagePath;
      }

      if (imageFile != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            await imageFile.readAsBytes(),
            filename: imageFile.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
        }
      }

      var response = await request.send().timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Create Product: $e");
      return false;
    }
  }

  static Future<bool> deleteProduct(int productId) async {
    final url = Uri.parse('$baseUrl/api/products/$productId');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Product: $e");
      return false;
    }
  }

  // ==========================================
  // FITUR 6: FARMER DASHBOARD & ORDER API
  // ==========================================
  static Future<List<String>> getKomoditasSlugs() async {
    final url = Uri.parse('$baseUrl/api/komoditas-slugs');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> listData = data['data'] ?? [];
        return listData.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print("Error Fetch Slugs: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getTrendHarga(String slug) async {
    final url = Uri.parse('$baseUrl/api/v1/harga-pasar/$slug');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error Fetch Trend Harga: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getFarmerDashboard() async {
    final url = Uri.parse('$baseUrl/api/petani-dashboard');
    final token = await LocalStorage.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error Fetch Farmer Dashboard: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUmkmDashboard() async {
    final url = Uri.parse('$baseUrl/api/umkm-dashboard');
    final token = await LocalStorage.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error Fetch UMKM Dashboard: $e");
    }
    return null;
  }

  static Future<bool> createOrder({
    required int productId,
    required int quantity,
    required String totalPrice,
  }) async {
    final url = Uri.parse('$baseUrl/api/orders');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'total_price': totalPrice,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Error Create Order: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getOrders() async {
    final url = Uri.parse('$baseUrl/api/orders');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Orders: $e");
    }
    return [];
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    final url = Uri.parse('$baseUrl/api/orders/$orderId/status');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Order Status: $e");
      return false;
    }
  }

  // --- LIVE BIDS API ---
  static Future<Map<String, dynamic>> createBid(int productId, int bidAmount) async {
    final url = Uri.parse('$baseUrl/api/bids');
    final token = await LocalStorage.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'bid_amount': bidAmount,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Tawaran berhasil diajukan!'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Gagal mengajukan tawaran'};
      }
    } catch (e) {
      print("Error Create Bid: $e");
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<List<dynamic>> getMyBids() async {
    final url = Uri.parse('$baseUrl/api/bids/my');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch My Bids: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getFarmerLiveBids() async {
    final url = Uri.parse('$baseUrl/api/farmer/live-bids');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Farmer Live Bids: $e");
    }
    return [];
  }

  static Future<bool> updateBidStatus(int bidId, String status) async {
    final url = Uri.parse('$baseUrl/api/bids/$bidId/status');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Bid Status: $e");
      return false;
    }
  }

  static Future<bool> extendLiveBid(int productId, int hours) async {
    final url = Uri.parse('$baseUrl/api/products/$productId/extend-live-bid');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'hours': hours}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Error Extend Live Bid: $e");
      return false;
    }
  }

  // --- SCAN HISTORY API ---
  static Future<bool> saveScanHistory({
    required String commodity,
    required String grade,
    dynamic confidence,
    String? imagePath,
  }) async {
    final url = Uri.parse('$baseUrl/api/scan-history');
    final token = await LocalStorage.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'commodity': commodity,
          'grade': grade,
          'confidence': confidence?.toString(),
          'image_path': imagePath,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Error Save Scan History: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getScanHistories() async {
    final url = Uri.parse('$baseUrl/api/scan-history');
    final token = await LocalStorage.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error Fetch Scan Histories: $e");
    }
    return [];
  }
}
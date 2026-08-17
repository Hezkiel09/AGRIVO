```markdown
# 🚀 API Documentation & Integration Guide (Softdev Fruit Grade App)

Repositori ini memuat dokumentasi kontrak API (*Antigravity Setup*) yang memisahkan beban kerja antara **Backend (Python/FastAPI)** dan **Frontend (Flutter)**. 

Sistem ini menggunakan arsitektur **Serverless Cloud API** di mana Backend bertindak sebagai jembatan antara aplikasi mobile dan mesin AI (Roboflow), sehingga API Key tetap aman dan Frontend tidak perlu mengurus komputasi AI.

---

## 🏗️ Arsitektur Sistem

1. **Frontend (Flutter)** memotret sayuran dan mengirim file gambar (`.jpg`/`.png`) ke Backend.
2. **Backend (FastAPI)** menerima gambar, lalu meneruskannya ke **Roboflow Inference API**.
3. **Roboflow** menganalisis gambar (mendeteksi *bounding box*, nama class, grade, dan jumlah).
4. **Backend** menerima hasil mentah dari Roboflow, merapikannya, dan mengirim balik JSON ke Frontend.
5. **Frontend** menampilkan hasil (UI/UX) ke pengguna.

---

## 🌐 Base URL Target

Pastikan Frontend menembak URL yang benar sesuai dengan lingkungan pengujian:

- **Pengujian via Emulator Android di PC yang sama:** `http://10.0.2.2:8000`
- **Pengujian via HP Fisik (Satu jaringan WiFi/Hotspot):** `http://<IP_IPv4_BACKEND>:8000` *(contoh: http://192.168.1.5:8000)*
- **Production Server:** `(Akan diupdate setelah deploy ke cloud hosting)`

---

## 📜 Kontrak API (Endpoint)

### 1. Register User Baru
Digunakan untuk mendaftarkan akun petani/UMKM.

- **Endpoint:** `POST /register`
- **Headers:** `Content-Type: application/json`
- **Body Request:**
  ```json
  {
    "username": "petani_01",
    "password": "password123"
  }

```

* **Response (200 OK):**
```json
{
  "status": "success",
  "message": "Register berhasil!"
}

```



### 2. Login User

Digunakan untuk autentikasi dan mendapatkan token.

* **Endpoint:** `POST /login`
* **Headers:** `Content-Type: application/json`
* **Body Request:** *(Sama seperti register)*
* **Response (200 OK):**
```json
{
  "status": "success",
  "token": "token_dummy_petani_01"
}

```



### 3. Deteksi Sayuran (Core Feature)

Endpoint utama untuk mendeteksi *grade* dan jumlah sayuran.

* **Endpoint:** `POST /api/detect`
* **Headers:** `Content-Type: multipart/form-data`
* **Body Request:** Menggunakan form-data dengan key `file` (berisi file fisik gambar).
* **Response (200 OK):**
```json
{
  "status": "success",
  "message": "Deteksi selesai",
  "roboflow_data": [
    {
      "class": "Kangkung_A",
      "confidence": 0.95,
      "x": 150.5,
      "y": 200.0,
      "width": 100,
      "height": 120
    }
  ]
}

```



---

## 💻 Panduan Setup Backend (Python / FastAPI)

Bagian ini dikelola murni oleh tim Backend.

**1. Install Dependencies:**

```bash
pip install fastapi uvicorn inference pydantic python-multipart

```

**2. File `main.py`:**

```python
from fastapi import FastAPI, HTTPException, File, UploadFile
from pydantic import BaseModel
from inference_sdk import InferenceHTTPClient
import shutil
import os

app = FastAPI()

# --- 1. SETUP ROBOFLOW ---
# TODO: Pindahkan API_KEY ke environment variable (.env) untuk keamanan saat production
CLIENT = InferenceHTTPClient(
    api_url="[https://serverless.roboflow.com](https://serverless.roboflow.com)",
    api_key="API_KEY_ROBOFLOW_KAMU_DISINI" 
)

# --- 2. DATABASE DUMMY (Untuk Prototyping Auth) ---
fake_db = {}

class User(BaseModel):
    username: str
    password: str

# --- 3. ROUTES: AUTHENTICATION ---
@app.post("/register")
def register(user: User):
    if user.username in fake_db:
        raise HTTPException(status_code=400, detail="Username sudah dipakai")
    fake_db[user.username] = user.password
    return {"status": "success", "message": "Register berhasil!"}

@app.post("/login")
def login(user: User):
    if fake_db.get(user.username) != user.password:
        raise HTTPException(status_code=401, detail="Login gagal, periksa kredensial")
    return {"status": "success", "token": f"token_{user.username}"}

# --- 4. ROUTES: AI DETECTION ---
@app.post("/api/detect")
async def detect_vegetable(file: UploadFile = File(...)):
    file_location = f"temp_{file.filename}"
    
    # Simpan file sementara
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        # Kirim ke Roboflow API
        result = CLIENT.run_workflow(
            workspace_name="sayyid-ilmi-hubballillah",
            workflow_id="detect-count-and-visualize",
            images={"image": file_location},
            use_cache=True
        )

        return {
            "status": "success",
            "message": "Deteksi selesai",
            "roboflow_data": result
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}
    
    finally:
        # Hapus file gambar dari server setelah selesai diproses
        if os.path.exists(file_location):
            os.remove(file_location)

```

**3. Jalankan Server Lokal:**

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

```

---

## 📱 Panduan Integrasi Frontend (Flutter / Dart)

Bagian ini ditujukan untuk tim Frontend. Tambahkan package `http` di `pubspec.yaml`.

**File `api_service.dart`:**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Ubah sesuai IP Backend (Gunakan 10.0.2.2 jika testing di emulator Android)
  static const String baseUrl = "[http://10.0.2.2:8000](http://10.0.2.2:8000)";

  // ==========================================
  // FITUR 1: AUTHENTICATION (LOGIN)
  // ==========================================
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
  static Future<void> uploadAndDetect(File imageFile) async {
    final url = Uri.parse('$baseUrl/api/detect');
    
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      print("Sedang memproses AI, mohon tunggu...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        
        // Logika Ekstraksi Data dari JSON
        print("Status: ${jsonResult['status']}");
        
        // Parsing data Roboflow 
        // Note: Struktur list/array tergantung dari bentuk respons asli Roboflow
        var detections = jsonResult['roboflow_data'][0]['predictions']; 
        print("Total Sayur Terdeteksi: ${detections.length}");
        
        for (var item in detections) {
           print("Class: ${item['class']} \vert{} Confidence:${item['confidence']}");
        }

      } else {
        print("Gagal deteksi. HTTP Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error Upload Foto: $e");
    }
  }
}

```

```

```
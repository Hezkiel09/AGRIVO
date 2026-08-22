AGRIVO App
AGRIVO adalah aplikasi berbasis kecerdasan buatan (AI) untuk memindai, mendeteksi, dan memberikan estimasi grade pada hasil panen pertanian (seperti buah-buahan dan sayuran) menggunakan kamera smartphone. Aplikasi ini ditujukan untuk menghubungkan Petani dan UMKM dengan hasil panen yang lebih terukur.

Prasyarat
Sebelum menginstal proyek ini, pastikan komputer Anda telah terinstal:

Flutter SDK (versi 3.0.0 ke atas)
Python (versi 3.8 ke atas)
MySQL Server atau Laragon/XAMPP (Untuk server lokal)
Struktur Proyek
lib/ - Berisi kode sumber aplikasi seluler Flutter.
backend/ - Berisi kode sumber server API menggunakan Python (FastAPI).
1. Panduan Menjalankan Backend (Server AI & Database)
Backend bertugas mengurus akun pengguna, menyimpan data ke MySQL, dan berkomunikasi dengan API kecerdasan buatan (Roboflow).

Siapkan Database MySQL

Pastikan MySQL server Anda sudah menyala.
Buat sebuah database kosong dengan nama agrivo (contoh via terminal MySQL: CREATE DATABASE agrivo;).
Secara default, aplikasi akan mencoba login ke MySQL dengan username: root dan tanpa password. Jika pengaturan MySQL Anda berbeda, silakan ubah di file backend/database.py.
Masuk ke folder backend Buka terminal, lalu masuk ke direktori backend:

cd backend
Buat Virtual Environment (Sangat Direkomendasikan)

python -m venv venv
# Di Windows:
venv\Scripts\activate
# Di Mac/Linux:
source venv/bin/activate
Instal Library Python yang Dibutuhkan

pip install -r requirements.txt
Jalankan Server API

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Jika berhasil, tabel database akan dibuat secara otomatis dan server dapat diakses di http://127.0.0.1:8000.

2. Panduan Menjalankan Frontend (Aplikasi Flutter)
Masuk ke Folder Utama (Flutter) Buka tab terminal baru (biarkan terminal backend tetap berjalan) dan pastikan Anda berada di direktori root (folder yang berisi pubspec.yaml).

Perbarui Library Flutter

flutter pub get
Jalankan Aplikasi

Pastikan Emulator Android/iOS Anda sudah menyala, atau jalankan via Web/Browser.
flutter run
Catatan Khusus untuk Emulator Android: Aplikasi Flutter dikonfigurasi untuk menghubungi API melalui http://10.0.2.2:8000 ketika diuji coba pada Emulator Android, dan http://127.0.0.1:8000 untuk mode Web/Desktop. Pengaturan ini bisa ditemukan di lib/api_service.dart.

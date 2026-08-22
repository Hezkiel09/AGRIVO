# 🌾 AGRIVO App

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/)
[![MySQL](https://img.shields.io/badge/mysql-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)

**AGRIVO** adalah aplikasi berbasis kecerdasan buatan (AI) yang dirancang untuk memindai, mendeteksi, dan memberikan estimasi grade pada hasil panen pertanian (seperti buah-buahan dan sayuran) menggunakan kamera *smartphone*. Aplikasi ini bertujuan untuk menghubungkan Petani dan UMKM dengan kriteria hasil panen yang lebih terukur, objektif, dan efisien.

---

## 📌 Prasyarat System

Sebelum menjalankan proyek ini di lingkungan lokal, pastikan perangkat Anda telah terinstal software berikut:

* **Flutter SDK**: Versi `^3.0.0`
* **Python**: Versi `^3.8`
* **Database**: MySQL Server (atau via Laragon / XAMPP)

---


## ⚙️ Panduan Instalasi & Menjalankan Proyek

### 1. Menjalankan Backend (Server AI & Database)

Backend bertugas mengurus autentikasi dan akun pengguna, menyimpan data ke MySQL, serta berkomunikasi dengan API kecerdasan buatan (*Roboflow*).

#### A. Siapkan Database MySQL
1. Pastikan servis **MySQL Server** Anda sudah menyala (via XAMPP/Laragon/MySQL Service).
2. Buka terminal/client MySQL dan buat database kosong dengan nama `agrivo`:
   ```sql
   CREATE DATABASE agrivo;
   ```
> **Catatan Kredensial:** Secara *default*, aplikasi akan mencoba *login* ke MySQL dengan `username: root` dan tanpa *password*. Jika pengaturan MySQL lokal Anda berbeda, silakan sesuaikan di file `backend/database.py`.

#### B. Menjalankan Server API FastAPI
1. Buka terminal baru, lalu masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Buat dan aktifkan *Virtual Environment* (Sangat Direkomendasikan):
   * **Windows:**
     ```bash
     python -m venv venv
     .\venv\Scripts\activate
     ```
   * **macOS / Linux:**
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```
3. Instal seluruh *library* Python yang dibutuhkan dari `requirements.txt`:
   ```bash
   pip install -r requirements.txt
   ```
4. Jalankan Server API (Uvicorn):
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
   *Jika berhasil, tabel-tabel database akan dibuat secara otomatis dan server dapat diakses di `http://127.0.0.1:8000`.*

---

### 2. Menjalankan Frontend (Aplikasi Flutter)

1. Buka tab/window terminal baru (biarkan terminal backend tetap berjalan) dan pastikan Anda berada di direktori *root* proyek (folder yang berisi `pubspec.yaml`).

2. Unduh dan perbarui seluruh paket/library Flutter:
   ```bash
   flutter pub get
   ```

3. Jalankan Aplikasi:
   Pastikan Emulator Android/iOS Anda sudah menyala, atau targetkan ke Web/Browser.
   ```bash
   flutter run
   ```

---

## 🌐 Catatan Konfigurasi Network (Emulator vs Device)

Aplikasi Flutter dikonfigurasi untuk menyesuaikan *endpoint* API bergantung pada *environment* uji coba:

| Target Environment | Endpoint Base URL |
| :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:8000` |
| **Web / Desktop / iOS Simulator** | `http://127.0.0.1:8000` |

> Pengaturan lokasi endpoint API ini dapat disesuaikan pada file `lib/api_service.dart`.
README.md
Displaying README.md.

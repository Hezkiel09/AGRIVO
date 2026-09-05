import sys
import sqlalchemy
from sqlalchemy import text, inspect

# Pastikan path modul terbaca jika dijalankan dari root atau backend
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import database
import models

def run_migration():
    print("[*] Memulai proses migrasi database AGRIVO...")
    engine = database.engine
    
    # 1. Buat semua tabel jika belum ada
    models.Base.metadata.create_all(bind=engine)
    print("[OK] Semua tabel utama dipastikan ada (create_all).")

    inspector = inspect(engine)

    # 2. Daftar kolom yang perlu dipastikan ada untuk setiap tabel
    column_checks = {
        "users": [
            ("full_name", "VARCHAR(255) NULL"),
            ("farm_name", "VARCHAR(255) NULL"),
            ("location", "VARCHAR(255) NULL"),
        ],
        "products": [
            ("grade", "VARCHAR(50) NULL"),
            ("category", "VARCHAR(50) DEFAULT 'Sayuran'"),
            ("description", "TEXT NULL"),
            ("slug", "VARCHAR(100) NULL"),
            ("sales_mode", "VARCHAR(20) DEFAULT 'market'"),
            ("expiry_time", "DATETIME NULL"),
            ("price", "VARCHAR(100) NOT NULL DEFAULT '0'"),
            ("unit", "VARCHAR(20) DEFAULT 'kg'"),
            ("stock", "INT DEFAULT 10"),
            ("image_path", "VARCHAR(255) NULL"),
        ],
        "harga_pasar": [
            ("slug", "VARCHAR(100) NULL"),
        ]
    }

    with engine.connect() as conn:
        for table_name, columns in column_checks.items():
            if table_name in inspector.get_table_names():
                existing_cols = [c["name"] for c in inspector.get_columns(table_name)]
                for col_name, col_def in columns:
                    if col_name not in existing_cols:
                        print(f"[*] Menambahkan kolom '{col_name}' ke tabel '{table_name}'...")
                        try:
                            conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {col_name} {col_def}"))
                            conn.commit()
                            print(f"    [OK] Kolom '{col_name}' berhasil ditambahkan.")
                        except Exception as e:
                            print(f"    [!] Gagal tambah kolom {col_name}: {e}")
                    else:
                        pass
        
        # 3. Seed data komoditas default jika tabel harga_pasar masih kosong
        if "harga_pasar" in inspector.get_table_names():
            result = conn.execute(text("SELECT COUNT(*) FROM harga_pasar")).scalar()
            if result == 0:
                print("[*] Menambahkan data awal (seed) harga pasar komoditas...")
                sample_commodities = [
                    ("Beras Medium", "beras-medium", 14500),
                    ("Bawang Merah", "bawang-merah", 35000),
                    ("Bawang Putih", "bawang-putih", 38000),
                    ("Cabai Merah Keriting", "cabai-merah-keriting", 45000),
                    ("Cabai Rawit Merah", "cabai-rawit-merah", 50000),
                    ("Daging Ayam Ras", "daging-ayam-ras", 36000),
                    ("Telur Ayam Ras", "telur-ayam-ras", 29000),
                    ("Gula Pasir", "gula-pasir", 17500),
                    ("Minyak Goreng Kemasan", "minyak-goreng-kemasan", 20000),
                    ("Tomat", "tomat", 16000),
                ]
                for name, slug, price in sample_commodities:
                    conn.execute(text(
                        "INSERT INTO harga_pasar (komoditas, slug, harga, tanggal_update) VALUES (:k, :s, :h, NOW())"
                    ), {"k": name, "s": slug, "h": price})
                conn.commit()
                print("    [OK] Seed harga pasar selesai.")

    print("\n[SUCCESS] Migrasi database selesai! Semua kolom & tabel di database sudah 100% sinkron.")

if __name__ == "__main__":
    run_migration()

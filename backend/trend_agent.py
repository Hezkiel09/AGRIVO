import os
from dotenv import load_dotenv
import google.generativeai as genai
from sqlalchemy.orm import Session
from sqlalchemy import desc
from database import SessionLocal
import models
import datetime

load_dotenv()

def generate_trend_article():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY not found in .env. Skipping AI agent.")
        return

    genai.configure(api_key=api_key)
    
    # Initialize the model (using gemini-1.5-flash as it's the current recommended model for general text)
    model = genai.GenerativeModel('gemini-3.5-flash-lite')
    
    db: Session = SessionLocal()
    try:
        # Get bot user ID
        bot_user = db.query(models.User).filter(models.User.username == "Agrivo AI").first()
        bot_id = bot_user.id if bot_user else None

        # Fetch recent market prices (last 7 days)
        seven_days_ago = datetime.datetime.utcnow() - datetime.timedelta(days=7)
        recent_prices = db.query(models.HargaPasar).filter(
            models.HargaPasar.tanggal_update >= seven_days_ago
        ).order_by(desc(models.HargaPasar.tanggal_update)).all()

        price_data_str = ""
        if not recent_prices:
            price_data_str = "Saat ini belum ada data pergerakan harga pasar dalam 7 hari terakhir di database."
        else:
            # Group by commodity
            commodity_data = {}
            for hp in recent_prices:
                if hp.komoditas not in commodity_data:
                    commodity_data[hp.komoditas] = []
                # Just saving a string for the prompt
                date_str = hp.tanggal_update.strftime("%Y-%m-%d")
                commodity_data[hp.komoditas].append(f"{date_str}: Rp {hp.harga}/kg")
                
            for kom, records in commodity_data.items():
                price_data_str += f"\n- {kom}: {', '.join(records[:5])} (menampilkan max 5 data terbaru)"

        # Prepare the prompt
        prompt = f"""
Anda adalah Agrivo AI, seorang analis pasar pertanian dan jurnalis agrikultur profesional.
Tugas Anda adalah menulis satu artikel berita singkat dan menarik mengenai tren harga komoditas pertanian saat ini. 

Berikut adalah data pergerakan harga pasar dalam 7 hari terakhir:
{price_data_str}

Instruksi tambahan:
1. Jika tidak ada data harga, tuliskan artikel tips umum seputar pertanian yang relevan dengan kondisi musim saat ini, dan beri sedikit motivasi.
2. Jika ada data, berikan analisis tren (apakah naik/turun/stabil), dan berikan rekomendasi untuk petani (kapan waktu terbaik untuk menjual/menahan stok).
3. Artikel harus memiliki judul yang menarik (Berikan di baris pertama saja, tanpa kata 'Judul:').
4. Gaya bahasa harus semi-formal namun ramah, mudah dipahami petani dan UMKM. Format konten Anda dalam format tulisan / paragraf biasa, gunakan sedikit emoji agar lebih menarik.
5. Jangan terlalu panjang, cukup 2-3 paragraf.

Tuliskan hasilnya dengan format:
[Judul Artikel]
(Baris Kosong)
[Isi Artikel Paragraf 1]
...
"""

        print("Generating article with Gemini...")
        response = model.generate_content(prompt)
        content = response.text.strip()
        
        # Parse title and body
        lines = content.split("\n")
        title = lines[0].replace("**", "").replace("#", "").strip()
        
        # Reconstruct body
        body = "\n".join(lines[1:]).strip()
        
        # Create Berita
        new_berita = models.Berita(
            title=title,
            category="Tren Pasar",
            content=body,
            image_path="assets/images/market_trend_placeholder.jpg", # Placeholder image
            author_id=bot_id,
            reference_source="Agrivo AI Market Analysis"
        )
        
        db.add(new_berita)
        db.commit()
        print(f"Article '{title}' successfully generated and saved to DB.")
        
    except Exception as e:
        print(f"Error in trend agent: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    generate_trend_article()

from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    try:
        conn.execute(text('ALTER TABLE products ADD COLUMN slug VARCHAR(100)'))
        conn.execute(text('CREATE INDEX ix_products_slug ON products(slug)'))
    except Exception as e:
        print(f"Products error: {e}")
        
    try:
        conn.execute(text('ALTER TABLE harga_pasar ADD COLUMN slug VARCHAR(100)'))
        conn.execute(text('CREATE INDEX ix_harga_pasar_slug ON harga_pasar(slug)'))
    except Exception as e:
        print(f"Harga pasar error: {e}")
        
    conn.commit()
print("Migration done")

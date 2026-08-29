from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    try:
        conn.execute(text("ALTER TABLE products ADD COLUMN sales_mode VARCHAR(20) DEFAULT 'market'"))
        print("Added sales_mode column")
    except Exception as e:
        print(f"Error adding sales_mode: {e}")

    try:
        conn.execute(text("ALTER TABLE products ADD COLUMN expiry_time DATETIME NULL"))
        print("Added expiry_time column")
    except Exception as e:
        print(f"Error adding expiry_time: {e}")
        
    conn.commit()
print("Migration done")

from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    # Try adding missing columns to products table
    columns = [
        "grade VARCHAR(50)",
        "category VARCHAR(50)",
        "unit VARCHAR(20)",
        "stock INT"
    ]
    
    for col in columns:
        col_name = col.split()[0]
        try:
            conn.execute(text(f'ALTER TABLE products ADD COLUMN {col}'))
            print(f"Successfully added {col_name}")
        except Exception as e:
            if "Duplicate column name" in str(e):
                print(f"Column {col_name} already exists.")
            else:
                print(f"Error adding {col_name}: {e}")
                
    conn.commit()
print("Migration for missing product columns done")

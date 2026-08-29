from database import engine
from sqlalchemy import text

def run_migration():
    with engine.connect() as conn:
        print("Starting migration to add full_name and location...")
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN full_name VARCHAR(255) NULL"))
            print("Added full_name column.")
        except Exception as e:
            print(f"Skipping full_name (maybe already exists)")

        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN location VARCHAR(255) NULL"))
            print("Added location column.")
        except Exception as e:
            print(f"Skipping location (maybe already exists)")
        
        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    run_migration()

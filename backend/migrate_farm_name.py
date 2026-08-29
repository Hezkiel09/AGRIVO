from database import engine
from sqlalchemy import text

def run_migration():
    with engine.connect() as conn:
        print("Starting migration to add farm_name...")
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN farm_name VARCHAR(255) NULL"))
            print("Added farm_name column.")
        except Exception as e:
            print(f"Skipping farm_name (maybe already exists)")
        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    run_migration()

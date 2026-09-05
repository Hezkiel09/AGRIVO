from database import engine
from sqlalchemy import text

def add_saldo_column():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN saldo INT NOT NULL DEFAULT 0;"))
            conn.commit()
            print("Successfully added 'saldo' column to 'users' table.")
        except Exception as e:
            print(f"Error (maybe column already exists): {e}")

if __name__ == "__main__":
    add_saldo_column()

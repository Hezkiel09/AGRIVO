from database import SessionLocal
import models
import auth

def create_bot_user():
    db = SessionLocal()
    try:
        bot_username = "Agrivo AI"
        bot_user = db.query(models.User).filter(models.User.username == bot_username).first()
        
        if not bot_user:
            # Create the bot user
            hashed_password = auth.get_password_hash("agrivo_ai_secret_password_123")
            bot_user = models.User(
                username=bot_username,
                password=hashed_password,
                role="system",
                full_name="Agrivo Artificial Intelligence",
                farm_name="Agrivo System",
                location="Cloud Server"
            )
            db.add(bot_user)
            db.commit()
            db.refresh(bot_user)
            print(f"Created bot user with ID: {bot_user.id}")
        else:
            print(f"Bot user already exists with ID: {bot_user.id}")
    finally:
        db.close()

if __name__ == "__main__":
    create_bot_user()

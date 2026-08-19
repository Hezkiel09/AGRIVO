from fastapi import FastAPI, HTTPException, File, UploadFile, Depends, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session
import shutil
import os
import requests
import base64
import time

# DB Imports
import models, database, auth
from database import engine

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = "tUhJ7SYMaCdbnFD8OlNu"

# --- SCHEMAS ---
class UserRegister(BaseModel):
    username: str # Will store email
    password: str
    role: str # "Petani" or "UMKM"

class UserLogin(BaseModel):
    username: str
    password: str

# --- ROUTES: AUTHENTICATION ---
@app.post("/register")
def register(user: UserRegister, db: Session = Depends(database.get_db)):
    role = user.role.lower()
    if role not in ["petani", "umkm"]:
        raise HTTPException(status_code=400, detail="Role harus 'petani' atau 'umkm'")
    
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username sudah dipakai")
    
    hashed_password = auth.get_password_hash(user.password)
    new_user = models.User(username=user.username, password=hashed_password, role=role)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {"status": "success", "message": "Register berhasil!"}

@app.post("/login")
def login(user: UserLogin, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if not db_user or not auth.verify_password(user.password, db_user.password):
        raise HTTPException(status_code=401, detail="Login gagal, periksa kredensial")
    
    access_token = auth.create_access_token(data={"sub": db_user.username})
    return {"status": "success", "token": access_token, "role": db_user.role}

# --- ROUTES: API ---

@app.get("/api/petani-dashboard", dependencies=[Depends(auth.require_role(["petani"]))])
def petani_dashboard(current_user: models.User = Depends(auth.get_current_user)):
    return {"message": f"Selamat datang di Dashboard Petani, {current_user.username}!"}

@app.post("/api/detect")
async def detect_vegetable(file: UploadFile = File(...)):
    # Simpan di folder temp_images
    temp_dir = "temp_images"
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)
        
    unique_filename = f"{int(time.time())}_{file.filename}"
    file_location = os.path.join(temp_dir, unique_filename)
    
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        with open(file_location, "rb") as img_file:
            img_data = img_file.read()
            encoded_image = base64.b64encode(img_data).decode("ascii")
            
        url = "https://serverless.roboflow.com/sayyid-ilmi-hubballillah/workflows/detect-count-and-visualize"
        payload = {
            "api_key": API_KEY,
            "inputs": {
                "image": {
                    "type": "base64",
                    "value": encoded_image
                }
            }
        }
        
        response = requests.post(url, json=payload)
        result = response.json()

        return {
            "status": "success",
            "message": "Deteksi selesai",
            "image_path": file_location,
            "roboflow_data": [result] if isinstance(result, dict) else result
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/api/products", dependencies=[Depends(auth.require_role(["petani"]))])
def create_product(
    name: str = Form(...),
    grade: str = Form(...),
    description: str = Form(...),
    price: str = Form(...),
    image_path: str = Form(...),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    new_product = models.Product(
        user_id=current_user.id,
        name=name,
        grade=grade,
        description=description,
        price=price,
        image_path=image_path
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    
    return {"status": "success", "message": "Produk berhasil ditambahkan!", "product_id": new_product.id}

from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import shutil
import os
import requests
import base64

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 1. SETUP ROBOFLOW ---
# TODO: Pindahkan API_KEY ke environment variable (.env) untuk keamanan saat production
API_KEY = "tUhJ7SYMaCdbnFD8OlNu"

# --- 2. DATABASE DUMMY (Untuk Prototyping Auth) ---
fake_db = {}

class User(BaseModel):
    username: str
    password: str

# --- 3. ROUTES: AUTHENTICATION ---
@app.post("/register")
def register(user: User):
    if user.username in fake_db:
        raise HTTPException(status_code=400, detail="Username sudah dipakai")
    fake_db[user.username] = user.password
    return {"status": "success", "message": "Register berhasil!"}

@app.post("/login")
def login(user: User):
    if fake_db.get(user.username) != user.password:
        raise HTTPException(status_code=401, detail="Login gagal, periksa kredensial")
    return {"status": "success", "token": f"token_{user.username}"}

# --- 4. ROUTES: AI DETECTION ---
@app.post("/api/detect")
async def detect_vegetable(file: UploadFile = File(...)):
    file_location = f"temp_{file.filename}"
    
    # Simpan file sementara
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        # Kirim ke Roboflow API menggunakan requests
        with open(file_location, "rb") as img_file:
            img_data = img_file.read()
            encoded_image = base64.b64encode(img_data).decode("ascii")
            
        url = "https://serverless.roboflow.com/infer/workflows/sayyid-ilmi-hubballillah/detect-count-and-visualize"
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
            "roboflow_data": [result] if isinstance(result, dict) else result
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}
    
    finally:
        # Hapus file gambar dari server setelah selesai diproses
        if os.path.exists(file_location):
            os.remove(file_location)

from __future__ import annotations
import os
import sys

# Ensure backend directory is in sys.path
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import shutil
import requests
import base64
import time
import datetime
from typing import Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, File, UploadFile, Depends, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy.orm import Session

# DB & Local Imports
import models
import database
import auth
from database import engine

try:
    from apscheduler.schedulers.background import BackgroundScheduler
except ImportError:
    # pyrefly: ignore [missing-import]
    from apscheduler.schedulers.background import BackgroundScheduler

import trend_agent

scheduler = BackgroundScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    if not os.environ.get("TESTING"):
        # Create tables
        models.Base.metadata.create_all(bind=engine)
        print("Starting background scheduler for AI Trend Agent...")
        try:
            scheduler.add_job(trend_agent.generate_trend_article, 'cron', hour=0, minute=0, id="trend_article_job")
            scheduler.start()
        except Exception as e:
            print(f"Warning: Could not start scheduler: {e}")
    yield
    if not os.environ.get("TESTING"):
        print("Shutting down background scheduler...")
        try:
            scheduler.shutdown()
        except Exception:
            pass

app = FastAPI(lifespan=lifespan)

if not os.path.exists("temp_images"):
    os.makedirs("temp_images")
app.mount("/temp_images", StaticFiles(directory="temp_images"), name="temp_images")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = "tUhJ7SYMaCdbnFD8OlNu"

# --- HELPER FUNCTIONS ---
def parse_price_to_int(price_val) -> int:
    if isinstance(price_val, (int, float)):
        return int(price_val)
    if not price_val:
        return 0
    digits = ''.join(filter(str.isdigit, str(price_val)))
    return int(digits) if digits else 0

def format_product(product: models.Product):
    return {
        "id": product.id,
        "name": product.name,
        "grade": product.grade,
        "category": product.category or "Sayuran",
        "description": product.description or "",
        "price": product.price,
        "unit": product.unit or "kg",
        "stock": product.stock if product.stock is not None else 10,
        "image_path": product.image_path,
        "sales_mode": product.sales_mode,
        "expiry_time": product.expiry_time.isoformat() + "Z" if product.expiry_time else None,
        "created_at": product.created_at.isoformat() + "Z" if product.created_at else None,
        "seller_id": product.user_id,
        "seller_name": product.owner.username if product.owner else "Petani Agrivo",
    }

def format_order(order: models.Order):
    return {
        "id": order.id,
        "product_id": order.product_id,
        "product_name": order.product.name if order.product else "Produk",
        "product_image": order.product.image_path if order.product else None,
        "buyer_id": order.buyer_id,
        "buyer_name": order.buyer.username if order.buyer else "Pembeli",
        "seller_id": order.product.user_id if order.product else None,
        "seller_name": order.product.owner.username if (order.product and order.product.owner) else "Petani",
        "quantity": order.quantity,
        "total_price": order.total_price,
        "status": order.status,
        "created_at": order.created_at.isoformat() if order.created_at else None,
    }

def format_bid(bid: models.Bid):
    return {
        "id": bid.id,
        "product_id": bid.product_id,
        "product_name": bid.product.name if bid.product else "Produk Lelang",
        "product_image": bid.product.image_path if bid.product else None,
        "product_grade": bid.product.grade if bid.product else "Grade A",
        "product_price": bid.product.price if bid.product else "0",
        "product_unit": bid.product.unit if bid.product else "kg",
        "product_stock": bid.product.stock if bid.product else 10,
        "product_expiry_time": bid.product.expiry_time.isoformat() + "Z" if (bid.product and bid.product.expiry_time) else None,
        "is_expired": (bid.product.expiry_time < datetime.datetime.utcnow()) if (bid.product and bid.product.expiry_time) else False,
        "bidder_id": bid.bidder_id,
        "bidder_name": bid.bidder.full_name or bid.bidder.username if bid.bidder else "Pembeli",
        "bid_amount": bid.bid_amount,
        "status": bid.status,
        "created_at": bid.created_at.isoformat() + "Z" if bid.created_at else None,
    }

def format_scan_history(scan: models.ScanHistory):
    return {
        "id": scan.id,
        "commodity": scan.commodity,
        "grade": scan.grade,
        "confidence": scan.confidence,
        "image_path": scan.image_path,
        "created_at": scan.created_at.isoformat() + "Z" if scan.created_at else None,
    }

# --- SCHEMAS ---
class UserRegister(BaseModel):
    username: str # Will store email
    password: str
    role: str # "Petani" or "UMKM"
    full_name: str
    farm_name: Optional[str] = None
    location: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class CheckEmail(BaseModel):
    email: str

class OrderCreate(BaseModel):
    product_id: int
    quantity: int
    total_price: str

class OrderStatusUpdate(BaseModel):
    status: str

class UserProfileUpdate(BaseModel):
    full_name: str
    farm_name: Optional[str] = None
    location: Optional[str] = None

class ChatMessageCreate(BaseModel):
    content: str

class BidCreate(BaseModel):
    product_id: int
    bid_amount: int

class BidStatusUpdate(BaseModel):
    status: str

class ExtendLiveBid(BaseModel):
    hours: int

class ScanHistoryCreate(BaseModel):
    commodity: str
    grade: str
    confidence: Optional[str] = None
    image_path: Optional[str] = None

# --- ROUTES: AUTHENTICATION ---
@app.post("/api/check-email")
def check_email(data: CheckEmail, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.username == data.email).first()
    if db_user:
        return {"exists": True}
    return {"exists": False}

@app.post("/register")
def register(user: UserRegister, db: Session = Depends(database.get_db)):
    role = user.role.lower()
    if role not in ["petani", "umkm"]:
        raise HTTPException(status_code=400, detail="Role harus 'petani' atau 'umkm'")
    
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username sudah dipakai")
    
    hashed_password = auth.get_password_hash(user.password)
    new_user = models.User(
        username=user.username, 
        password=hashed_password, 
        role=role,
        full_name=user.full_name,
        farm_name=user.farm_name,
        location=user.location
    )
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

# --- ROUTES: USER PROFILE ---
@app.get("/api/profile")
def get_profile(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    return {
        "status": "success",
        "data": {
            "id": current_user.id,
            "username": current_user.username,
            "role": current_user.role,
            "full_name": current_user.full_name,
            "farm_name": current_user.farm_name,
            "location": current_user.location,
        }
    }

@app.put("/api/profile")
def update_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    current_user.full_name = profile_data.full_name
    current_user.farm_name = profile_data.farm_name
    current_user.location = profile_data.location
    db.commit()
    db.refresh(current_user)
    return {
        "status": "success",
        "message": "Profil berhasil diperbarui"
    }

# --- ROUTES: API ---

@app.get("/api/petani-dashboard", dependencies=[Depends(auth.require_role(["petani", "umkm"]))])
def petani_dashboard(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    farmer_products = db.query(models.Product).filter(models.Product.user_id == current_user.id).all()
    product_ids = [p.id for p in farmer_products]
    
    total_sales = 0
    active_orders = 0
    recent_orders = []
    
    if product_ids:
        orders = db.query(models.Order).filter(models.Order.product_id.in_(product_ids)).order_by(models.Order.created_at.desc()).all()
        
        for o in orders:
            price_val = parse_price_to_int(o.total_price)
            if o.status.lower() in ["selesai", "completed"]:
                total_sales += price_val
            elif o.status.lower() in ["pending", "diproses", "dikirim"]:
                active_orders += 1
                
        recent_orders = orders[:5]
    
    formatted_sales = f"Rp. {total_sales:,.0f}".replace(",", ".")
    
    return {
        "status": "success",
        "data": {
            "id": current_user.id,
            "username": current_user.username,
            "role": current_user.role,
            "total_sales": total_sales,
            "formatted_sales": formatted_sales,
            "sales_growth": "+12%",
            "active_orders": active_orders,
            "total_products": len(farmer_products),
            "recent_orders": [format_order(o) for o in recent_orders]
        }
    }

@app.get("/api/umkm-dashboard", dependencies=[Depends(auth.get_current_user)])
def umkm_dashboard(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Ringkasan pesanan pembeli/UMKM
    buyer_orders = db.query(models.Order).filter(models.Order.buyer_id == current_user.id).order_by(models.Order.created_at.desc()).all()
    
    active_orders = 0
    for o in buyer_orders:
        if o.status.lower() in ["pending", "diproses", "dikirim"]:
            active_orders += 1

    # Featured Live Auction (ambil live bid aktif)
    now = datetime.datetime.utcnow()
    live_bid = db.query(models.Product).filter(
        models.Product.sales_mode == "live_bid",
        models.Product.expiry_time > now
    ).order_by(models.Product.created_at.desc()).first()
    
    # Fallback jika tidak ada yang masih berlangsung
    if not live_bid:
        live_bid = db.query(models.Product).filter(
            models.Product.sales_mode == "live_bid"
        ).order_by(models.Product.created_at.desc()).first()

    featured_auction = format_product(live_bid) if live_bid else None

    # Rekomendasi produk (ambil produk beli langsung/market terbaru, maks 3)
    recommended_query = db.query(models.Product).filter(
        models.Product.sales_mode != "live_bid"
    ).order_by(models.Product.created_at.desc()).limit(3).all()

    recommendations = [format_product(p) for p in recommended_query]
    
    business_name = current_user.farm_name or current_user.full_name or "Toko Buah Sehat"

    return {
        "status": "success",
        "data": {
            "id": current_user.id,
            "username": current_user.username,
            "role": current_user.role,
            "full_name": current_user.full_name,
            "business_name": business_name,
            "location": current_user.location,
            "active_orders": active_orders,
            "total_orders": len(buyer_orders),
            "featured_auction": featured_auction,
            "recommendations": recommendations,
        }
    }

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

# --- ROUTES: PRODUCTS ---
@app.post("/api/products", dependencies=[Depends(auth.require_role(["petani"]))])
def create_product(
    name: str = Form(...),
    slug: str = Form(...),
    sales_mode: str = Form("market"),
    grade: Optional[str] = Form("Grade A"),
    category: Optional[str] = Form("Sayuran"),
    description: Optional[str] = Form(""),
    price: str = Form(...),
    unit: Optional[str] = Form("kg"),
    stock: Optional[int] = Form(10),
    expiry_hours: Optional[int] = Form(None),
    image_path: Optional[str] = Form(None),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    final_image_path = image_path
    if image:
        temp_dir = "temp_images"
        if not os.path.exists(temp_dir):
            os.makedirs(temp_dir)
        unique_filename = f"{int(time.time())}_product_{image.filename}"
        file_location = os.path.join(temp_dir, unique_filename)
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        final_image_path = file_location

    expiry_time = None
    if sales_mode == "live_bid":
        hours_to_add = expiry_hours if expiry_hours is not None else 6
        expiry_time = datetime.datetime.utcnow() + datetime.timedelta(hours=hours_to_add)

    new_product = models.Product(
        user_id=current_user.id,
        name=name,
        grade=grade,
        category=category,
        description=description,
        slug=slug,
        sales_mode=sales_mode,
        expiry_time=expiry_time,
        price=price,
        unit=unit,
        stock=stock,
        image_path=final_image_path
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    
    return {
        "status": "success", 
        "message": "Produk berhasil ditambahkan!", 
        "data": format_product(new_product)
    }

@app.get("/api/products")
def get_products(
    category: Optional[str] = None,
    grade: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(database.get_db)
):
    query = db.query(models.Product)
    if category and category.lower() != "semua":
        query = query.filter(models.Product.category.ilike(f"%{category}%"))
    if grade:
        query = query.filter(models.Product.grade.ilike(f"%{grade}%"))
    if search:
        query = query.filter(models.Product.name.ilike(f"%{search}%"))
        
    products = query.order_by(models.Product.created_at.desc()).all()
    return {
        "status": "success",
        "data": [format_product(p) for p in products]
    }

@app.get("/api/products/{product_id}")
def get_product_detail(product_id: int, db: Session = Depends(database.get_db)):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
    return {
        "status": "success",
        "data": format_product(product)
    }

@app.get("/api/my-products", dependencies=[Depends(auth.require_role(["petani"]))])
def get_my_products(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    products = db.query(models.Product).filter(models.Product.user_id == current_user.id).order_by(models.Product.created_at.desc()).all()
    return {
        "status": "success",
        "data": [format_product(p) for p in products]
    }

@app.delete("/api/products/{product_id}")
def delete_product(
    product_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
    if product.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Anda tidak berhak menghapus produk ini")
    
    db.delete(product)
    db.commit()
    return {"status": "success", "message": "Produk berhasil dihapus"}

@app.post("/api/komunitas")
def create_komunitas(
    name: str = Form(...),
    category: str = Form(...),
    privacy: str = Form(...),
    description: str = Form(""),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    image_path = None
    if image:
        temp_dir = "temp_images"
        if not os.path.exists(temp_dir):
            os.makedirs(temp_dir)
        unique_filename = f"{int(time.time())}_komunitas_{image.filename}"
        file_location = os.path.join(temp_dir, unique_filename)
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_path = file_location

    new_komunitas = models.Komunitas(
        name=name,
        category=category,
        privacy=privacy,
        description=description,
        image_path=image_path,
        owner_id=current_user.id
    )
    db.add(new_komunitas)
    db.commit()
    db.refresh(new_komunitas)
    return {"status": "success", "message": "Komunitas berhasil dibuat!"}

@app.get("/api/komunitas")
def get_komunitas(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    komunitas_list = db.query(models.Komunitas).order_by(models.Komunitas.created_at.desc()).all()
    
    joined_ids = {mem.komunitas_id for mem in db.query(models.CommunityMember).filter_by(user_id=current_user.id).all()}
    
    result = []
    for k in komunitas_list:
        k_dict = {
            "id": k.id,
            "name": k.name,
            "category": k.category,
            "privacy": k.privacy,
            "description": k.description,
            "is_joined": k.id in joined_ids
        }
        result.append(k_dict)
        
    return {"status": "success", "data": result}

@app.get("/api/komunitas/me")
def get_my_komunitas(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    memberships = db.query(models.CommunityMember).filter_by(user_id=current_user.id).all()
    result = []
    for mem in memberships:
        k = mem.komunitas
        result.append({
            "id": k.id,
            "name": k.name,
            "category": k.category,
            "privacy": k.privacy,
            "description": k.description,
            "is_joined": True
        })
    return {"status": "success", "data": result}

@app.post("/api/komunitas/{komunitas_id}/join")
def join_komunitas(
    komunitas_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    komunitas = db.query(models.Komunitas).filter(models.Komunitas.id == komunitas_id).first()
    if not komunitas:
        raise HTTPException(status_code=404, detail="Komunitas tidak ditemukan")
        
    existing = db.query(models.CommunityMember).filter_by(komunitas_id=komunitas_id, user_id=current_user.id).first()
    if not existing:
        new_member = models.CommunityMember(komunitas_id=komunitas_id, user_id=current_user.id)
        db.add(new_member)
        db.commit()
    
    return {"status": "success", "message": "Berhasil bergabung"}

@app.post("/api/komunitas/{komunitas_id}/chat")
def send_chat_message(
    komunitas_id: int,
    message: ChatMessageCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    komunitas = db.query(models.Komunitas).filter(models.Komunitas.id == komunitas_id).first()
    if not komunitas:
        raise HTTPException(status_code=404, detail="Komunitas tidak ditemukan")
    
    new_message = models.CommunityMessage(
        komunitas_id=komunitas_id,
        sender_id=current_user.id,
        content=message.content
    )
    db.add(new_message)
    db.commit()
    db.refresh(new_message)
    
    return {
        "status": "success", 
        "data": {
            "id": new_message.id,
            "content": new_message.content,
            "sender_name": current_user.full_name or current_user.username,
            "created_at": new_message.created_at.isoformat() + "Z"
        }
    }

@app.get("/api/komunitas/{komunitas_id}/chat")
def get_chat_messages(
    komunitas_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    komunitas = db.query(models.Komunitas).filter(models.Komunitas.id == komunitas_id).first()
    if not komunitas:
        raise HTTPException(status_code=404, detail="Komunitas tidak ditemukan")
    
    messages = db.query(models.CommunityMessage).filter(
        models.CommunityMessage.komunitas_id == komunitas_id
    ).order_by(models.CommunityMessage.created_at.asc()).all()
    
    result = []
    for msg in messages:
        result.append({
            "id": msg.id,
            "content": msg.content,
            "sender_name": msg.sender.full_name or msg.sender.username,
            "is_me": msg.sender_id == current_user.id,
            "created_at": msg.created_at.isoformat() + "Z"
        })
        
    return {"status": "success", "data": result}

@app.post("/api/berita")
def create_berita(
    title: str = Form(...),
    category: str = Form(...),
    content: str = Form(...),
    reference_source: str = Form(""),
    reference_url: str = Form(""),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    image_path = None
    if image:
        temp_dir = "temp_images"
        if not os.path.exists(temp_dir):
            os.makedirs(temp_dir)
        unique_filename = f"{int(time.time())}_berita_{image.filename}"
        file_location = os.path.join(temp_dir, unique_filename)
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_path = file_location

    new_berita = models.Berita(
        title=title,
        category=category,
        content=content,
        reference_source=reference_source,
        reference_url=reference_url,
        image_path=image_path,
        author_id=current_user.id
    )
    db.add(new_berita)
    db.commit()
    db.refresh(new_berita)
    return {"status": "success", "message": "Berita berhasil diajukan!"}

@app.get("/api/berita")
def get_berita(db: Session = Depends(database.get_db)):
    berita_list = db.query(models.Berita).order_by(models.Berita.created_at.desc()).all()
    return {"status": "success", "data": berita_list}


@app.get("/api/v1/harga-pasar")
def get_harga_pasar(db: Session = Depends(database.get_db)):
    data = db.query(models.HargaPasar).all()
    response = []
    for item in data:
        # Hitung analitik berdasarkan slug komoditas
        products = db.query(models.Product).filter(models.Product.slug == item.slug).all()
        
        total_volume = 0
        rata_rata_internal = 0
        
        if products:
            product_ids = [p.id for p in products]
            
            # Hitung tren volume penjualan dari tabel Order
            orders = db.query(models.Order).filter(models.Order.product_id.in_(product_ids)).all()
            total_volume = sum(o.quantity for o in orders)
            
            # Hitung tren harga internal (harga rata-rata petani di aplikasi)
            harga_internal = []
            for p in products:
                # Membersihkan format harga, misal '5000' atau 'Rp 5000'
                try:
                    h = int(''.join(filter(str.isdigit, str(p.price))))
                    harga_internal.append(h)
                except ValueError:
                    continue
            
            if harga_internal:
                rata_rata_internal = sum(harga_internal) / len(harga_internal)

        response.append({
            "tanggal_update": item.tanggal_update.isoformat() if item.tanggal_update else None,
            "komoditas": item.komoditas,
            "slug": item.slug,
            "harga_pasar": item.harga,
            "tren_harga_petani": rata_rata_internal,
            "tren_volume_penjualan": total_volume
        })
    return {"status": "success", "data": response}

@app.get("/api/v1/harga-pasar/{slug}")
def get_tren_harga(slug: str, db: Session = Depends(database.get_db)):
    """Mengembalikan data tren harga historis (dummy) untuk grafik berdasarkan slug"""
    # Mencari komoditas berdasarkan slug
    harga_db = db.query(models.HargaPasar).filter(models.HargaPasar.slug == slug).first()
    
    # Generate data grafik (dummy trend)
    base_price = harga_db.harga if harga_db else 15000
    
    # Buat titik harga untuk 7 hari terakhir sebagai simulasi grafik tren
    trend_data = []
    import random
    for i in range(7):
        target_date = datetime.datetime.now() - datetime.timedelta(days=6-i)
        day_label = target_date.strftime("%d %b") # e.g. '28 Aug'
        # Fluktuasi harga acak +/- 500 sampai 1500
        fluctuation = random.choice([-1, 1]) * random.randint(5, 15) * 100
        point_price = base_price + fluctuation
        trend_data.append({"day": day_label, "price": point_price})

    return {
        "status": "success", 
        "data": {
            "slug": slug,
            "current_price": base_price,
            "trend": trend_data
        }
    }

@app.get("/api/komoditas-slugs")
def get_komoditas_slugs():
    """Mengembalikan daftar slug komoditas yang tersedia dari file slugs.txt"""
    try:
        with open("slugs.txt", "r") as f:
            slugs = [line.strip() for line in f.readlines() if line.strip()]
        return {"status": "success", "data": slugs}
    except Exception as e:
        return {"status": "error", "message": f"Gagal membaca file slug: {str(e)}"}

# --- ROUTES: ORDERS ---
@app.post("/api/orders")
def create_order(
    order_data: OrderCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    product = db.query(models.Product).filter(models.Product.id == order_data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
    
    new_order = models.Order(
        product_id=order_data.product_id,
        buyer_id=current_user.id,
        quantity=order_data.quantity,
        total_price=order_data.total_price,
        status="pending"
    )
    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    
    return {
        "status": "success",
        "message": "Pesanan berhasil dibuat!",
        "data": format_order(new_order)
    }

@app.get("/api/orders")
def get_orders(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if current_user.role == "petani":
        # Pesanan masuk untuk produk milik petani
        farmer_products = db.query(models.Product).filter(models.Product.user_id == current_user.id).all()
        product_ids = [p.id for p in farmer_products]
        if not product_ids:
            return {"status": "success", "data": []}
        orders = db.query(models.Order).filter(models.Order.product_id.in_(product_ids)).order_by(models.Order.created_at.desc()).all()
    else:
        # Riwayat belanja buyer / UMKM
        orders = db.query(models.Order).filter(models.Order.buyer_id == current_user.id).order_by(models.Order.created_at.desc()).all()

    return {
        "status": "success",
        "data": [format_order(o) for o in orders]
    }

@app.put("/api/orders/{order_id}/status")
def update_order_status(
    order_id: int,
    status_update: OrderStatusUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Pesanan tidak ditemukan")
    
    # Validasi hak akses (hanya pemilik produk atau pembeli yang bisa ubah)
    if order.product.user_id != current_user.id and order.buyer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Anda tidak memiliki izin mengubah pesanan ini")
        
    order.status = status_update.status
    db.commit()
    db.refresh(order)
    
    return {
        "status": "success",
        "message": f"Status pesanan berhasil diubah menjadi {order.status}",
        "data": format_order(order)
    }

# --- ADMIN ROUTES (MANUAL TRIGGER) ---
@app.post("/api/admin/generate-trend-article")
def manual_trigger_trend_article():
    """Manual trigger to run the Gemini AI trend agent immediately."""
    import threading
    import trend_agent
    
    def run_agent():
        trend_agent.generate_trend_article()
        
    # Run in background thread so API responds immediately
    thread = threading.Thread(target=run_agent)
    thread.start()
    
    return {"status": "success", "message": "Trend article generation triggered in background."}

# --- ROUTES: LIVE BIDS ---
@app.post("/api/bids")
def create_bid(
    bid_data: BidCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    product = db.query(models.Product).filter(models.Product.id == bid_data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
    
    if product.sales_mode != "live_bid":
        raise HTTPException(status_code=400, detail="Produk ini bukan produk live bid")
        
    # Periksa apakah lelang sudah selesai
    if product.expiry_time and product.expiry_time < datetime.datetime.utcnow():
        raise HTTPException(status_code=400, detail="Lelang live bid untuk produk ini sudah selesai")
        
    # Petani tidak boleh menawar produk sendiri
    if product.user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Anda tidak dapat menawar produk milik sendiri")

    new_bid = models.Bid(
        product_id=bid_data.product_id,
        bidder_id=current_user.id,
        bid_amount=bid_data.bid_amount,
        status="pending"
    )
    db.add(new_bid)
    db.commit()
    db.refresh(new_bid)

    return {
        "status": "success",
        "message": "Tawaran Anda berhasil diajukan!",
        "data": format_bid(new_bid)
    }

@app.get("/api/bids/my")
def get_my_bids(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    """Mengambil seluruh lelang yang diikuti oleh user saat ini (buyer/UMKM)."""
    bids = db.query(models.Bid).filter(models.Bid.bidder_id == current_user.id).order_by(models.Bid.created_at.desc()).all()
    return {
        "status": "success",
        "data": [format_bid(b) for b in bids]
    }

@app.get("/api/farmer/live-bids")
def get_farmer_live_bids(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    """Mengambil seluruh produk live bid milik petani beserta daftar penawaran yang masuk."""
    live_products = db.query(models.Product).filter(
        models.Product.user_id == current_user.id,
        models.Product.sales_mode == "live_bid"
    ).order_by(models.Product.created_at.desc()).all()

    result = []
    for prod in live_products:
        prod_data = format_product(prod)
        bids = db.query(models.Bid).filter(models.Bid.product_id == prod.id).order_by(models.Bid.bid_amount.desc()).all()
        prod_data["bids"] = [format_bid(b) for b in bids]
        prod_data["is_expired"] = (prod.expiry_time < datetime.datetime.utcnow()) if prod.expiry_time else False
        result.append(prod_data)

    return {
        "status": "success",
        "data": result
    }

@app.put("/api/bids/{bid_id}/status")
def update_bid_status(
    bid_id: int,
    status_update: BidStatusUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    """Petani menyetujui atau menolak tawaran lelang."""
    bid = db.query(models.Bid).filter(models.Bid.id == bid_id).first()
    if not bid:
        raise HTTPException(status_code=404, detail="Tawaran tidak ditemukan")

    # Pastikan yang approve/reject adalah pemilik produk
    if bid.product.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Hanya pemilik produk yang dapat mengubah status tawaran")

    if status_update.status not in ["accepted", "rejected", "pending"]:
        raise HTTPException(status_code=400, detail="Status harus 'accepted', 'rejected', atau 'pending'")

    bid.status = status_update.status
    if status_update.status == "accepted":
        # Update harga produk menjadi tawaran yang diterima
        bid.product.price = str(bid.bid_amount)
    db.commit()
    db.refresh(bid)

    return {
        "status": "success",
        "message": f"Tawaran berhasil {'disetujui' if bid.status == 'accepted' else 'ditolak'}",
        "data": format_bid(bid)
    }

@app.put("/api/products/{product_id}/extend-live-bid")
def extend_live_bid(
    product_id: int,
    extend_data: ExtendLiveBid,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    """Petani memperpanjang waktu Live Bid."""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")

    if product.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Hanya pemilik produk yang dapat memperpanjang waktu lelang")

    now = datetime.datetime.utcnow()
    # Jika sudah expired, extend dari now. Jika belum expired, tambahkan dari expiry_time yang ada.
    base_time = product.expiry_time if (product.expiry_time and product.expiry_time > now) else now
    product.expiry_time = base_time + datetime.timedelta(hours=extend_data.hours)
    db.commit()
    db.refresh(product)

    return {
        "status": "success",
        "message": f"Waktu Live Bid berhasil diperpanjang {extend_data.hours} jam!",
        "data": format_product(product)
    }

# --- ROUTES: SCAN HISTORY ---
@app.post("/api/scan-history")
def save_scan_history(
    scan_data: ScanHistoryCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    new_scan = models.ScanHistory(
        user_id=current_user.id,
        commodity=scan_data.commodity,
        grade=scan_data.grade,
        confidence=scan_data.confidence,
        image_path=scan_data.image_path
    )
    db.add(new_scan)
    db.commit()
    db.refresh(new_scan)

    return {
        "status": "success",
        "message": "Riwayat scan berhasil disimpan",
        "data": format_scan_history(new_scan)
    }

@app.get("/api/scan-history")
def get_scan_histories(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    scans = db.query(models.ScanHistory).filter(
        models.ScanHistory.user_id == current_user.id
    ).order_by(models.ScanHistory.created_at.desc()).all()

    return {
        "status": "success",
        "data": [format_scan_history(s) for s in scans]
    }

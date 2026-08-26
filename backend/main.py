from fastapi import FastAPI, HTTPException, File, UploadFile, Depends, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Optional
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
        "created_at": product.created_at.isoformat() if product.created_at else None,
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

# --- SCHEMAS ---
class UserRegister(BaseModel):
    username: str # Will store email
    password: str
    role: str # "Petani" or "UMKM"

class UserLogin(BaseModel):
    username: str
    password: str

class OrderCreate(BaseModel):
    product_id: int
    quantity: int
    total_price: str

class OrderStatusUpdate(BaseModel):
    status: str

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
    grade: Optional[str] = Form("Grade A"),
    category: Optional[str] = Form("Sayuran"),
    description: Optional[str] = Form(""),
    price: str = Form(...),
    unit: Optional[str] = Form("kg"),
    stock: Optional[int] = Form(10),
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

    new_product = models.Product(
        user_id=current_user.id,
        name=name,
        grade=grade,
        category=category,
        description=description,
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
def get_komunitas(db: Session = Depends(database.get_db)):
    komunitas_list = db.query(models.Komunitas).order_by(models.Komunitas.created_at.desc()).all()
    return {"status": "success", "data": komunitas_list}

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


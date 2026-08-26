from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False) # 'petani' or 'umkm'
    
    # Relationship with other tables
    products = relationship("Product", back_populates="owner")
    komunitas = relationship("Komunitas", back_populates="owner")
    berita = relationship("Berita", back_populates="author")
    orders = relationship("Order", back_populates="buyer", foreign_keys="[Order.buyer_id]")


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    name = Column(String(100), nullable=False)
    grade = Column(String(50), nullable=True)
    category = Column(String(50), default="Sayuran", nullable=True)
    description = Column(Text, nullable=True)
    price = Column(String(100), nullable=False)
    unit = Column(String(20), default="kg", nullable=True)
    stock = Column(Integer, default=10, nullable=True)
    image_path = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    owner = relationship("User", back_populates="products")
    orders = relationship("Order", back_populates="product")

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    buyer_id = Column(Integer, ForeignKey("users.id"))
    quantity = Column(Integer, nullable=False)
    total_price = Column(String(100), nullable=False)
    status = Column(String(20), default="pending", nullable=False) # 'pending', 'diproses', 'dikirim', 'selesai', 'dibatalkan'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    product = relationship("Product", back_populates="orders")
    buyer = relationship("User", back_populates="orders", foreign_keys=[buyer_id])

class Komunitas(Base):
    __tablename__ = "komunitas"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    privacy = Column(String(20), nullable=False) # 'Publik' or 'Private'
    description = Column(Text, nullable=True)
    image_path = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="komunitas")


class Berita(Base):
    __tablename__ = "berita"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(150), nullable=False)
    category = Column(String(50), nullable=False)
    content = Column(Text, nullable=False)
    image_path = Column(String(255), nullable=True)
    reference_source = Column(String(255), nullable=True)
    reference_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    author_id = Column(Integer, ForeignKey("users.id"))
    author = relationship("User", back_populates="berita")

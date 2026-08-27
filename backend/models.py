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


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    name = Column(String(100), nullable=False)
    grade = Column(String(50))
    description = Column(Text)
    price = Column(String(100))
    image_path = Column(String(255))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    owner = relationship("User", back_populates="products")


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

class HargaPasar(Base):
    __tablename__ = "harga_pasar"

    id = Column(Integer, primary_key=True, index=True)
    komoditas = Column(String(100), nullable=False)
    harga = Column(Integer, nullable=False)
    tanggal_update = Column(DateTime, default=datetime.datetime.utcnow)

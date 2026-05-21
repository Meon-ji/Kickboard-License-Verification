from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)

    name = Column(String, nullable=False)
    birth_date=Column(String, nullable=False)
    phone_number=Column(String, nullable=False)

    license_verified = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.utcnow)

    driver_license = relationship(
        "DriverLicense",
        back_populates="user",
        uselist=False
    )

class DriverLicense(Base):
    __tablename__ = "driver_licenses"

    id = Column(Integer, primary_key=True, index=True)

    license_image_path = Column(String, nullable=False)

    verified = Column(Boolean, default=False)
    fail_reason = Column(String, nullable=True)

    user_id = Column(Integer, ForeignKey("users.id"), unique=True)

    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="driver_license")
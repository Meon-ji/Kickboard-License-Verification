from typing import Optional

from pydantic import BaseModel, EmailStr


class UserRegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    birth_date: str
    phone_number: str


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    birth_date: str
    phone_number: str
    license_verified: bool

    class Config:
        from_attributes = True


class LicenseStatusResponse(BaseModel):
    license_registered: bool
    verified: bool
    license_image_path: Optional[str] = None
    fail_reason: Optional[str] = None


class LicenseRegisterResponse(BaseModel):
    message: str
    license_image_path: str
    verified: bool


class RentalVerifyResponse(BaseModel):
    verified: bool
    rental_allowed: bool
    message: str
    fail_reason: Optional[str] = None
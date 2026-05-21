import os
import uuid
import shutil

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, DriverLicense
from app.auth import get_current_user
from app.schemas import LicenseRegisterResponse, LicenseStatusResponse


router = APIRouter(prefix="/license", tags=["License"])

UPLOAD_DIR = "uploads/license"


def save_upload_file(upload_file: UploadFile) -> str:
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    file_extension = os.path.splitext(upload_file.filename)[1]
    saved_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, saved_filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)

    return file_path


@router.post("/register", response_model=LicenseRegisterResponse)
def register_license(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="이미지 파일만 업로드할 수 있습니다."
        )

    saved_path = save_upload_file(file)

    existing_license = (
        db.query(DriverLicense)
        .filter(DriverLicense.user_id == current_user.id)
        .first()
    )

    if existing_license:
        existing_license.license_image_path = saved_path
        existing_license.verified = True
        existing_license.fail_reason = None

    else:
        new_license = DriverLicense(
            license_image_path=saved_path,
            verified=True,
            fail_reason=None,
            user_id=current_user.id
        )
        db.add(new_license)

    current_user.license_verified = True

    db.commit()

    return {
        "message": "운전면허증 이미지가 등록되었습니다.",
        "license_image_path": saved_path,
        "verified": True
    }


@router.get("/status", response_model=LicenseStatusResponse)
def get_license_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    license_info = (
        db.query(DriverLicense)
        .filter(DriverLicense.user_id == current_user.id)
        .first()
    )

    if not license_info:
        return {
            "license_registered": False,
            "verified": False,
            "license_image_path": None,
            "fail_reason": None
        }

    return {
        "license_registered": True,
        "verified": license_info.verified,
        "license_image_path": license_info.license_image_path,
        "fail_reason": license_info.fail_reason
    }
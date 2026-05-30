import os
import uuid
import shutil
from typing import List

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, DriverLicense, RentalVerification
from app.auth import get_current_user
from app.schemas import RentalVerifyResponse, RentalHistoryResponse

router = APIRouter(prefix="/rental", tags=["Rental"])

UPLOAD_DIR = "uploads/selfie"

def save_selfie_file(upload_file: UploadFile) -> str:
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    file_extension = os.path.splitext(upload_file.filename)[1]
    saved_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, saved_filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
    
    return file_path.replace("\\", "/")

@router.post("/verify-face", response_model=RentalVerifyResponse)
def verify_face(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    license_info = (
        db.query(DriverLicense)
        .filter(DriverLicense.user_id == current_user.id)
        .first()
    )

    if not license_info:
        verification = RentalVerification(
            selfie_image_path = "",
            result = False,
            fail_reason = "운전면허증 미등록",
            user_id = current_user.id
        )

        db.add(verification)
        db.commit()

        return {
            "verified": False,
            "rental_allowed": False,
            "message": "운전면허증이 등록되어 있지 않습니다.",
            "fail_reason": "운전면허증 미등록"
        }
    
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="이미지 파일만 업로드 가능합니다."
        )
    
    selfie_path = save_selfie_file(file)

    #TODO: 추후 AI 얼굴 비교 로직으로 교체
    #license_info.license_image_path와 selife_path를 비교할 예정임
    is_same_person = True

    if is_same_person:
        verification = RentalVerification(
            selfie_image_path=selfie_path,
            result=True,
            fail_reason=None,
            user_id=current_user.id
        )

        db.add(verification)
        db.commit()

        return {
            "verified": True,
            "rental_allowed": True,
            "message": "본인 인증에 성공하였습니다. 전동 킥보드 대여가 가능합니다.",
            "fail_reason": None
        }
    
    verification = RentalVerification(
        selfie_image_path=selfie_path,
        result=False,
        fail_reason="운전면허증 사진과 현재 얼굴이 일치하지 않습니다.",
        user_id=current_user.id
    )

    db.add(verification)
    db.commit()

    return {
        "verified": False,
        "rental_allowed": False,
        "message": "본인 인증에 실패했습니다. 전동 킥보드 대여가 불가능합니다.",
        "fail_reason": "운전면허증 사진과 현재 얼굴이 일치하지 않습니다."
    }

@router.get("/history", response_model=List[RentalHistoryResponse])
def get_rental_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    histories = (
        db.query(RentalVerification)
        .filter(RentalVerification.user_id == current_user.id)
        .order_by(RentalVerification.created_at.desc())
        .all()
    )

    return histories
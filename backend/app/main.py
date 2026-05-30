from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routers import auth_router, license_router, rental_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Kickboard License Verification API",
    description="전동 킥보드 운전면허 도용 방지 시스템 백엔드",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(license_router.router)
app.include_router(rental_router.router)

@app.get("/")
def root():
    return{
        "message": "Kickboard License Verification API"
    }

@app.get("/health")
def health_check():
    return {
        "status": "ok"
    }
import os
from fastapi import FastAPI, Depends, HTTPException, Header
from pydantic import BaseModel
from decimal import Decimal
from sqlalchemy import create_engine, Column, Integer, String, Numeric, text
from sqlalchemy.orm import declarative_base, sessionmaker, Session
import jwt

app = FastAPI()

# Database setup
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "corebank_user")
DB_PASS = os.getenv("DB_PASS", "corebank_pass")
DB_NAME = os.getenv("DB_NAME", "corebank")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Account(Base):
    __tablename__ = "accounts"
    id = Column(Integer, primary_key=True, index=True)
    account_number = Column(String(50), unique=True, index=True, nullable=False)
    balance = Column(Numeric(15, 2), nullable=False)

# JWT Secret
JWT_SECRET = os.getenv("JWT_SECRET", "super_secret_banking_key")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def verify_jwt(authorization: str = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authorization scheme")
        
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

class TransferRequest(BaseModel):
    amount: Decimal
    destination: str

@app.post("/process-transfer")
def process_transfer(request: TransferRequest, db: Session = Depends(get_db), user: dict = Depends(verify_jwt)):
    # Verify the dummy account has enough funds, or just process logic
    # In a real app, we'd deduct from user's account and add to destination
    # For this demo, let's just find the dummy account and deduct the funds
    dummy_acc = db.query(Account).filter(Account.account_number == "DUMMY-100K").first()
    
    if not dummy_acc:
        raise HTTPException(status_code=404, detail="Dummy account not found for simulation")
    
    if dummy_acc.balance < request.amount:
        raise HTTPException(status_code=400, detail="Insufficient funds in dummy account")
        
    dummy_acc.balance -= request.amount
    db.commit()
    
    return {
        "status": "success",
        "message": f"Successfully transferred {request.amount} to {request.destination}",
        "user_involved": user.get("username"),
        "remaining_dummy_balance": dummy_acc.balance
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

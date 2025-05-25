from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import SessionLocal
import schemas, crud, models

app = FastAPI()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Register user
@app.post("/register", response_model=schemas.UserOut)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    return crud.create_user(db, user)

# Login user
@app.post("/login", response_model=schemas.UserOut)
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    auth_user = crud.authenticate_user(db, user.username, user.password)
    if not auth_user:
        raise HTTPException(status_code=400, detail="Invalid username or password")
    return auth_user

# Check username availability
@app.get("/check-username")
def check_username(username: str = Query(...), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    return {"available": user is None}

# Check email availability
@app.get("/check-email")
def check_email(email: str = Query(...), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == email).first()
    return {"available": user is None}

# Check phone number availability
@app.get("/check-phone")
def check_phone(phone: str = Query(...), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.phone == phone).first()
    return {"available": user is None}
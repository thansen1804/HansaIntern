from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException
from models import User
import bcrypt

def create_user(db, user):
    hashed_pw = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt())
    db_user = User(
        name=user.name,
        username=user.username,
        dob=user.dob,
        email=user.email,
        phone=user.phone,
        password_hash=hashed_pw.decode(),
    )
    try:
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except IntegrityError as e:
        db.rollback()
        # Extract error message from MSSQL (via pyodbc)
        msg = str(e.orig)
        print("IntegrityError:", msg)  # For debugging
        
        # Adjust error handling based on MSSQL messages
        if "UNIQUE KEY" in msg and "username" in msg:
            raise HTTPException(status_code=400, detail="Username already exists.")
        elif "UNIQUE KEY" in msg and "email" in msg:
            raise HTTPException(status_code=400, detail="Email already registered.")
        elif "UNIQUE KEY" in msg and "phone" in msg:
            raise HTTPException(
                status_code=400, detail="Phone number already registered."
            )
        else:
            raise HTTPException(status_code=400, detail="Registration failed.")

def authenticate_user(db, username: str, password: str):
    user = db.query(User).filter(User.username == username).first()
    if not user:
        return None
    if bcrypt.checkpw(password.encode(), user.password_hash.encode()):
        return user
    return None
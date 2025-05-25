from pydantic import BaseModel, EmailStr
from datetime import date
from typing import Optional

class UserCreate(BaseModel):
    name: str
    username: str
    dob: Optional[date]  # Optional if date of birth is not mandatory
    email: EmailStr
    phone: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserOut(BaseModel):
    id: int
    name: str
    username: str
    email: EmailStr
    phone: str
    dob: Optional[date]

    class Config:
        orm_mode = True
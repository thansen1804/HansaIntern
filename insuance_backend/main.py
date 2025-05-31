from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import schemas, crud, models
from sqlalchemy import inspect
from typing import List
from pydantic import BaseModel
from sqlalchemy import inspect, text
from sqlalchemy import MetaData, Table
app = FastAPI()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
class TableColumn(BaseModel):
    name: str
    type: str
    is_identity: bool

# # DB Dependency
# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()

@app.get("/get-table-schema", response_model=List[TableColumn])
def get_table_schema(table_name: str = Query(...)):
    with engine.connect() as conn:
        query = text(f"""
            SELECT 
                c.name AS name,
                t.name AS type,
                c.is_identity AS is_identity
            FROM sys.columns c
            JOIN sys.types t ON c.user_type_id = t.user_type_id
            WHERE c.object_id = OBJECT_ID(:table_name)
        """)
        result = conn.execute(query, {"table_name": table_name})
        return [
            {"name": row.name, "type": row.type, "is_identity": row.is_identity}
            for row in result
        ]

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


@app.get("/company-tables")
def get_company_tables(db: Session = Depends(get_db)):
    inspector = inspect(db.bind)
    all_tables = inspector.get_table_names()
    company_tables = [table for table in all_tables if table.startswith("Company_")]
    return {"tables": company_tables}

# @app.get("/table-schema/{table_name}")
# def get_table_schema(table_name: str, db: Session = Depends(get_db)):
#     inspector = inspect(engine)
#     if table_name not in inspector.get_table_names():
#         raise HTTPException(status_code=404, detail="Table not found")
#     columns = inspector.get_columns(table_name)
#     schema = [{"name": col["name"], "type": str(col["type"])} for col in columns]
#     return schema

# class TableColumn(BaseModel):
#     name: str
#     type: str
# @app.get("/get-table-schema", response_model=List[TableColumn])
# def get_table_schema(table_name: str = Query(...)):
#     with engine.connect() as conn:
#         query = text(f"""
#             SELECT COLUMN_NAME as name, DATA_TYPE as type
#             FROM INFORMATION_SCHEMA.COLUMNS
#             WHERE TABLE_NAME = :table_name
#         """)
#         result = conn.execute(query, {"table_name": table_name})
#         columns = [{"name": row.name, "type": row.type} for row in result]
#         return columns
# class TableColumn(BaseModel):
#     name: str
#     type: str
# @app.get("/get-table-schema", response_model=List[TableColumn])
# def get_table_schema_query(table_name: str = Query(...)):
#     with engine.connect() as conn:
#         query = text("""
#             SELECT COLUMN_NAME as name, DATA_TYPE as type
#             FROM INFORMATION_SCHEMA.COLUMNS
#             WHERE TABLE_NAME = :table_name
#         """)
#         result = conn.execute(query, {"table_name": table_name})
#         columns = [{"name": row.name, "type": row.type} for row in result]
#         return columns


from sqlalchemy import text

@app.post("/insert-data/{table_name}")
def insert_data(table_name: str, data: dict, db: Session = Depends(get_db)):
    inspector = inspect(engine)
    if table_name not in inspector.get_table_names():
        raise HTTPException(status_code=404, detail="Table not found")

    # Fetch identity columns (e.g., 'id')
    with engine.connect() as conn:
        identity_query = text("""
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS c
            INNER JOIN sys.identity_columns ic 
                ON OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME) = ic.object_id 
                AND c.COLUMN_NAME = ic.name
            WHERE c.TABLE_NAME = :table_name
        """)
        identity_result = conn.execute(identity_query, {"table_name": table_name})
        identity_columns = {row[0] for row in identity_result}

    # Get all valid columns
    columns = {col['name'] for col in inspector.get_columns(table_name)}

    # Filter out identity columns
    insert_data = {k: v for k, v in data.items() if k in columns and k not in identity_columns}

    if not insert_data:
        raise HTTPException(status_code=400, detail="No valid columns to insert (identity fields are excluded)")

    try:
        metadata = MetaData()
        table = Table(table_name, metadata, autoload_with=engine)
        insert_stmt = table.insert().values(**insert_data)
        db.execute(insert_stmt)
        db.commit()
        return {"detail": "Data inserted successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Insert failed: {e}")
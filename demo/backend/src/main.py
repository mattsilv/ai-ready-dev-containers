from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas
from .database import engine, get_db, SessionLocal
from typing import List
import time
import os
from fastapi.responses import JSONResponse

# Ensure the directory for SQLite exists
os.makedirs(os.path.dirname("/app/data/demo.db"), exist_ok=True)

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Demo API", description="Dev Container Demo API")

# Add CORS middleware with proper frontend URLs
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3001", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Remove the rate limiting middleware for now to fix the error
# We'll add it back properly later if needed

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/")
def read_root():
    return {"message": "Welcome to the Demo API"}

# Create sample data if the database is empty
@app.on_event("startup")
def create_initial_data():
    db = SessionLocal()
    # Check if we have any items
    if db.query(models.Item).count() == 0:
        # Add some sample items
        sample_items = [
            {"name": "Sample Item 1", "description": "This is a sample item"},
            {"name": "Sample Item 2", "description": "Another sample item"},
            {"name": "Sample Item 3", "description": "Yet another sample item"}
        ]
        for item_data in sample_items:
            db_item = models.Item(**item_data)
            db.add(db_item)
        db.commit()
    db.close()

@app.get("/items", response_model=List[schemas.Item])
def get_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    items = db.query(models.Item).offset(skip).limit(limit).all()
    return items

@app.post("/items", response_model=schemas.Item)
def create_item(item: schemas.ItemCreate, db: Session = Depends(get_db)):
    db_item = models.Item(**item.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.get("/items/{item_id}", response_model=schemas.Item)
def get_item(item_id: int, db: Session = Depends(get_db)):
    db_item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return db_item
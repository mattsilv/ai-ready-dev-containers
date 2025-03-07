from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pydantic_settings import BaseSettings
import os
from dotenv import load_dotenv

load_dotenv()

# Ensure the data directory exists
data_dir = "/app/data"
os.makedirs(data_dir, exist_ok=True)
if os.path.exists(data_dir):
    os.chmod(data_dir, 0o777)  # Ensure directory is writable

class Settings(BaseSettings):
    # Default to SQLite, stored in a volume for persistence
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:////app/data/demo.db")

settings = Settings()

# Create SQLAlchemy engine
# Connect with connect_args={"check_same_thread": False} for SQLite
engine = create_engine(
    settings.DATABASE_URL, 
    connect_args={"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
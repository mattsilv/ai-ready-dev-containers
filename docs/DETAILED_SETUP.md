# Detailed Dev Container Setup Guide

This document provides comprehensive instructions for setting up a development container environment for your project. The example configuration is based on a Master Data Management (MDM) platform using React, FastAPI, and PostgreSQL.

## System Architecture

The development environment consists of three main services:

```mermaid
graph TD
    subgraph "Development Environment"
        DevUser((User)) --> DevFE[React Frontend]
        DevFE <--> DevBE[FastAPI Backend]
        DevBE <--> DevDB[(Local PostgreSQL)]
    end

    subgraph "Production Environment"
        ProdUser((User)) --> ProdFE[React Frontend]
        ProdFE <--> ProdBE[FastAPI Backend]
        ProdBE <--> SupaDB[(Supabase PostgreSQL)]
    end

    subgraph "Core Functionality"
        DevBE --> AM[Attribute Management]
        DevBE --> DD[Data Dictionary]
        DevBE --> DM[Domain Management]
    end

    classDef users fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef frontend fill:#61DAFB,stroke:#333,stroke-width:1px,color:black;
    classDef backend fill:#3E9B89,stroke:#333,stroke-width:1px,color:white;
    classDef database fill:#336791,stroke:#333,stroke-width:1px,color:white;
    classDef functionality fill:#FFB74D,stroke:#333,stroke-width:1px,color:black;

    class DevUser,ProdUser users;
    class DevFE,ProdFE frontend;
    class DevBE,ProdBE backend;
    class DevDB,SupaDB database;
    class AM,DD,DM functionality;
```

## Project Structure

A complete dev container setup includes the following directory structure:

```
project-root/
├── .devcontainer/
│   ├── devcontainer.json
│   └── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── alembic.ini
│   ├── migrations/
│   │   └── versions/
│   └── src/
│       ├── main.py
│       ├── models/
│       ├── schemas/
│       └── database.py
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   └── src/
├── .docker/
│   ├── postgres-data/
│   └── init-scripts/
│       └── setup.sql
└── .env.example
```

## Configuration Files

Below are the detailed configuration files needed for a complete dev container setup:

### 1. Dev Container Configuration

#### `.devcontainer/devcontainer.json`

This file configures VS Code's behavior when opening the project in a container:

```json
{
  "name": "MDM Dev Environment",
  "dockerComposeFile": "docker-compose.yml",
  "service": "backend",
  "workspaceFolder": "/app",
  "forwardPorts": [3000, 8000, 5432],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "dsznajder.es7-react-js-snippets",
        "ms-vscode.vscode-typescript-next",
        "mtxr.sqltools",
        "mtxr.sqltools-driver-pg"
      ],
      "settings": {
        "python.linting.enabled": true,
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": true
        }
      }
    }
  },
  "remoteUser": "vscode"
}
```

#### `.devcontainer/docker-compose.yml`

This file defines the services that make up your development environment:

```yaml
version: "3.8"

services:
  backend:
    build:
      context: ../backend
      target: development
    volumes:
      - ../backend:/app
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/mdm_db
    env_file:
      - ../backend/.env
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build: ../frontend
    volumes:
      - ../frontend:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    env_file:
      - ../frontend/.env

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mdm_db
    volumes:
      - ../.docker/postgres-data:/var/lib/postgresql/data
      - ../.docker/init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mdm_db"]
      interval: 10s
      timeout: 5s
      retries: 3
```

### 2. Backend Configuration

#### `backend/Dockerfile`

This file defines how to build the backend container:

```dockerfile
FROM python:3.12-slim as development

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

FROM python:3.12-slim as production
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=development /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=development /usr/local/bin /usr/local/bin
COPY . .

CMD ["gunicorn", "src.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

#### `backend/requirements.txt`

This file lists the Python dependencies:

```
fastapi==0.104.1
uvicorn==0.23.2
gunicorn==21.2.0
psycopg2-binary==2.9.9
alembic==1.12.1
pydantic==2.4.2
pydantic-settings==2.0.3
python-dotenv==1.0.0
sqlalchemy==2.0.23
asyncpg==0.28.0
httpx==0.25.1
```

#### `backend/src/database.py`

This file configures the database connection:

```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pydantic_settings import BaseSettings
import os
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://user:password@db:5432/mdm_db")

settings = Settings()

# Create SQLAlchemy engine
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

#### `backend/alembic.ini`

This file configures database migrations:

```ini
[alembic]
script_location = migrations
prepend_sys_path = .
sqlalchemy.url = postgresql://user:password@db:5432/mdm_db

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

#### `backend/src/main.py`

This file defines the FastAPI application:

```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas
from .database import engine, get_db

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="MDM API", description="Master Data Management API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/")
def read_root():
    return {"message": "Welcome to the MDM API"}

# Sample routes for attribute management
@app.get("/attributes", response_model=list[schemas.Attribute])
def get_attributes(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    attributes = db.query(models.Attribute).offset(skip).limit(limit).all()
    return attributes

@app.post("/attributes", response_model=schemas.Attribute)
def create_attribute(attribute: schemas.AttributeCreate, db: Session = Depends(get_db)):
    db_attribute = models.Attribute(**attribute.dict())
    db.add(db_attribute)
    db.commit()
    db.refresh(db_attribute)
    return db_attribute
```

#### `backend/src/models.py`

This file defines the database models:

```python
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class Attribute(Base):
    __tablename__ = "attributes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    display_name = Column(String)
    description = Column(Text)
    data_type = Column(String)
    format = Column(String, nullable=True)
    is_nullable = Column(Boolean, default=True)
    default_value = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    domain_id = Column(Integer, ForeignKey("domains.id"), nullable=True)
    domain = relationship("Domain", back_populates="attributes")

class Domain(Base):
    __tablename__ = "domains"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    attributes = relationship("Attribute", back_populates="domain")
```

#### `backend/src/schemas.py`

This file defines the Pydantic models for API validation:

```python
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class AttributeBase(BaseModel):
    name: str
    display_name: str
    description: Optional[str] = None
    data_type: str
    format: Optional[str] = None
    is_nullable: bool = True
    default_value: Optional[str] = None
    domain_id: Optional[int] = None

class AttributeCreate(AttributeBase):
    pass

class Attribute(AttributeBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

class DomainBase(BaseModel):
    name: str
    description: Optional[str] = None

class DomainCreate(DomainBase):
    pass

class Domain(DomainBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    attributes: List[Attribute] = []

    class Config:
        orm_mode = True
```

### 3. Frontend Configuration

#### `frontend/Dockerfile`

This file defines how to build the frontend container:

```dockerfile
FROM node:20-alpine as development

WORKDIR /app

COPY package*.json ./
RUN npm ci
# Keep node_modules in the container, not in the mounted volume
ENV NODE_PATH=/app/node_modules

CMD ["npm", "run", "dev"]

FROM node:20-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine as production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 4. Database Initialization

#### `.docker/init-scripts/setup.sql`

This file runs when the PostgreSQL container first initializes:

```sql
-- Enable extensions that match Supabase
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create similar schemas to Supabase
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;

-- Create a role similar to Supabase's anon role
CREATE ROLE anon NOLOGIN;
GRANT anon TO user;

-- Create a custom function for easier UUID generation (similar to Supabase)
CREATE OR REPLACE FUNCTION public.uuid_generate_v4()
RETURNS uuid
LANGUAGE SQL
AS $$
    SELECT gen_random_uuid();
$$;
```

### 5. Environment Configuration

#### `backend/.env.example`

This file serves as a template for the backend environment variables:

```
DATABASE_URL=postgresql://user:password@db:5432/mdm_db
SECRET_KEY=yoursecretkey
DEBUG=True
```

#### `frontend/.env.example`

This file serves as a template for the frontend environment variables:

```
VITE_API_URL=http://localhost:8000
VITE_DEBUG=true
```

## Setup Instructions

Follow these steps to set up the dev container:

1. **Clone Your Repository**

   ```bash
   git clone https://github.com/yourusername/your-project.git
   cd your-project
   ```

2. **Create Environment Files**

   ```bash
   cp backend/.env.example backend/.env
   cp frontend/.env.example frontend/.env
   ```

3. **Open in VS Code**

   ```bash
   code .
   ```

4. **Start the Dev Container**

   - In VS Code, press F1 and select "Remote-Containers: Reopen in Container"
   - Alternatively, click the green button in the bottom-left corner and select "Reopen in Container"

5. **Initialize Database Migrations**

   ```bash
   cd /app
   alembic init migrations

   # Edit migrations/env.py to import your models
   # Add these lines to migrations/env.py:
   # from src.models import Base
   # target_metadata = Base.metadata

   alembic revision --autogenerate -m "Initial migration"
   alembic upgrade head
   ```

6. **Start the Development Servers**

   Both servers should start automatically based on the Dockerfile CMD instructions. If they don't:

   ```bash
   # In one terminal
   cd /app  # Inside the backend container
   uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

   # In another terminal
   cd /frontend  # Navigate to frontend container
   npm run dev
   ```

## Key Commands

Here are some useful commands for working with your dev container:

```bash
# Start development environment
docker-compose -f .devcontainer/docker-compose.yml up --build

# Create a new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Access services
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# Swagger UI: http://localhost:8000/docs
# PostgreSQL: postgres://user:password@localhost:5432/mdm_db

# Connect to PostgreSQL
psql -h localhost -U user -d mdm_db
```

## Customizing for Your Project

### Changing the Tech Stack

To adapt this setup for different technologies:

1. **Different Frontend Framework**:

   - Update the frontend Dockerfile with the appropriate base image
   - Modify package.json with the relevant dependencies
   - Update the frontend CMD in the Dockerfile

2. **Different Backend Framework**:

   - Update the backend Dockerfile with the appropriate base image
   - Modify requirements.txt with the relevant dependencies
   - Update the backend CMD in the Dockerfile

3. **Different Database**:
   - Replace the PostgreSQL service in docker-compose.yml
   - Update the database connection code in the backend
   - Modify the database initialization scripts

### Scaling the Dev Container

For larger projects, consider these additions:

1. **Additional Services**:

   - Add Redis for caching
   - Include Elasticsearch for search
   - Add RabbitMQ or Kafka for message queuing

2. **Development Tools**:
   - Add Adminer or pgAdmin for database management
   - Include tools like Mailhog for email testing
   - Add monitoring tools like Prometheus and Grafana

## Troubleshooting

### Common Issues

1. **Container Build Failures**:

   - Check Docker for sufficient resources
   - Verify network connectivity
   - Look for specific error messages in the build logs

2. **Database Connection Issues**:

   - Verify the database service is running
   - Check the connection string format
   - Ensure the database initialization completed successfully

3. **Volume Mounting Issues**:

   - Verify file permissions in mounted directories
   - Check for syntax errors in docker-compose.yml
   - Try using named volumes instead of bind mounts

4. **VS Code Extension Problems**:
   - Reinstall the Dev Containers extension
   - Check for extension compatibility issues
   - Update VS Code to the latest version

### Getting Help

If you encounter issues not covered here:

1. Check the [VS Code Dev Containers documentation](https://code.visualstudio.com/docs/remote/containers)
2. Review the [Docker documentation](https://docs.docker.com/)
3. Search for issues on the GitHub repository
4. Post questions in the Discussion section of the repository

## Advanced Configuration

### Multi-stage Builds

The provided Dockerfiles use multi-stage builds to optimize for both development and production:

- Development stage: Includes development tools and uses volume mounts
- Production stage: Optimized for size and security

### DevContainer Features

VS Code's Dev Containers support "features" that add common development tools:

```json
// Add this to devcontainer.json
"features": {
  "ghcr.io/devcontainers/features/github-cli:1": {},
  "ghcr.io/devcontainers/features/docker-in-docker:2": {},
  "ghcr.io/devcontainers/features/node:1": {}
}
```

### Extending the Dev Container

To add custom initialization scripts:

```json
// Add this to devcontainer.json
"postCreateCommand": "bash .devcontainer/post-create.sh"
```

Then create `.devcontainer/post-create.sh`:

```bash
#!/bin/bash
echo "Setting up additional tools..."
# Add your custom setup commands here
```

## Best Practices

1. **Version Control**:

   - Keep all configuration in version control
   - Exclude `.env` files and postgres-data directory

2. **Environment Separation**:

   - Use different environment variables for development and production
   - Maintain parity between environments for consistency

3. **Migration Management**:

   - Always use Alembic for database changes
   - Document migrations with descriptive messages

4. **Development Workflow**:
   - Use the Dev Container for consistent development environments
   - Run tests inside the container to ensure environment consistency

## Further Reading

- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/remote/containers)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://reactjs.org/docs/getting-started.html)
- [Supabase Documentation](https://supabase.io/docs)

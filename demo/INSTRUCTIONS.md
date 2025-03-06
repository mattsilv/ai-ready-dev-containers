# Dev Container Demo Setup Instructions

This directory contains a complete working example of a dev container setup with React frontend, FastAPI backend, and PostgreSQL database. This guide will help you get started with running and exploring the demo.

## Prerequisites

Make sure you have the following installed on your system:

- [Docker](https://www.docker.com/products/docker-desktop/) (Docker Desktop recommended)
- [VS Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## Quick Start

### Option 1: Using the Setup Script (Recommended)

Run the included setup script that will check prerequisites and create all necessary directories:

```bash
# Navigate to the demo directory
cd /path/to/ai-ready-dev-containers/demo

# Run the setup script
./setup.sh
```

After running the setup script, open VS Code and start the container:

```bash
code .
```

### Option 2: Manual Setup

If you prefer to set up manually:

1. Create the PostgreSQL data directory first (critical step):

   ```bash
   mkdir -p .docker/postgres-data
   ```

2. Open this `demo` directory in VS Code:

   ```bash
   code /path/to/ai-ready-dev-containers/demo
   ```

3. When prompted by VS Code, click "Reopen in Container" or use the command palette (F1) and select "Remote-Containers: Reopen in Container".

VS Code will build and start the dev containers defined in `.devcontainer/docker-compose.yml`. This may take a few minutes the first time.

4. Once the containers are running, you can access:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - PostgreSQL: postgresql://user:password@localhost:5432/demo_db

## Key Features to Explore

This demo showcases several important dev container features:

### 1. Consistent Environment

All team members work with identical versions of:
- Python 3.12
- Node.js 20
- PostgreSQL 16
- Specific package versions defined in `requirements.txt` and `package.json`

### 2. VS Code Integration

The `.devcontainer/devcontainer.json` configures:
- Recommended extensions for Python and JavaScript development
- Editor settings like format-on-save
- Port forwarding

### 3. Multi-Container Setup

The dev environment consists of three interconnected services:
- Backend (FastAPI)
- Frontend (React)
- Database (PostgreSQL)

### 4. Development Workflow

Experience a seamless development workflow:
- Code changes in the backend automatically trigger a reload
- Code changes in the frontend automatically refresh the browser
- Database migrations can be created and applied using Alembic

### 5. AI Ready

The dev container is configured for AI-assisted development:
- `.cursor.json` file provides context for Cursor IDE
- Directory structure and configurations follow best practices

## Common Tasks

Here are some commands you can try within the dev container:

### Backend (FastAPI)

```bash
# Create a new database migration
cd /app
alembic revision --autogenerate -m "Add new field"

# Apply migrations
alembic upgrade head

# Manual API start (if needed)
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend (React)

```bash
# Install a new package
cd /app
npm install some-package

# Manual dev server start (if needed)
npm run dev
```

### Database (PostgreSQL)

```bash
# Connect to the database
psql -h db -U user -d demo_db
# Password: password

# Sample queries
\dt  # List tables
SELECT * FROM items;
```

## Customizing the Demo

You can use this demo as a starting point for your own projects:

1. Modify `backend/src/models.py` to define your database schema
2. Update `backend/src/main.py` to add new API endpoints
3. Customize the React components in `frontend/src/`
4. Adjust container configurations in `.devcontainer/docker-compose.yml`

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Developer Machine                  │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                    VS Code Editor                    │
└───────────────────────┬─────────────────────────────┘
                        │ Dev Containers Extension
                        ▼
┌─────────────────────────────────────────────────────┐
│                    Docker Compose                    │
└───────┬─────────────────┬──────────────────┬────────┘
        │                 │                  │
        ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌─────────────────┐
│   Frontend   │  │    Backend   │  │    Database     │
│  Container   │◄─┤  Container   │◄─┤   Container     │
│    (React)   │  │   (FastAPI)  │  │  (PostgreSQL)   │
└──────┬───────┘  └──────┬───────┘  └─────────────────┘
       │                 │
       ▼                 ▼
┌─────────────┐  ┌─────────────┐
│  Port 3000  │  │  Port 8000  │
└─────────────┘  └─────────────┘
```

## Troubleshooting

### Common Issues

1. **Container fails to start**: The most common cause is the missing postgres-data directory. Make sure you've created it before starting the container:
   ```bash
   mkdir -p .docker/postgres-data
   ```

2. **Port conflicts**: If ports 3000, 8000, or 5432 are already in use on your host machine, modify the port mappings in `.devcontainer/docker-compose.yml`.

3. **Docker resource limits**: If containers fail to start, check that Docker has sufficient resources allocated (memory, CPU).

4. **Volume mounting issues**: If changes aren't reflected, check that volume mounts are working correctly.

### Getting Help

If you encounter issues with this demo, please open an issue on the GitHub repository: https://github.com/mattsilv/ai-ready-dev-containers/issues
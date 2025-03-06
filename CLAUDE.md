# CLAUDE.md - AI-Ready Dev Containers Guide

## Commands
- **Backend**: `uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload`
- **Frontend**: `npm run dev`
- **Database**: 
  - `alembic revision --autogenerate -m "message"` (create migration)
  - `alembic upgrade head` (apply migrations)
- **Container**: `docker-compose -f .devcontainer/docker-compose.yml up --build`

## Code Style Guidelines
- **Python**: PEP8 formatted, FastAPI conventions for route definitions
- **JavaScript/TypeScript**: ESLint + Prettier
- **Naming**: camelCase for JS/TS, snake_case for Python
- **File Structure**: Follow existing project patterns
- **Editor Settings**: Use formatOnSave, respect .editorconfig
- **Error Handling**: Centralized error handling with appropriate HTTP codes
- **Types**: Strong typing with TypeScript and Python type hints

## Development Environment
- Dev containers configured with Docker Compose
- VS Code with Dev Containers extension
- Multi-stage Dockerfiles for dev/prod environments
- Always match production parity in local environment
- Configure AI tools with `.cursor.json` following CURSOR_RULES.md
# Local Development with Dev Containers

This guide covers best practices for local development using dev containers, focusing on workflow efficiency, collaboration, and consistency.

## Why Dev Containers for Local Development?

Dev containers offer several advantages for local development:

1. **Consistency**: Every team member works in identical environments
2. **Isolation**: Dependencies are isolated from your host system
3. **Onboarding**: New team members can start coding in minutes, not days
4. **Compatibility**: Works with AI coding assistants out of the box
5. **Portability**: Runs consistently across different operating systems

## Setting Up Your Local Environment

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Docker Compose on Linux)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Opening a Project in a Dev Container

1. Clone your project repository

   ```bash
   git clone https://github.com/your-org/your-project.git
   cd your-project
   ```

2. Open the project in VS Code

   ```bash
   code .
   ```

3. VS Code should detect the dev container configuration and prompt you to reopen in a container. If not, click the green button in the bottom-left corner and select "Reopen in Container"

4. Wait for the container to build and initialize (this may take a few minutes the first time)

## Working with Dev Containers

### Directory Structure

A typical dev container project follows this structure:

```
project-root/
├── .devcontainer/
│   ├── devcontainer.json      # Main configuration for VS Code
│   └── docker-compose.yml     # Define and configure services
├── .docker/                   # Additional Docker resources
│   ├── data/                  # Persisted data volumes
│   └── init-scripts/          # Initialization scripts
├── backend/                   # Backend service directory
├── frontend/                  # Frontend service directory
└── .env.example               # Template for environment variables
```

### Accessing Services

Services in your dev container are accessible via their mapped ports:

| Service  | Default Port | Access URL                  |
| -------- | ------------ | --------------------------- |
| Frontend | 3000         | http://localhost:3000       |
| Backend  | 8000         | http://localhost:8000       |
| API Docs | 8000         | http://localhost:8000/docs  |
| Database | 5432         | postgresql://localhost:5432 |

### Common Local Development Tasks

#### Starting and Stopping Services

The dev container automatically starts services defined in your `docker-compose.yml`. To manually control services:

```bash
# Start all services
docker-compose -f .devcontainer/docker-compose.yml up

# Start specific service
docker-compose -f .devcontainer/docker-compose.yml up frontend

# Stop all services
docker-compose -f .devcontainer/docker-compose.yml down

# Rebuild services after changes to Dockerfile or dependencies
docker-compose -f .devcontainer/docker-compose.yml up --build
```

#### Working with the Database

Connect to your database using the VS Code database extension or command line:

```bash
# Connect to PostgreSQL
psql -h localhost -U user -d your_database

# Run database migrations
cd /app  # Inside the backend container
alembic upgrade head

# Create a new migration
alembic revision --autogenerate -m "Description of changes"
```

#### Installing Dependencies

Dependencies should be managed within the container:

**For backend (Python):**

```bash
cd /app  # Inside the backend container
pip install new-package
pip freeze > requirements.txt
```

**For frontend (Node.js):**

```bash
cd /app  # Inside the frontend container
npm install new-package
```

## Development Workflow Best Practices

### Git Integration

VS Code's Git integration works normally inside dev containers. Some tips:

- Configure Git user inside the container:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```
- Store Git credentials for easier authentication

### Environment Variables

- Never commit `.env` files with secrets
- Use `.env.example` as a template
- Consider using a secrets manager for team environments

### Shared Cache and Volumes

Dev containers use Docker volumes to persist data:

- Database data is persisted in `.docker/data`
- Package caches can be shared between containers
- Container rebuilds don't lose your data

### Code Organization

Follow these guidelines for AI-friendly code organization:

- Keep related files together
- Use consistent naming conventions
- Document interfaces between services
- Add comments explaining complex logic

### Debugging

VS Code's debugging features work seamlessly in dev containers:

1. Add appropriate launch configurations in `.vscode/launch.json`
2. Set breakpoints in your code
3. Use the VS Code debugging interface

Example `.vscode/launch.json` for a FastAPI backend:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": [
        "src.main:app",
        "--host",
        "0.0.0.0",
        "--port",
        "8000",
        "--reload"
      ],
      "jinja": true,
      "justMyCode": true
    }
  ]
}
```

## Troubleshooting

### Container Build Issues

If you encounter issues building the container:

1. Check your Docker resources (memory, disk space)
2. Verify network connectivity for downloading dependencies
3. Check logs with `docker-compose logs`

### Port Conflicts

If ports are already in use:

1. Change the port mapping in `docker-compose.yml`
2. Update the `forwardPorts` in `devcontainer.json`
3. Update your application configuration to use the new ports

### Performance Issues

For better performance:

1. Use volume mounts instead of bind mounts for heavy I/O
2. Consider using a dev container on a remote host for low-powered machines
3. Exclude large directories from VS Code's file watcher

## Further Reading

- [Microsoft Dev Containers Documentation](https://code.visualstudio.com/docs/remote/containers)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI in Containers](https://fastapi.tiangolo.com/deployment/docker/)
- [React Development Environment](https://create-react-app.dev/docs/setting-up-your-environment/)

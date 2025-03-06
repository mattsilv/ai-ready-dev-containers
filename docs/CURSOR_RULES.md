# Cursor IDE Rules for Dev Containers

This document provides guidance on configuring Cursor IDE to work effectively with dev containers. By adding appropriate rules, you can help AI coding assistants understand your development environment and generate more accurate code.

## What is Cursor IDE?

[Cursor](https://cursor.sh/) is an IDE built on top of VS Code that integrates AI assistants to help developers write, understand, and debug code more efficiently. Configuring rules for Cursor helps the AI better understand the structure and functionality of your dev container.

## Creating a `.cursor.json` File

Create a `.cursor.json` file at the root of your project with rules that describe your dev container setup:

```json
{
  "projectRules": {
    "devEnvironment": {
      "type": "devcontainer",
      "services": [
        {
          "name": "backend",
          "type": "api",
          "language": "python",
          "framework": "fastapi"
        },
        {
          "name": "frontend",
          "type": "web",
          "language": "javascript",
          "framework": "react"
        },
        {
          "name": "db",
          "type": "database",
          "engine": "postgresql"
        }
      ],
      "ports": {
        "backend": 8000,
        "frontend": 3000,
        "db": 5432
      }
    },
    "workspaceStructure": {
      "backend": "./backend",
      "frontend": "./frontend",
      "devcontainer": "./.devcontainer"
    }
  }
}
```

## Customizing Rules for Your Project

Modify the template above according to your specific project setup:

1. **Replace Services**: Update the `services` array with your actual services
2. **Adjust Ports**: Change port numbers to match your configuration
3. **Update Directory Structure**: Modify the `workspaceStructure` to match your project organization

## Variables to Customize

| Variable                 | Description                  | Example                                    |
| ------------------------ | ---------------------------- | ------------------------------------------ |
| `services[].name`        | Name of your service         | "backend", "api", "web"                    |
| `services[].type`        | Type of service              | "api", "web", "database", "cache"          |
| `services[].language`    | Programming language         | "python", "javascript", "typescript", "go" |
| `services[].framework`   | Framework used               | "fastapi", "react", "express", "django"    |
| `ports.serviceName`      | Port exposed for the service | 8000, 3000, 5432                           |
| `workspaceStructure.key` | Path to key directories      | "./backend", "./frontend"                  |

## Additional Rules for Enhanced AI Understanding

Consider adding these rules for better AI assistance:

### Database Schema Understanding

```json
"database": {
  "engine": "postgresql",
  "models": "./backend/src/models.py",
  "migrations": "./backend/migrations",
  "mainEntities": ["Attribute", "Domain"]
}
```

### API Endpoint Understanding

```json
"api": {
  "mainFile": "./backend/src/main.py",
  "routes": "./backend/src/routes",
  "schemas": "./backend/src/schemas.py"
}
```

### Frontend Component Structure

```json
"frontend": {
  "components": "./frontend/src/components",
  "pages": "./frontend/src/pages",
  "stateManagement": "redux"
}
```

## Example: Full `.cursor.json` for MDM Platform

Here's a complete example for a Master Data Management platform using React, FastAPI, and PostgreSQL:

```json
{
  "projectRules": {
    "name": "MDM Platform",
    "devEnvironment": {
      "type": "devcontainer",
      "services": [
        {
          "name": "backend",
          "type": "api",
          "language": "python",
          "framework": "fastapi"
        },
        {
          "name": "frontend",
          "type": "web",
          "language": "javascript",
          "framework": "react"
        },
        {
          "name": "db",
          "type": "database",
          "engine": "postgresql"
        }
      ],
      "ports": {
        "backend": 8000,
        "frontend": 3000,
        "db": 5432
      }
    },
    "workspaceStructure": {
      "backend": "./backend",
      "frontend": "./frontend",
      "devcontainer": "./.devcontainer"
    },
    "database": {
      "engine": "postgresql",
      "models": "./backend/src/models.py",
      "migrations": "./backend/migrations",
      "mainEntities": ["Attribute", "Domain"]
    },
    "api": {
      "mainFile": "./backend/src/main.py",
      "routes": "./backend/src/main.py",
      "schemas": "./backend/src/schemas.py"
    }
  }
}
```

## Tips for Working with AI in Dev Containers

1. **Be Explicit**: Define all services, ports, and directories clearly
2. **Include Build Instructions**: Add information about how services are built
3. **Specify Dependencies**: List major libraries and dependencies
4. **Document Relationships**: Explain how services communicate
5. **Keep Updated**: Update your rules when your project structure changes

## Troubleshooting

If the AI assistant doesn't seem to understand your project structure:

1. Verify your `.cursor.json` file is properly formatted
2. Check that file paths in `workspaceStructure` are correct
3. Ensure service names match those in your `docker-compose.yml`
4. Try adding more detailed comments in key configuration files

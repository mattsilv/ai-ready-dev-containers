# AI-Ready Dev Containers

This repository contains development containers optimized for consistent, reproducible development workflows.

## Why Dev Containers?

Development containers provide significant benefits for engineering teams:

- **Consistent Environments**: Ensures all team members work with identical dependencies, tools, and configurations
- **Reduced Onboarding Time**: New engineers can start contributing quickly without lengthy environment setup
- **Minimized "Works on My Machine" Issues**: Eliminates environment-specific bugs and troubleshooting
- **Production Parity**: Local development closely mirrors production environments
- **Version-Controlled Configuration**: Environment definitions are tracked alongside code

By standardizing development environments with containers, teams spend less time troubleshooting environment issues and more time building features.

## Repository Information

- GitHub: [mattsilv/ai-ready-dev-containers](https://github.com/mattsilv/ai-ready-dev-containers)

## Overview

This repository provides templates and best practices for creating consistent development environments using [Dev Containers](https://containers.dev/). The configurations are designed to be:

1. **Reproducible**: Ensuring consistent development experiences across team members
2. **Production-Ready**: Configurable to match production environments
3. **Flexible**: Adaptable to various tech stacks and frameworks
4. **AI-Assisted Development Ready**: Optimized for developers using AI coding assistants

## Architecture

The templates follow a consistent architecture pattern that can be customized for different tech stacks:

```mermaid
graph TD
    subgraph "Local Development Environment"
        DevUser((Developer)) --> DevFE[Frontend]
        DevFE <--> DevBE[Backend API]
        DevBE <--> DevDB[(Local Database)]
    end

    subgraph "Dev Container Configuration"
        DevContainer[Dev Container] --> Config[Configuration]
        DevContainer --> Dir[Directory Structure]
        DevContainer --> Deps[Dependencies]
        DevContainer --> Tools[Development Tools]
    end

    DevUser --> DevContainer

    subgraph "Production Deployment"
        ProdEnv[Production Environment] --> ProdContainers[Containerized Services]
    end

    DevContainer -.-> ProdContainers

    classDef users fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef components fill:#61DAFB,stroke:#333,stroke-width:1px,color:black;
    classDef database fill:#336791,stroke:#333,stroke-width:1px,color:white;
    classDef prod fill:#5D8C3E,stroke:#333,stroke-width:1px,color:white;
    classDef container fill:#4A89DC,stroke:#333,stroke-width:1px,color:white;

    class DevUser users;
    class DevFE,DevBE,Config,Dir,Deps,Tools components;
    class DevDB database;
    class ProdEnv,ProdContainers prod;
    class DevContainer container;
```

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Quick Start

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/ai-ready-dev-containers.git
   ```

2. Choose a template that matches your tech stack (e.g., React + FastAPI + PostgreSQL)

3. Copy the template files to your project:

   ```bash
   cp -r templates/react-fastapi-postgres/* /path/to/your/project/
   ```

4. Customize the configuration files as needed

5. Open your project in VS Code and click "Reopen in Container" when prompted

## Available Templates

- [React + FastAPI + PostgreSQL](./templates/react-fastapi-postgres/README.md)
- [Next.js + Express + MongoDB](./templates/nextjs-express-mongodb/README.md)
- [Vue + NestJS + MySQL](./templates/vue-nestjs-mysql/README.md)

## Documentation

- [Detailed Setup Guide](./docs/DETAILED_SETUP.md) - Comprehensive instructions for setting up dev containers
- [Cursor IDE Rules](./docs/CURSOR_RULES.md) - Instructions for configuring AI coding assistants
- [Local Development](./docs/LOCAL_DEVELOPMENT.md) - Guide for local development workflows
- [Production Deployment](./docs/PRODUCTION_DEPLOYMENT.md) - Matching production environments to local development

## Best Practices

- **Version Control**: Keep all configuration in version control
- **Environment Separation**: Use different environment variables for development and production
- **Migration Management**: Use database migration tools for schema changes
- **Consistent Development Environments**: Ensure all team members use the same environment

## Community Contributions

We welcome contributions from the community! Please check our [Contribution Guidelines](./CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

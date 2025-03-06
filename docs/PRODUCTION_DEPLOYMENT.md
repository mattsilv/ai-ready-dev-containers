# Production Deployment

This guide outlines how to configure your production environment to match your local dev container setup, ensuring consistency between development and production.

## Development-to-Production Philosophy

The core principle of our approach is: **"Production should mirror development, not the other way around."**

Benefits of this approach:

- Eliminates "works on my machine" issues
- Reduces deployment surprises
- Simplifies CI/CD pipelines
- Makes local debugging more reliable

## Deployment Options

### Option 1: Container Orchestration (Kubernetes/ECS)

For deploying directly from your dev container setup to a container orchestration platform:

1. **Extract Service Definitions**: Convert your `docker-compose.yml` to Kubernetes manifests or ECS task definitions
2. **Configure Environment Variables**: Replace development values with production secrets
3. **Set Resource Limits**: Define appropriate CPU/memory allocations
4. **Configure Networking**: Set up ingress/load balancing

Example Kubernetes conversion:

```bash
# Using kompose to convert docker-compose.yml to Kubernetes manifests
kompose convert -f .devcontainer/docker-compose.yml -o k8s/

# Review and adjust the generated files
# Apply to your cluster
kubectl apply -f k8s/
```

### Option 2: Platform-as-a-Service (Heroku, Render, etc.)

For deploying to PaaS platforms:

1. **Extract Dockerfiles**: Use the same Dockerfiles from your dev container
2. **Configure Build Process**: Setup the build pipeline to use these Dockerfiles
3. **Set Environment Variables**: Configure production values

Example Heroku deployment:

```bash
# Deploy backend
cd backend
heroku container:push web -a your-app-backend
heroku container:release web -a your-app-backend

# Deploy frontend
cd ../frontend
heroku container:push web -a your-app-frontend
heroku container:release web -a your-app-frontend
```

### Option 3: Managed Database + Serverless

For a hybrid approach:

1. **Production Database**: Use a managed database service (e.g., Supabase, AWS RDS)
2. **Backend API**: Deploy to serverless (e.g., AWS Lambda, Vercel Functions)
3. **Frontend**: Deploy to a static hosting service (e.g., Vercel, Netlify)

#### Supabase Integration

Our dev container configuration is specifically designed to be compatible with Supabase for seamless production deployment:

1. The local PostgreSQL setup includes:

   - UUID and pgcrypto extensions
   - Similar schema structure (auth, storage)
   - Supabase-like roles
   - UUID generation functions

2. To migrate to Supabase:
   - Export your database schema:
     ```bash
     pg_dump -s -h localhost -U user -d your_database > schema.sql
     ```
   - Import into Supabase:
     ```bash
     # Using Supabase CLI
     supabase db push
     ```
   - Update connection strings in your backend

## CI/CD Pipeline Integration

### GitHub Actions Example

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push backend
        uses: docker/build-push-action@v4
        with:
          context: ./backend
          file: ./backend/Dockerfile
          target: production
          push: true
          tags: yourusername/app-backend:latest

  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build and push frontend
        uses: docker/build-push-action@v4
        with:
          context: ./frontend
          file: ./frontend/Dockerfile
          target: production
          push: true
          tags: yourusername/app-frontend:latest
```

## Environment-Specific Configuration

### Managing Environment Variables

1. **Local Development**: Use `.env` files within the dev container
2. **CI/CD Pipeline**: Use secrets management in your CI/CD platform
3. **Production**: Use environment variables or a secrets manager

Example environment configuration strategy:

```
project-root/
├── .env.development       # Local development only (git ignored)
├── .env.test              # Testing environment (git ignored)
├── .env.example           # Template (committed to git)
└── .env.production.example # Production template (committed to git)
```

### Feature Flags

Use feature flags to control functionality across environments:

```python
# backend/src/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Common settings
    APP_NAME: str = "MDM API"

    # Environment-specific features
    ENABLE_CACHE: bool = False
    ENABLE_ANALYTICS: bool = False

    # Override with environment variables
    class Config:
        env_file = ".env"

settings = Settings()
```

## Database Management

### Migration Strategy

Use controlled migrations for all database changes:

1. Develop migrations locally in the dev container
2. Test migrations in a staging environment
3. Apply migrations to production during deployment

```bash
# Generate migration from changes to models
alembic revision --autogenerate -m "Add new field to attribute table"

# Apply migrations in production
alembic upgrade head
```

### Backup and Restore

Always implement backup and restore procedures:

```bash
# Backup
pg_dump -h localhost -U user -d your_database > backup.sql

# Restore
psql -h localhost -U user -d your_database < backup.sql
```

## Monitoring and Logging

Implement monitoring and logging that works consistently across environments:

1. Use structured logging (e.g., JSON format)
2. Implement health check endpoints
3. Set up metrics collection

Example FastAPI health check:

```python
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT
    }
```

## Production Security Checklist

Before going live, ensure:

- [ ] HTTPS is enabled
- [ ] Proper authentication is implemented
- [ ] Rate limiting is configured
- [ ] Database credentials are secured
- [ ] Ports are properly restricted
- [ ] Dependency vulnerabilities are scanned
- [ ] Environment variables don't contain secrets in logs
- [ ] CORS is properly configured

## Rollback Procedures

Always have a rollback plan:

1. **Version your containers**: Tag container images with version/build numbers
2. **Database rollbacks**: Test rollback migrations
3. **Blue/Green deployments**: Consider maintaining parallel environments

## Further Reading

- [Twelve-Factor App Methodology](https://12factor.net/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Supabase Documentation](https://supabase.com/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

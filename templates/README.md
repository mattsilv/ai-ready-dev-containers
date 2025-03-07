# Dev Container Templates

This directory contains templates for setting up development containers for various technology stacks. These templates have been designed with reusability and ease of use in mind, incorporating best practices learned from our demo implementation.

## Available Templates

1. **React + FastAPI + PostgreSQL** - A full-stack template with React frontend, FastAPI backend, and PostgreSQL database
2. **Next.js + Express + MongoDB** - A full-stack template with Next.js frontend, Express backend, and MongoDB database
3. **Vue.js + Django + PostgreSQL** - A full-stack template with Vue.js frontend, Django backend, and PostgreSQL database

## Best Practices for Dev Containers

Based on our experience building and troubleshooting the demo container, we've compiled these best practices:

### Container Configuration

1. **Use Development Targets**: Always specify `target: development` in your build configuration to ensure hot reloading and development tooling is available.

2. **Volume Mapping for Code**: Map your local source directories to the container to allow editing files on your host that instantly reflect in the container:

   ```yaml
   volumes:
     - ../frontend:/app
   ```

3. **Separate Volume for Node Modules**: Use anonymous volumes for node_modules to improve performance:

   ```yaml
   volumes:
     - /app/node_modules
   ```

4. **Forward All Necessary Ports**: Include all required ports in both the docker-compose.yml and devcontainer.json files.

5. **Use Consistent Port Mapping**: Maintain consistent port mappings across templates (e.g., frontend on 3001, backend on 8001).

6. **Container Labeling**: Add descriptive labels to containers for easy identification and management:
   ```yaml
   labels:
     - "com.app=dev-container"
     - "com.component=frontend"
   ```

### Backend Services

1. **Keep Backend Containers Running**: For backend services that need to stay running, use a command like `tail -f /dev/null` to prevent the container from exiting.

2. **Start Services with Explicit Commands**: Start services through explicit commands in startup scripts rather than depending on container entry points.

3. **Health Checks**: Include health endpoints in your services and verify they are accessible during startup.

4. **Log File Management**: Direct service output to log files that can be easily accessed for debugging.

### Frontend Configuration

1. **API Proxy Configuration**: Set up proper API proxying in development mode to avoid CORS issues:

   ```javascript
   // vite.config.js
   server: {
     proxy: {
       "/health": {
         target: "http://backend:8000",
         changeOrigin: true,
       }
     }
   }
   ```

2. **Environment Variables**: Configure environment variables for services to communicate with each other.

### Setup Script

1. **Prerequisite Checking**: Verify Docker is running before attempting to start containers.

2. **Port Conflict Detection**: Check for port conflicts before starting containers.

3. **Container Management**: Automatically clean up existing containers to prevent conflicts.

4. **Status Reporting**: Provide clear status information for all components with visual indicators.

5. **Error Handling**: Include robust error handling and recovery mechanisms.

6. **Log References**: Provide clear references to where logs can be found.

## Using the Templates

To use these templates:

1. Copy the relevant template directory to your project
2. Customize the docker-compose.yml and devcontainer.json files as needed
3. Create a start_here.sh script based on the provided template
4. Run the start_here.sh script to launch your development environment

## Frequently Encountered Issues and Solutions

1. **Backend API not responding**: Ensure the backend service is explicitly started and properly detached.

2. **Frontend can't connect to backend**: Check API URL configuration and proxy settings.

3. **Hot reloading not working**: Verify volume mappings are correct and development targets are used.

4. **Permission issues**: Add chmod commands to ensure proper file permissions in mounted volumes.

5. **Database connection failures**: Verify the database URL matches the configured environment.

For more detailed implementations, refer to our demo in the demo/ directory.

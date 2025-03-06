#!/bin/bash

echo "🚀 Starting Dev Container Demo"
echo "============================="

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if containers are already running
RUNNING_CONTAINERS=$(docker ps --filter "name=devcontainer" --format "{{.Names}}" | wc -l)

if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
    echo -e "${YELLOW}Found existing Dev Container components running.${NC}"
    echo ""
    echo "Options:"
    echo "  1) Use existing containers (fastest)"
    echo "  2) Stop and recreate all containers (clean slate)"
    echo "  3) Exit"
    echo ""
    read -p "Choose an option [1-3]: " option
    
    case $option in
        1)
            echo -e "${GREEN}Using existing containers...${NC}"
            # Get existing backend container ID
            BACKEND_CONTAINER=$(docker ps --filter "name=devcontainer-backend" --format "{{.ID}}")
            
            if [ -n "$BACKEND_CONTAINER" ]; then
                # Run setup script in existing container
                echo "🔄 Running setup script inside existing container..."
                docker exec -it $BACKEND_CONTAINER bash -c "chmod +x /app/setup.sh && /app/setup.sh"
            else
                echo -e "${RED}Backend container not found but other containers exist.${NC}"
                echo "Please run with option 2 to recreate all containers."
                exit 1
            fi
            ;;
        2)
            echo "🔄 Stopping existing containers and cleaning up..."
            docker-compose -f .devcontainer/docker-compose.yml down -v
            
            # Build and start the containers
            echo "🔄 Building and starting fresh containers..."
            docker-compose -f .devcontainer/docker-compose.yml up -d --build --force-recreate
            
            # Wait for containers to be ready
            echo "⏳ Waiting for containers to start (15 seconds)..."
            sleep 15
            
            # Execute setup script inside the backend container
            echo "🔄 Running setup script inside container..."
            docker exec -it devcontainer-backend-1 bash -c "chmod +x /app/setup.sh && /app/setup.sh"
            ;;
        3)
            echo "Exiting script. Existing containers are still running."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac
else
    # No existing containers found, start fresh
    echo "No existing Dev Container components found. Starting fresh..."
    
    # Check if ports are already in use
    PORT_8001_STATUS=$(lsof -i:8001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
    PORT_3001_STATUS=$(lsof -i:3001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
    PORT_5434_STATUS=$(lsof -i:5434 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
    
    if [ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ] || [ "$PORT_5434_STATUS" -eq 0 ]; then
        echo -e "${YELLOW}Warning: Some ports needed by the application are already in use:${NC}"
        [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
        [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
        [ "$PORT_5434_STATUS" -eq 0 ] && echo "- Port 5434 (PostgreSQL) is busy"
        echo ""
        echo "Please free up these ports before continuing, or edit docker-compose.yml to use different ports."
        read -p "Continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo "Exiting script."
            exit 1
        fi
    fi
    
    # Build and start the containers
    echo "🔄 Building and starting containers..."
    docker-compose -f .devcontainer/docker-compose.yml up -d --build
    
    # Wait for containers to be ready
    echo "⏳ Waiting for containers to start (15 seconds)..."
    sleep 15
    
    # Execute setup script inside the backend container
    echo "🔄 Running setup script inside container..."
    docker exec -it devcontainer-backend-1 bash -c "chmod +x /app/setup.sh && /app/setup.sh"
fi

echo ""
echo -e "${GREEN}🎉 Setup completed!${NC}"
echo ""
echo "🔍 You can access the web application at: http://localhost:3001"
echo "📚 API documentation: http://localhost:8001/docs"
echo "💾 Database: postgresql://user:password@localhost:5434/demo_db"
echo "" 
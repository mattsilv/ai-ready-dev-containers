#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Enable error handling
set -e

# Create a log file for backend output
LOG_FILE="/tmp/demo-backend-$(date +%s).log"
touch "$LOG_FILE"

echo -e "${BLUE}🚀 Dev Container Demo - START HERE${NC}"
echo "======================================="

# Check if Docker is running
echo -e "\n${YELLOW}Checking prerequisites...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop first.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker is running${NC}"
fi

# Display Docker version
echo -e "\n${YELLOW}Docker version:${NC}"
docker version | head -n 6
echo ""

# Create necessary directories
echo -e "\n${YELLOW}Setting up environment...${NC}"
mkdir -p .docker/postgres-data
mkdir -p .docker/init-scripts

# Check if setup.sql exists, create it if it doesn't
if [ ! -f .docker/init-scripts/setup.sql ]; then
    echo "-- Basic initialization for PostgreSQL" > .docker/init-scripts/setup.sql
    echo "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >> .docker/init-scripts/setup.sql
    echo "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" >> .docker/init-scripts/setup.sql
    echo -e "${GREEN}✅ Created setup.sql${NC}"
fi

# Check if ports are already in use by non-demo containers
echo -e "\n${YELLOW}Checking for port conflicts...${NC}"
PORT_8001_STATUS=$(lsof -i:8001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_3001_STATUS=$(lsof -i:3001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_5434_STATUS=$(lsof -i:5434 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)

# Check for existing containers created by this script
echo -e "\n${YELLOW}Checking for existing demo containers...${NC}"
EXISTING_CONTAINERS=$(docker ps -a --filter "label=com.demo.app=ai-ready-demo" --format "{{.Names}}" | wc -l | xargs)

if [ "$EXISTING_CONTAINERS" -gt 0 ]; then
    echo -e "${YELLOW}Found $EXISTING_CONTAINERS existing demo container(s):${NC}"
    docker ps -a --filter "label=com.demo.app=ai-ready-demo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Check if our demo containers are using the ports
    DEMO_USING_PORTS=true
    
    # If ports are in use but not by our containers, we have a conflict
    if ([ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ] || [ "$PORT_5434_STATUS" -eq 0 ]) && [ "$DEMO_USING_PORTS" = false ]; then
        echo -e "\n${YELLOW}Warning: Some ports needed by the application are in use by non-demo processes:${NC}"
        [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
        [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
        [ "$PORT_5434_STATUS" -eq 0 ] && echo "- Port 5434 (PostgreSQL) is busy"
        echo ""
        echo -e "${YELLOW}Please free up these ports before continuing.${NC}"
        exit 1
    fi
    
    echo -e "\n${YELLOW}Automatically stopping and removing existing containers for a clean start...${NC}"
    docker-compose -f .devcontainer/docker-compose.yml down -v
    echo -e "${GREEN}✅ Removed existing containers and volumes${NC}"
else
    echo -e "${GREEN}✅ No existing demo containers found${NC}"
    
    # Only check for port conflicts if no demo containers exist
    if [ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ] || [ "$PORT_5434_STATUS" -eq 0 ]; then
        echo -e "${YELLOW}Warning: Some ports needed by the application are already in use:${NC}"
        [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
        [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
        [ "$PORT_5434_STATUS" -eq 0 ] && echo "- Port 5434 (PostgreSQL) is busy"
        echo ""
        echo -e "${YELLOW}Please free up these ports before continuing.${NC}"
        exit 1
    fi
fi

# Start containers directly
echo -e "\n${YELLOW}Starting containers with Docker...${NC}"
docker-compose -f .devcontainer/docker-compose.yml up -d --build

# Verify the containers are running
echo -e "\n${YELLOW}Verifying containers are running...${NC}"
RUNNING_CONTAINERS=$(docker ps --filter "label=com.demo.app=ai-ready-demo" --format "{{.Names}}" | wc -l | xargs)

if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo -e "${RED}❌ No containers are running. There might be an issue with Docker Compose.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Found $RUNNING_CONTAINERS container(s) running${NC}"
    docker ps --filter "label=com.demo.app=ai-ready-demo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi

# Update frontend configuration to fix routing issues
echo -e "\n${YELLOW}Updating frontend configuration...${NC}"
docker exec -i devcontainer-frontend-1 bash -c "cd /app && sed -i 's/host: .*/host: \"0.0.0.0\",/g' vite.config.js"
docker restart devcontainer-frontend-1
sleep 3
echo -e "${GREEN}✅ Frontend configuration updated${NC}"

# Start the backend service manually, redirecting output to log file
echo -e "\n${YELLOW}Starting the FastAPI backend service...${NC}"
docker exec -i devcontainer-backend-1 bash -c "cd /app && uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload" > "$LOG_FILE" 2>&1 &
sleep 2
echo -e "${GREEN}✅ Backend service started${NC}"

# Display a clear summary at the end
echo -e "\n${GREEN}🚀 Dev environment started!${NC}"
echo ""
echo -e "${BLUE}=== IMPORTANT INFORMATION ====${NC}"
echo -e "${YELLOW}You can access the application at:${NC}"
echo "→ Frontend: http://localhost:3001"
echo "→ API docs: http://localhost:8001/docs"
echo ""
echo -e "${YELLOW}Backend logs are being written to:${NC} $LOG_FILE"
echo -e "${YELLOW}To view logs in real-time:${NC} tail -f $LOG_FILE"
echo ""
echo -e "${YELLOW}To open VS Code in this directory:${NC}"
echo "→ Run: code ."
echo -e "${YELLOW}(Note: VS Code Dev Container integration is disabled - use browser access only)${NC}"

echo -e "\n${YELLOW}Happy coding!${NC} 🎉" 
#!/bin/bash

# Define color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create a log file for backend output
LOG_FILE="/tmp/app-backend-$(date +%s).log"
touch "$LOG_FILE"

echo -e "${BLUE}🚀 Dev Container Setup Script${NC}"
echo "=============================="

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
echo -e "${GREEN}✅ Created required directories${NC}"

# Check for port conflicts
echo -e "\n${YELLOW}Checking for port conflicts...${NC}"
PORT_8001_STATUS=$(lsof -i:8001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_3001_STATUS=$(lsof -i:3001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_5432_STATUS=$(lsof -i:5432 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)

# Check if ports are in use by non-app processes
if [ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ] || [ "$PORT_5432_STATUS" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Some ports needed by the application are already in use:${NC}"
    [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
    [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
    [ "$PORT_5432_STATUS" -eq 0 ] && echo "- Port 5432 (PostgreSQL) is busy"
    echo ""
    echo -e "${YELLOW}Please free up these ports before continuing.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No port conflicts detected${NC}"
fi

# Check for existing containers
echo -e "\n${YELLOW}Checking for existing containers...${NC}"
EXISTING_CONTAINERS=$(docker ps -a --filter "label=com.app=dev-container" --format "{{.Names}}" | wc -l | xargs)

if [ "$EXISTING_CONTAINERS" -gt 0 ]; then
    echo -e "${YELLOW}Found $EXISTING_CONTAINERS existing container(s):${NC}"
    docker ps -a --filter "label=com.app=dev-container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${YELLOW}Automatically stopping and removing existing containers for a clean start...${NC}"
    docker compose -f .devcontainer/docker-compose.yml down -v
    echo -e "${GREEN}✅ Removed existing containers and volumes${NC}"
else
    echo -e "${GREEN}✅ No existing containers found${NC}"
fi

# Start the containers
echo -e "\n${YELLOW}Starting containers with Docker...${NC}"
docker compose -f .devcontainer/docker-compose.yml up -d --build

# Verify the containers are running
echo -e "\n${YELLOW}Verifying containers are running...${NC}"
sleep 5  # Give time for all containers to start properly
RUNNING_CONTAINERS=$(docker ps --filter "label=com.app=dev-container" --format "{{.Names}}" | wc -l | xargs)

if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo -e "${RED}❌ No containers are running. There might be an issue with Docker Compose.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Found $RUNNING_CONTAINERS container(s) running${NC}"
    docker ps --filter "label=com.app=dev-container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi

# Start the backend service manually in the container
echo -e "\n${YELLOW}Starting the FastAPI backend service...${NC}"
BACKEND_CONTAINER=$(docker ps --filter "label=com.component=backend" --format "{{.Names}}" | head -n 1)

if [ -n "$BACKEND_CONTAINER" ]; then
    docker exec -d $BACKEND_CONTAINER bash -c "cd /app && uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload > /app/backend.log 2>&1 &"
    sleep 2
    echo -e "${GREEN}✅ Backend service started${NC}"
else
    echo -e "${RED}❌ Backend container not found.${NC}"
    echo -e "${YELLOW}Please check Docker logs for more information.${NC}"
fi

# Verify backend API is working properly
echo -e "\n${YELLOW}Verifying backend API is working...${NC}"
BACKEND_API_WORKING=false
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo -e "Attempt $RETRY_COUNT of $MAX_RETRIES..."
    
    # Try to call the health endpoint
    HEALTH_RESULT=$(curl -s -m 2 http://localhost:8001/health 2>/dev/null)
    if [[ "$HEALTH_RESULT" == *"healthy"* ]]; then
        BACKEND_API_WORKING=true
        break
    fi
    
    echo -e "${YELLOW}Backend not ready yet, waiting...${NC}"
    sleep 3
done

# Display a clear summary at the end
echo -e "\n${GREEN}🚀 Dev environment started!${NC}"
echo ""
echo -e "${BLUE}=== IMPORTANT INFORMATION ====${NC}"
echo -e "${YELLOW}Component Status:${NC}"

# Frontend status
if curl -s --head --connect-timeout 2 http://localhost:3001 >/dev/null; then
    echo -e "→ ${GREEN}✅ Frontend:${NC} http://localhost:3001"
else
    echo -e "→ ${RED}❌ Frontend:${NC} http://localhost:3001 (not responding)"
fi

# API docs status
if curl -s --head --connect-timeout 2 http://localhost:8001/docs >/dev/null; then
    echo -e "→ ${GREEN}✅ API Docs:${NC} http://localhost:8001/docs"
else
    echo -e "→ ${RED}❌ API Docs:${NC} http://localhost:8001/docs (not responding)"
fi

# Backend API status
if [ "$BACKEND_API_WORKING" = true ]; then
    echo -e "→ ${GREEN}✅ Backend API:${NC} http://localhost:8001/health"
else
    echo -e "→ ${RED}❌ Backend API:${NC} http://localhost:8001/health (not responding)"
    echo -e "\n${RED}The backend API is not responding. Check the logs for errors:${NC}"
    echo -e "docker logs $BACKEND_CONTAINER"
fi

# Database status
if [ -n "$(docker ps --filter "label=com.component=database" --format "{{.Names}}")" ]; then
    echo -e "→ ${GREEN}✅ Database:${NC} PostgreSQL on port 5432"
else
    echo -e "→ ${RED}❌ Database:${NC} PostgreSQL container is not running"
fi

echo ""
echo -e "${YELLOW}Backend logs are being written to:${NC} $LOG_FILE"
echo -e "${YELLOW}To view logs in real-time:${NC} tail -f $LOG_FILE"
echo ""
echo -e "\n${YELLOW}Happy coding!${NC} 🎉"

# Notes for customization (remove these in your actual script):
# 1. Add any project-specific directory creation steps
# 2. Add environment file creation if needed
# 3. Add any project-specific initialization steps
# 4. Consider adding a check for minimum Docker resource requirements
#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Enable error handling
set -e

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

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    echo -e "${RED}❌ VS Code is not installed or not in PATH.${NC}"
    echo "Please install VS Code from https://code.visualstudio.com/"
    exit 1
else
    echo -e "${GREEN}✅ VS Code is installed${NC}"
fi

# Check if Dev Containers extension is installed
if ! code --list-extensions | grep -q "ms-vscode-remote.remote-containers"; then
    echo -e "${YELLOW}⚠️ Dev Containers extension not found.${NC}"
    echo "Installing Dev Containers extension..."
    code --install-extension ms-vscode-remote.remote-containers
    echo -e "${GREEN}✅ Dev Containers extension installed${NC}"
else
    echo -e "${GREEN}✅ Dev Containers extension is installed${NC}"
fi

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

# Check if ports are already in use
echo -e "\n${YELLOW}Checking for port conflicts...${NC}"
PORT_8001_STATUS=$(lsof -i:8001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_3001_STATUS=$(lsof -i:3001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_5434_STATUS=$(lsof -i:5434 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)

if [ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ] || [ "$PORT_5434_STATUS" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Some ports needed by the application are already in use:${NC}"
    [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
    [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
    [ "$PORT_5434_STATUS" -eq 0 ] && echo "- Port 5434 (PostgreSQL) is busy"
    echo ""
    echo "Please free up these ports before continuing."
    read -p "Continue anyway? (y/n): " continue_anyway
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        echo "Exiting script."
        exit 1
    fi
fi

# Stop any existing containers
echo -e "\n${YELLOW}Stopping any existing containers...${NC}"
docker-compose -f .devcontainer/docker-compose.yml down -v
echo -e "${GREEN}✅ Removed any existing containers and volumes${NC}"

# Present options to the user
echo -e "\n${BLUE}Choose how you want to run the demo:${NC}"
echo ""
echo -e "1. ${GREEN}Direct Docker start${NC} (Recommended, more reliable)"
echo "   → Starts containers directly using docker-compose"
echo "   → Access the app in your browser immediately"
echo ""
echo -e "2. ${GREEN}VS Code Dev Container${NC} (Better for development)"
echo "   → Opens VS Code and lets it handle container creation"
echo "   → Provides full development environment in VS Code"
echo ""
read -p "Enter your choice (1 or 2): " user_choice

case $user_choice in
  1)
    # OPTION 1: Direct Docker start
    echo -e "\n${YELLOW}Starting containers directly with Docker...${NC}"
    docker-compose -f .devcontainer/docker-compose.yml up -d --build
    
    # Verify the containers are running
    echo -e "\n${YELLOW}Verifying containers are running...${NC}"
    RUNNING_CONTAINERS=$(docker ps --filter "name=devcontainer" --format "{{.Names}}" | wc -l | xargs)
    
    if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
        echo -e "${RED}❌ No containers are running. There might be an issue with Docker Compose.${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Found $RUNNING_CONTAINERS container(s) running${NC}"
        docker ps
    fi
    
    # Start the backend service manually
    echo -e "\n${YELLOW}Starting the FastAPI backend service...${NC}"
    docker exec -i devcontainer-backend-1 bash -c "cd /app && uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload" &
    sleep 2
    echo -e "${GREEN}✅ Backend service started${NC}"
    
    echo -e "\n${GREEN}🚀 Dev environment started!${NC}"
    echo ""
    echo -e "${YELLOW}You can access the application at:${NC}"
    echo "→ Frontend: http://localhost:3001"
    echo "→ API docs: http://localhost:8001/docs"
    echo ""
    echo -e "${YELLOW}To open VS Code in this directory (without containers):${NC}"
    echo "→ Run: code ."
    ;;
    
  2)
    # OPTION 2: VS Code Dev Container
    echo -e "\n${YELLOW}Opening VS Code with Dev Containers...${NC}"
    echo -e "${YELLOW}VS Code will handle creating and starting the containers.${NC}"
    echo ""
    echo -e "${YELLOW}When VS Code opens:${NC}"
    echo "1. You'll see a notification to 'Reopen in Container'"
    echo "2. Click this notification to start the container build process"
    echo "3. Wait for the containers to build and start (may take a few minutes)"
    echo ""
    echo -e "${YELLOW}If you encounter issues with VS Code Dev Containers:${NC}"
    echo "→ Try option 1 instead (Direct Docker start)"
    echo "→ Or run: code --force-disable-user-env-probe"
    
    # Open VS Code
    code .
    ;;
    
  *)
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
    ;;
esac

echo -e "\n${YELLOW}Happy coding!${NC} 🎉" 
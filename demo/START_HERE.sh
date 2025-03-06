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
docker version
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
echo -e "${GREEN}✅ Removed any existing containers${NC}"

# Clean old Docker volumes
echo -e "\n${YELLOW}Cleaning up old Docker volumes...${NC}"
docker volume prune -f
echo -e "${GREEN}✅ Removed any unused volumes${NC}"

# Check Docker Compose version
echo -e "\n${YELLOW}Docker Compose version:${NC}"
docker-compose version
echo ""

# Start containers directly with full output
echo -e "\n${YELLOW}Starting the containers directly...${NC}"
docker-compose -f .devcontainer/docker-compose.yml up -d --build

# Verify the containers are running
echo -e "\n${YELLOW}Verifying containers are running...${NC}"
RUNNING_CONTAINERS=$(docker ps --filter "name=devcontainer" --format "{{.Names}}" | wc -l | xargs)

if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo -e "${RED}❌ No containers are running. There might be an issue with Docker Compose.${NC}"
    echo -e "Let's try again with more detailed output:"
    echo ""
    docker-compose -f .devcontainer/docker-compose.yml up -d --build --verbose
    
    # Check again
    RUNNING_CONTAINERS=$(docker ps --filter "name=devcontainer" --format "{{.Names}}" | wc -l | xargs)
    if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
        echo -e "${RED}❌ Failed to start containers. Please check the error messages above.${NC}"
        # Show the logs to help diagnose the issue
        echo -e "\n${YELLOW}Showing Docker Compose logs to help diagnose the issue:${NC}"
        docker-compose -f .devcontainer/docker-compose.yml logs
        exit 1
    fi
else
    echo -e "${GREEN}✅ Found $RUNNING_CONTAINERS container(s) running${NC}"
    docker ps
fi

echo -e "\n${GREEN}🚀 Dev environment started!${NC}"

# Show instructions for both methods
echo -e "\n${BLUE}There are two ways to proceed:${NC}"
echo ""
echo -e "1. ${GREEN}Access directly in your browser:${NC}"
echo "   → Frontend: http://localhost:3001"
echo "   → API docs: http://localhost:8001/docs"
echo ""
echo -e "2. ${GREEN}Or open VS Code with dev container:${NC}"
echo "   → Press Enter to open VS Code"
echo "   → When prompted, click 'Reopen in Container'"
echo ""
echo -e "${YELLOW}This dual approach ensures you can work even if the VS Code extension has issues.${NC}"

read -p "Press Enter to open VS Code (or Ctrl+C to skip)..."
code .

echo -e "\n${YELLOW}Happy coding!${NC} 🎉" 
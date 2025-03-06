#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
    echo "Please free up these ports before continuing."
    read -p "Continue anyway? (y/n): " continue_anyway
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        echo "Exiting script."
        exit 1
    fi
fi

# Stop any existing containers
echo -e "\n${YELLOW}Stopping any existing containers...${NC}"
docker-compose -f .devcontainer/docker-compose.yml down -v &> /dev/null

# Clean old Docker volumes
echo -e "\n${YELLOW}Cleaning up old Docker volumes...${NC}"
docker volume prune -f &> /dev/null

# Start containers directly
echo -e "\n${YELLOW}Starting the containers directly...${NC}"
docker-compose -f .devcontainer/docker-compose.yml up -d --build

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
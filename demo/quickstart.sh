#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Dev Container Demo - Quick Start${NC}"
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

# Stop any existing containers
echo -e "\n${YELLOW}Stopping any existing containers...${NC}"
docker-compose -f .devcontainer/docker-compose.yml down -v &> /dev/null

# Open VS Code
echo -e "\n${GREEN}🚀 Opening VS Code...${NC}"
echo -e "${YELLOW}When VS Code opens, click 'Reopen in Container' when prompted.${NC}"
echo -e "${YELLOW}This will build and start the development environment.${NC}"
echo ""
echo -e "${BLUE}After the container builds (this may take a few minutes the first time):${NC}"
echo "1. The application will be running automatically"
echo "2. Access the frontend at: http://localhost:3001"
echo "3. Access the API docs at: http://localhost:8001/docs"
echo ""
echo -e "${YELLOW}Happy coding!${NC} 🎉"

# Open VS Code in the current directory
code . 
#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Testing Dev Container Configuration${NC}"
echo "======================================="

# Check if Docker is running
echo -e "\n${YELLOW}Checking if Docker is running...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop first.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker is running${NC}"
fi

# Backup existing configuration if it exists
echo -e "\n${YELLOW}Backing up existing configuration...${NC}"
if [ -f ".devcontainer/devcontainer.json" ]; then
    mv .devcontainer/devcontainer.json .devcontainer/devcontainer.json.backup
    echo -e "${GREEN}✅ Existing configuration backed up${NC}"
fi

# Copy the simple configuration
echo -e "\n${YELLOW}Setting up simple configuration...${NC}"
cp .devcontainer/simple-devcontainer.json .devcontainer/devcontainer.json
echo -e "${GREEN}✅ Simple configuration set up${NC}"

# Test the container directly with Docker
echo -e "\n${YELLOW}Testing container with Docker...${NC}"
echo "This will pull the Python image and run a simple test..."

# Run a simple test container
TEST_RESULT=$(docker run --rm python:3.12-slim python -c "print('Container test successful!')" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker container test successful${NC}"
    echo "$TEST_RESULT"
else
    echo -e "${RED}❌ Docker container test failed${NC}"
    echo "$TEST_RESULT"
fi

# Test the Dev Container CLI if available
echo -e "\n${YELLOW}Testing with Dev Container CLI...${NC}"
if command -v devcontainer &> /dev/null; then
    echo "Running Dev Container CLI test..."
    devcontainer build --workspace-folder . --log-level debug
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Dev Container CLI test successful${NC}"
    else
        echo -e "${RED}❌ Dev Container CLI test failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Dev Container CLI not found, skipping this test${NC}"
    echo "You can install it with: npm install -g @devcontainers/cli"
fi

echo -e "\n${YELLOW}Test Results Summary:${NC}"
echo "1. The simplified configuration has been set up"
echo "2. Basic Docker functionality is working"
echo "3. You can now try opening VS Code with: code ."
echo ""
echo "If VS Code still fails to open the container, try these steps:"
echo "1. Clear VS Code's Dev Container cache:"
echo "   rm -rf ~/.vscode/extensions/ms-vscode-remote.remote-containers-*/data"
echo "2. Restart VS Code and Docker Desktop"
echo "3. Try with a completely new project folder"
echo ""
echo -e "${YELLOW}Would you like to restore the original configuration? (y/n)${NC}"
read -p "> " restore_config

if [[ "$restore_config" =~ ^[Yy]$ ]]; then
    if [ -f ".devcontainer/devcontainer.json.backup" ]; then
        mv .devcontainer/devcontainer.json.backup .devcontainer/devcontainer.json
        echo -e "${GREEN}✅ Original configuration restored${NC}"
    else
        echo -e "${RED}❌ No backup found to restore${NC}"
    fi
else
    echo -e "${GREEN}✅ Keeping the simple configuration${NC}"
fi

echo -e "\n${GREEN}Testing completed!${NC}" 
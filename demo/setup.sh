#!/bin/bash

# setup.sh - Initial setup script for AI-Ready Dev Containers demo
# This script creates necessary directories and checks prerequisites

echo "🚀 AI-Ready Dev Containers Demo Setup"
echo "======================================"

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker before continuing."
    echo "   Download from: https://www.docker.com/products/docker-desktop/"
    exit 1
else
    echo "✅ Docker is installed"
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo "❌ Docker is not running. Please start Docker Desktop first."
        exit 1
    else
        echo "✅ Docker is running"
    fi
fi

# Check for VS Code
if ! command -v code &> /dev/null; then
    echo "⚠️ VS Code command line tool not found."
    echo "   This is not critical, but you'll need VS Code to open in the dev container."
    echo "   Download from: https://code.visualstudio.com/"
else
    echo "✅ VS Code is installed"
    
    # Check for Dev Containers extension
    if code --list-extensions | grep -q "ms-vscode-remote.remote-containers"; then
        echo "✅ Dev Containers extension is installed"
    else
        echo "⚠️ Dev Containers extension not found."
        echo "   You can install it with: code --install-extension ms-vscode-remote.remote-containers"
        echo "   Or install it from the VS Code marketplace."
    fi
fi

# Create necessary directories
echo -e "\nCreating required directories..."

# Postgres data directory
mkdir -p .docker/postgres-data
echo "✅ Created .docker/postgres-data directory"

# Init scripts directory (should already exist but just in case)
mkdir -p .docker/init-scripts
echo "✅ Checked .docker/init-scripts directory"

# Check/create the init script if it doesn't exist
if [ ! -f .docker/init-scripts/setup.sql ]; then
    echo "⚠️ setup.sql not found, creating it..."
    echo "-- Basic initialization for PostgreSQL" > .docker/init-scripts/setup.sql
    echo "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >> .docker/init-scripts/setup.sql
    echo "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" >> .docker/init-scripts/setup.sql
fi

echo -e "\n✅ Setup completed successfully!"
echo -e "You can now open VS Code in this directory and start the dev container:\n"
echo "   code ."
echo "   Then click 'Reopen in Container' when prompted"
echo -e "\nOr run manually with:"
echo "   docker-compose -f .devcontainer/docker-compose.yml up --build"
echo -e "\nHappy coding! 🎉"
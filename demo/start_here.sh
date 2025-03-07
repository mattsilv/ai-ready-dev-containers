#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
mkdir -p .docker

# Check if index.html exists in public directory, create it if it doesn't
if [ ! -f frontend/public/index.html ]; then
    echo -e "${YELLOW}Creating index.html in frontend/public directory...${NC}"
    mkdir -p frontend/public
    cat > frontend/public/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DevContainer Demo App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOL
    echo -e "${GREEN}✅ Created index.html${NC}"
    
    # Create vite.svg favicon
    cat > frontend/public/vite.svg << 'EOL'
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none">
  <rect width="32" height="32" rx="4" fill="#646CFF"/>
  <path d="M16 8L24 16L16 24L8 16L16 8Z" fill="white"/>
</svg>
EOL
    echo -e "${GREEN}✅ Created vite.svg favicon${NC}"
fi

# Check if ports are already in use by non-demo containers
echo -e "\n${YELLOW}Checking for port conflicts...${NC}"
PORT_8001_STATUS=$(lsof -i:8001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)
PORT_3001_STATUS=$(lsof -i:3001 -sTCP:LISTEN -t >/dev/null 2>&1; echo $?)

# Check for existing containers created by this script
echo -e "\n${YELLOW}Checking for existing demo containers...${NC}"
EXISTING_CONTAINERS=$(docker ps -a --filter "label=com.demo.app=ai-ready-demo" --format "{{.Names}}" | wc -l | xargs)

if [ "$EXISTING_CONTAINERS" -gt 0 ]; then
    echo -e "${YELLOW}Found $EXISTING_CONTAINERS existing demo container(s):${NC}"
    docker ps -a --filter "label=com.demo.app=ai-ready-demo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Check if our demo containers are using the ports
    DEMO_USING_PORTS=true
    
    # If ports are in use but not by our containers, we have a conflict
    if ([ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ]) && [ "$DEMO_USING_PORTS" = false ]; then
        echo -e "\n${YELLOW}Warning: Some ports needed by the application are in use by non-demo processes:${NC}"
        [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
        [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
        echo ""
        echo -e "${YELLOW}Please free up these ports before continuing.${NC}"
        exit 1
    fi
    
    echo -e "\n${YELLOW}Automatically stopping and removing existing containers for a clean start...${NC}"
    docker compose -f .devcontainer/docker-compose.yml down -v
    echo -e "${GREEN}✅ Removed existing containers and volumes${NC}"
else
    echo -e "${GREEN}✅ No existing demo containers found${NC}"
    
    # Only check for port conflicts if no demo containers exist
    if [ "$PORT_8001_STATUS" -eq 0 ] || [ "$PORT_3001_STATUS" -eq 0 ]; then
        echo -e "${YELLOW}Warning: Some ports needed by the application are already in use:${NC}"
        [ "$PORT_8001_STATUS" -eq 0 ] && echo "- Port 8001 (Backend API) is busy"
        [ "$PORT_3001_STATUS" -eq 0 ] && echo "- Port 3001 (Frontend) is busy"
        echo ""
        echo -e "${YELLOW}Please free up these ports before continuing.${NC}"
        exit 1
    fi
fi

# Update frontend API URLs to use the correct port
echo -e "\n${YELLOW}Updating frontend API URLs...${NC}"
sed -i '' 's/http:\/\/localhost:8000/http:\/\/localhost:8001/g' frontend/src/App.jsx
echo -e "${GREEN}✅ Updated frontend API URLs${NC}"

# Start containers directly
echo -e "\n${YELLOW}Starting containers with Docker...${NC}"
docker compose -f .devcontainer/docker-compose.yml up -d --build

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

# Start the backend service manually, redirecting output to log file
echo -e "\n${YELLOW}Starting the FastAPI backend service...${NC}"

# First, kill any existing uvicorn processes to avoid conflicts
docker exec -i devcontainer-backend-1 bash -c "pkill -f uvicorn || true"
sleep 1

# Start the backend service
docker exec -i devcontainer-backend-1 bash -c "cd /app && mkdir -p /app/data && chmod 777 /app/data && uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload" > "$LOG_FILE" 2>&1 &
sleep 2
echo -e "${GREEN}✅ Backend service started${NC}"

# Display a clear summary at the end
echo -e "\n${GREEN}🚀 Dev environment started!${NC}"
echo ""
# echo -e "${BLUE}=== IMPORTANT INFORMATION ====${NC}"
# echo -e "${YELLOW}You can access the application at:${NC}"
# echo "→ Frontend: http://localhost:3001"
# echo "→ API docs: http://localhost:8001/docs"
# echo ""
# echo -e "${YELLOW}Backend logs are being written to:${NC} $LOG_FILE"
# echo -e "${YELLOW}To view logs in real-time:${NC} tail -f $LOG_FILE"
# echo ""
# echo -e "\n${YELLOW}Happy coding!${NC} 🎉"
# 
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

# Updated display section for component status
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
    echo -e "docker logs devcontainer-backend-1"
fi

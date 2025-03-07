#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🚀 Starting DevContainer Demo Setup"
echo "===================================="

# Check if we're in the dev container
if [ ! -d "/app" ]; then
    echo "❌ This script should be run inside the dev container"
    exit 1
fi

echo -e "${GREEN}✅ Running inside dev container${NC}"

# Debug information
echo -e "\n${YELLOW}📋 System Information:${NC}"
echo "- Hostname: $(hostname)"
echo "- User: $(whoami)"
echo "- Current directory: $(pwd)"
echo "- Network interfaces:"
ip addr | grep -E 'inet ' | awk '{print "  - " $2 " on " $NF}'

# Check required files
echo -e "\n${YELLOW}📋 Checking required files:${NC}"
[ -f "/app/src/main.py" ] && echo "- main.py: Found" || echo -e "${RED}- main.py: Not found${NC}"
[ -f "/app/src/database.py" ] && echo "- database.py: Found" || echo -e "${RED}- database.py: Not found${NC}"
[ -f "/app/src/models.py" ] && echo "- models.py: Found" || echo -e "${RED}- models.py: Not found${NC}"
[ -f "/app/src/schemas.py" ] && echo "- schemas.py: Found" || echo -e "${RED}- schemas.py: Not found${NC}"

# Check database connection
echo -e "\n${YELLOW}📋 Checking database connection:${NC}"
DATABASE_URL=${DATABASE_URL:-"postgresql://user:password@db:5432/demo_db"}
echo "- Database URL: $DATABASE_URL"

# Extract database host and port
DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\).*/\1/p')
echo "- Database host: $DB_HOST"

# Check if we can ping the database host
ping -c 1 $DB_HOST > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}- Database host reachable${NC}"
else
    echo -e "${RED}- Database host unreachable${NC}"
fi

# Test the backend API directly
echo -e "\n${YELLOW}📋 Testing backend API directly:${NC}"
# Check if uvicorn is already running
ps aux | grep -v grep | grep "uvicorn" > /dev/null
if [ $? -eq 0 ]; then
    echo "- Uvicorn process is already running"
    echo "- Stopping existing uvicorn process..."
    ps aux | grep uvicorn | grep -v grep | awk '{print $2}' | xargs -r kill -9
    sleep 2
fi

# Start uvicorn with logging to check for errors
echo "- Starting uvicorn for testing..."
cd /app
UVICORN_LOG=$(uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload 2>&1 &)
UVICORN_PID=$!
sleep 5

# Kill the background process
kill $UVICORN_PID 2>/dev/null

# Check if the health endpoint is reachable
echo -e "\n${YELLOW}📋 Testing backend API endpoints:${NC}"
curl -s http://localhost:8000/health && echo -e "\n${GREEN}- Health endpoint is reachable${NC}" || echo -e "${RED}- Health endpoint is not reachable${NC}"
curl -s http://localhost:8001/health && echo -e "\n${GREEN}- Health endpoint is reachable on mapped port 8001${NC}" || echo -e "${RED}- Health endpoint is not reachable on mapped port 8001${NC}"

# Try using wget if curl doesn't work
if ! command -v curl &> /dev/null; then
    echo "- Curl not found, using wget"
    wget -q -O - http://localhost:8000/health && echo -e "\n${GREEN}- Health endpoint is reachable with wget${NC}" || echo -e "${RED}- Health endpoint is not reachable with wget${NC}"
fi

# Check network connectivity
echo -e "\n${YELLOW}📋 Network connectivity:${NC}"
echo "- Connection to Frontend container:"
ping -c 1 frontend > /dev/null 2>&1 && echo -e "${GREEN}  Frontend container reachable${NC}" || echo -e "${RED}  Frontend container unreachable${NC}"

echo "- Connection to Database container:"
ping -c 1 db > /dev/null 2>&1 && echo -e "${GREEN}  Database container reachable${NC}" || echo -e "${RED}  Database container unreachable${NC}"

# Check if ports are in use
echo -e "\n${YELLOW}📋 Port usage:${NC}"
netstat -tulpn 2>/dev/null | grep 8000 && echo "- Port 8000 is in use" || echo "- Port 8000 is free"
netstat -tulpn 2>/dev/null | grep 8001 && echo "- Port 8001 is in use" || echo "- Port 8001 is free"

# Function to check if a service is running (with more detailed debugging)
check_service() {
    local service=$1
    local url=$2
    local max_attempts=$3
    local attempt=1
    
    echo -e "\n${YELLOW}🔄 Checking $service at $url...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        echo "- Attempt $attempt/$max_attempts"
        
        # Detailed curl output
        echo "- Curl output:"
        CURL_RESULT=$(curl -v $url 2>&1)
        echo "$CURL_RESULT"
        
        if echo "$CURL_RESULT" | grep -q "200 OK"; then
            echo -e "${GREEN}✅ $service is running!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts: $service not ready yet, waiting...${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service failed to start after $max_attempts attempts${NC}"
    return 1
}

echo -e "\n${YELLOW}📋 Starting debug information collection${NC}"

# Print versions
echo "Python version:"
python --version

echo "Pip packages:"
pip list

echo "FastAPI app structure:"
find /app -type f -name "*.py" | sort

echo -e "\n${YELLOW}📋 Starting services for testing${NC}"

# Re-start uvicorn properly
echo "- Starting backend API in background..."
cd /app
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload &
UVICORN_PID=$!
sleep 5

# Check backend API with more details
check_service "Backend API" "http://localhost:8000/health" 5

# Output a clear message if the backend API is not running
if [ $? -ne 0 ]; then
    echo -e "\n${RED}❌ Backend API is not running${NC}"
    echo -e "${YELLOW}Troubleshooting suggestions:${NC}"
    echo "1. Check if FastAPI and dependencies are installed correctly"
    echo "2. Verify the database connection string is correct"
    echo "3. Check for syntax errors in the Python code"
    echo "4. Verify all database migrations have been applied"
    echo "5. Check the container logs for more details with:"
    echo "   docker logs devcontainer-backend-1"
    echo ""
    echo "You can manually start the API with:"
    echo "cd /app && uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload"
    exit 1
fi

# Clean up the background process
kill $UVICORN_PID 2>/dev/null

echo -e "\n${GREEN}🎉 DevContainer Demo is ready! 🎉${NC}"
echo "=================================="
echo ""
echo -e "${YELLOW}You can access the application at:${NC}"
echo "- Frontend: http://localhost:3001"
echo "- Backend API: http://localhost:8001"
echo "- API Documentation: http://localhost:8001/docs"
echo ""
echo -e "${YELLOW}Sample API endpoints:${NC}"
echo "- GET /items: http://localhost:8001/items"
echo "- GET /health: http://localhost:8001/health"
echo ""
echo -e "${YELLOW}To run this app from the terminal, use the following command:${NC}"
echo "bash /app/backend/setup.sh"
echo ""
echo "Have fun coding! 🚀" 
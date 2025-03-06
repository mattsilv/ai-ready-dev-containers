#!/bin/bash

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Dev Container Services Utility${NC}"
echo "====================================="

# Function to check service health
check_service() {
    local service=$1
    local url=$2
    local max_attempts=$3
    local attempt=1
    
    echo "🔍 Checking $service at $url..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null; then
            echo -e "${GREEN}✅ $service is running!${NC}"
            return 0
        fi
        
        echo "⏳ Attempt $attempt/$max_attempts: $service not ready yet, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service is not responding${NC}"
    return 1
}

# Display menu
echo "What would you like to do?"
echo ""
echo "1) Check services status"
echo "2) Restart backend service"
echo "3) View logs for all services"
echo "4) Show URLs and connection info"
echo "5) Exit"
echo ""

read -p "Enter your choice [1-5]: " option

case $option in
    1)
        echo -e "\n${YELLOW}Checking services status...${NC}"
        
        # Check backend API
        check_service "Backend API" "http://localhost:8001/health" 3
        
        # Check frontend
        check_service "Frontend" "http://localhost:3001" 3
        
        # Check database connection through API
        echo "🔍 Checking Database connection..."
        if curl -s "http://localhost:8001/items" | grep -q "name"; then
            echo -e "${GREEN}✅ Database connection successful!${NC}"
        else
            echo -e "${RED}❌ Database connection failed${NC}"
        fi
        ;;
        
    2)
        echo -e "\n${YELLOW}Restarting backend service...${NC}"
        # We're running inside the container, but we'll send a command to the host
        # to restart the container
        echo "This will restart the FastAPI service inside this container"
        read -p "Continue? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "Restarting service..."
            # Just restart the uvicorn process
            ps aux | grep "uvicorn" | grep -v grep | awk '{print $2}' | xargs -r kill -9
            cd /app && uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload &
            echo -e "${GREEN}✅ Backend service restarted${NC}"
        fi
        ;;
        
    3)
        echo -e "\n${YELLOW}Viewing logs...${NC}"
        echo "Press Ctrl+C to exit logs view"
        echo ""
        # Using docker logs from inside the container won't work
        # but we can check the uvicorn logs
        tail -f /app/*.log 2>/dev/null || echo "No log files found"
        ;;
        
    4)
        echo -e "\n${YELLOW}Service URLs and Connection Information:${NC}"
        echo ""
        echo "🌐 Frontend URL: http://localhost:3001"
        echo "🌐 Backend API: http://localhost:8001"
        echo "🌐 API Documentation: http://localhost:8001/docs"
        echo "🗄️ Database Connection:"
        echo "   - Host: db"
        echo "   - Port: 5432"
        echo "   - Username: user"
        echo "   - Password: password"
        echo "   - Database: demo_db"
        echo "   - Connection string: postgresql://user:password@db:5432/demo_db"
        echo ""
        echo "External connection (from your host machine):"
        echo "   - Connection string: postgresql://user:password@localhost:5434/demo_db"
        ;;
        
    5)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Done!${NC}" 
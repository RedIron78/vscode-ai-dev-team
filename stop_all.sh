#!/bin/bash

# VS Code AI Dev Team - Service Stopper
# This script stops all services started by start_all.sh

# Ensure we're in the correct directory regardless of how the script is called
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track if we had any errors
HAD_ERROR=0
error_handler() {
    HAD_ERROR=1
    echo -e "${RED}❌ Error occurred: $1${NC}"
}

# Display banner
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  VS Code AI Dev Team - Stopping All Services         ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Function to check if a port is in use
port_in_use() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -i :"$port" >/dev/null 2>&1
        return $?
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port "
        return $?
    else
        # Default to assuming port is free if we can't check
        return 1
    fi
}

# Function to parse YAML key
parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    local fs=$(echo @|tr @ '\034')
    
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $yaml_file |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

# Parse config.yml
echo -e "${YELLOW}Parsing configuration from config.yml...${NC}"
if [ -f "config.yml" ]; then
    eval $(parse_yaml config.yml "config_")
    BACKEND_PORT="${config_backend_port}"
    LLM_PORT="${config_llm_port}"
    echo -e "${GREEN}Configuration loaded:${NC}"
    echo -e "  Backend Port: ${BACKEND_PORT}"
    echo -e "  LLM Port: ${LLM_PORT}"
else
    echo -e "${YELLOW}config.yml not found, using default ports${NC}"
    BACKEND_PORT=5000
    LLM_PORT=8081
fi

# Load port information from the central location
PORT_INFO_DIR="/tmp/ai-dev-team"
PORT_INFO_FILE="$PORT_INFO_DIR/ports.json"
if [ -f "$PORT_INFO_FILE" ]; then
    echo -e "${YELLOW}Loading port information from $PORT_INFO_FILE${NC}"
    # Set environment variables for docker-compose
    export WEAVIATE_PORT=$(grep -o '"weaviate_port":[^,]*' "$PORT_INFO_FILE" | cut -d':' -f2 | tr -d ' ')
    export WEAVIATE_GRPC_PORT=$(grep -o '"weaviate_grpc_port":[^,}]*' "$PORT_INFO_FILE" | cut -d':' -f2 | tr -d ' ')
    echo -e "${GREEN}Using Weaviate port: $WEAVIATE_PORT${NC}"
fi

# Stop the VS Code agent
if port_in_use $BACKEND_PORT; then
    echo -e "${YELLOW}Stopping VS Code agent on port $BACKEND_PORT...${NC}"
    if pgrep -f "vscode_integration.py" > /dev/null; then
        pkill -f "vscode_integration.py"
        echo -e "${GREEN}✅ VS Code agent stopped.${NC}"
    else
        echo -e "${YELLOW}⚠️ Could not find VS Code agent process.${NC}"
        echo -e "   You may need to manually kill the process."
        error_handler "Could not find VS Code agent process"
    fi
else
    echo -e "${GREEN}✅ VS Code agent is not running.${NC}"
fi

# Stop the LLM server
if port_in_use $LLM_PORT; then
    echo -e "${YELLOW}Stopping LLM server on port $LLM_PORT...${NC}"
    if pgrep -f "llama-server" > /dev/null; then
        pkill -f "llama-server"
        echo -e "${GREEN}✅ LLM server stopped.${NC}"
    else
        echo -e "${YELLOW}⚠️ Could not find LLM server process.${NC}"
        echo -e "   You may need to manually kill the process."
        error_handler "Could not find LLM server process"
    fi
else
    echo -e "${GREEN}✅ LLM server is not running.${NC}"
fi

# Stop Weaviate
echo -e "${YELLOW}Stopping Weaviate...${NC}"
if command -v docker >/dev/null 2>&1 && docker ps >/dev/null 2>&1; then
    if docker ps | grep -q weaviate; then
        # Ensure docker-compose.yml exists
        if [ ! -f "docker-compose.yml" ]; then
            echo -e "${RED}❌ docker-compose.yml not found.${NC}"
            error_handler "docker-compose.yml not found"
        else
            # Using docker-compose down -v to completely remove volumes
            docker-compose down
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Weaviate stopped.${NC}"
            else
                echo -e "${RED}❌ Failed to stop Weaviate.${NC}"
                error_handler "Failed to stop Weaviate with docker-compose"
            fi
        fi
    else
        echo -e "${GREEN}✅ Weaviate is not running.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Docker not available. Cannot check or stop Weaviate.${NC}"
    error_handler "Docker not available"
fi

# Clean up named pipes and temporary files
PIPE_DIR="/tmp/ai-dev-team"
PIPE="$PIPE_DIR/llm_pipe"
if [ -p "$PIPE" ]; then
    rm "$PIPE"
fi

# Clean up port info file
if [ -f "$PORT_INFO_FILE" ]; then
    rm "$PORT_INFO_FILE"
fi

if [ -f "/tmp/vscode_ai_agent_port.txt" ]; then
    rm "/tmp/vscode_ai_agent_port.txt"
fi

echo -e "${GREEN}✅ Cleaned up named pipes and temporary files.${NC}"

# Final status
if [ $HAD_ERROR -eq 0 ]; then
    echo ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${BLUE}  All services have been stopped!                     ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo ""
    echo -e "To start services again, run: ${YELLOW}./start_all.sh${NC}"
    echo -e "${BLUE}======================================================${NC}"
else
    echo ""
    echo -e "${RED}======================================================${NC}"
    echo -e "${RED}  Some services may not have been stopped properly     ${NC}"
    echo -e "${RED}======================================================${NC}"
    echo ""
    echo -e "Please check the error messages above for details."
    echo -e "You might need to manually stop some services."
    echo -e ""
    echo -e "To start services again, run: ${YELLOW}./start_all.sh${NC}"
    echo -e "${RED}======================================================${NC}"
fi

# Keep the terminal open
echo -e "${YELLOW}Terminal will remain open. Use Ctrl+C to exit.${NC}"
# Wait for user input but handle it gracefully
read -r -d '' _ || true 
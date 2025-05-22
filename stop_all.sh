#!/bin/bash

# VS Code AI Dev Team - Service Stopper
# This script stops all services started by start_all.sh

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Stop the VS Code agent
if port_in_use $BACKEND_PORT; then
    echo -e "${YELLOW}Stopping VS Code agent on port $BACKEND_PORT...${NC}"
    if pgrep -f "vscode_integration.py" > /dev/null; then
        pkill -f "vscode_integration.py"
        echo -e "${GREEN}✅ VS Code agent stopped.${NC}"
    else
        echo -e "${YELLOW}⚠️ Could not find VS Code agent process.${NC}"
        echo -e "   You may need to manually kill the process."
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
    fi
else
    echo -e "${GREEN}✅ LLM server is not running.${NC}"
fi

# Stop Weaviate
echo -e "${YELLOW}Stopping Weaviate...${NC}"
if docker ps | grep -q weaviate; then
    docker-compose down
    echo -e "${GREEN}✅ Weaviate stopped.${NC}"
else
    echo -e "${GREEN}✅ Weaviate is not running.${NC}"
fi

# Clean up named pipes
PIPE_DIR="/tmp/ai-dev-team"
PIPE="$PIPE_DIR/llm_pipe"
if [ -p "$PIPE" ]; then
    rm "$PIPE"
    echo -e "${GREEN}✅ Cleaned up named pipes.${NC}"
fi

echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  All services have been stopped!                     ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""
echo -e "To start services again, run: ${YELLOW}./start_all.sh${NC}"
echo -e "${BLUE}======================================================${NC}" 
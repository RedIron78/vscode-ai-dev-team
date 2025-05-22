#!/bin/bash

# VS Code AI Dev Team - All-in-One Startup Script
# This script starts all required services for the VS Code AI Dev Team extension

# Ensure we're in the correct directory regardless of how the script is called
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Track if we had any errors
HAD_ERROR=0
error_handler() {
    HAD_ERROR=1
    echo -e "${RED}❌ Error occurred: $1${NC}"
}

# Check if required files exist
if [ ! -f "scripts/run_llama_server.sh" ] || [ ! -f "scripts/start_vscode_agent.sh" ]; then
    echo "Error: Required script files not found. Make sure you're in the project root directory."
    error_handler "Missing required script files"
fi

# Ensure scripts are executable
chmod +x scripts/run_llama_server.sh
chmod +x scripts/start_vscode_agent.sh

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a port is in use and find an available one
check_port_available() {
    local port=$1
    local service_name=$2
    local config_key=$3
    
    # Check if port is in use
    if port_in_use "$port"; then
        echo -e "${YELLOW}⚠️ Port $port for $service_name is already in use.${NC}"
        # Find an available port
        local new_port=$(find_available_port "$port")
        echo -e "${YELLOW}Using alternative port: $new_port${NC}"
        
        # Update the config file if a config key was provided
        if [ -n "$config_key" ]; then
            sed -i "s/^  $config_key: $port/  $config_key: $new_port/" config.yml
            echo -e "${YELLOW}Updated config.yml with new port${NC}"
        fi
        
        # Return the new port
        echo "$new_port"
    else
        # Port is available, return it
        echo "$port"
    fi
}

# Function to find an available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    
    while port_in_use "$port"; do
        port=$((port + 1))
        # Safety check to prevent infinite loop
        if [ "$port" -gt "$((start_port + 100))" ]; then
            echo -e "${RED}Cannot find available port within reasonable range.${NC}"
            return 1
        fi
    done
    
    echo "$port"
}

# Display banner
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  VS Code AI Dev Team - All-in-One Starter           ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Check if config.yml exists
if [ ! -f "config.yml" ]; then
    echo -e "${YELLOW}Warning: config.yml not found, creating with default settings...${NC}"
    cat > config.yml << EOF
# VS Code AI Dev Team Configuration

# LLM Server Configuration
llm:
  # Default model to use
  default_model: "models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
  # Server host
  host: "127.0.0.1"
  # Server port
  port: 8081
  # Number of CPU threads (0 = auto)
  threads: 0
  # Context size
  context_size: 4096
  # GPU layers (0 = CPU only)
  gpu_layers: 35
  # Temperature (higher = more creative, lower = more deterministic)
  temperature: 0.7
  # Additional model parameters
  extra_params: ""

# Python Backend Configuration
backend:
  # Host for the Flask backend
  host: "127.0.0.1"
  # Port for the Flask backend
  port: 5000
  # Debug mode (true/false)
  debug: false
  # Memory integration (true/false)
  use_memory: true

# Weaviate Configuration
weaviate:
  # Host
  host: "localhost"
  # Port
  port: 8090
  # Schema name
  schema_name: "VSCodeAssistant"
  # Class name
  class_name: "Memory"
EOF
    echo -e "${GREEN}Created default config.yml${NC}"
fi

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
eval $(parse_yaml config.yml "config_")

echo -e "${GREEN}Configuration loaded:${NC}"
echo -e "  LLM Model: ${config_llm_default_model}"
echo -e "  LLM Port: ${config_llm_port}"
echo -e "  Backend Port: ${config_backend_port}"
echo -e "  Use Memory: ${config_backend_use_memory}"

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

# Check and update ports if they are in use
LLM_PORT=$(check_port_available "${config_llm_port}" "LLM Server" "port")
export LLM_PORT
BACKEND_PORT=$(check_port_available "${config_backend_port}" "Backend Server" "port")
export BACKEND_PORT

# Verify Docker is running (only if memory is enabled)
if [ "${config_backend_use_memory}" = "true" ]; then
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not installed.${NC}"
        echo -e "Please install Docker first: https://docs.docker.com/get-docker/"
        echo -e "${YELLOW}You can disable memory in config.yml by setting use_memory: false${NC}"
        error_handler "Docker not installed"
    elif ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running.${NC}"
        echo -e "Please start Docker first."
        echo -e "${YELLOW}You can disable memory in config.yml by setting use_memory: false${NC}"
        error_handler "Docker not running"
    else
        echo -e "${GREEN}✅ Docker is running.${NC}"
    fi
fi

# Check if venv exists, create if not
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r backend/requirements.txt
else
    source venv/bin/activate
fi

# Start Weaviate if memory is enabled and not running
if [ "${config_backend_use_memory}" = "true" ]; then
    echo -e "${YELLOW}Checking Weaviate status...${NC}"
    
    # Check if weaviate port is in use by something other than weaviate
    WEAVIATE_PORT=$(check_port_available "${config_weaviate_port}" "Weaviate" "port")
    
    if ! docker ps | grep -q weaviate; then
        echo -e "${YELLOW}Starting Weaviate database...${NC}"
        
        # Check if we need to update the port in docker-compose.yml
        if [ "$WEAVIATE_PORT" != "${config_weaviate_port}" ]; then
            # Update docker-compose.yml with the new port
            sed -i "s/- \"${config_weaviate_port}:8080\"/- \"$WEAVIATE_PORT:8080\"/" docker-compose.yml
        fi
        
        docker-compose up -d
        
        # Wait for Weaviate to initialize
        echo -e "${YELLOW}Waiting for Weaviate to initialize (10 seconds)...${NC}"
        sleep 10
        
        if docker ps | grep -q weaviate; then
            echo -e "${GREEN}✅ Weaviate started successfully.${NC}"
        else
            echo -e "${RED}❌ Failed to start Weaviate.${NC}"
            error_handler "Failed to start Weaviate"
        fi
    else
        echo -e "${GREEN}✅ Weaviate is already running.${NC}"
    fi
else
    echo -e "${YELLOW}Memory integration is disabled in config.yml. Skipping Weaviate startup.${NC}"
fi

# Check if LLM server is already running
if port_in_use "${config_llm_port}"; then
    echo -e "${GREEN}✅ LLM server is already running on port ${config_llm_port}.${NC}"
else
    # Start LLM server in background
    echo -e "${YELLOW}Starting LLM server...${NC}"
    
    # Check if model exists
    if [ ! -f "${config_llm_default_model}" ]; then
        echo -e "${RED}❌ Model file not found: ${config_llm_default_model}${NC}"
        echo -e "${YELLOW}You can download models using:${NC} ./scripts/download_model.sh"
        error_handler "Model file not found"
    fi
    
    # Creating named pipe for automatic input to LLM server
    PIPE_DIR="/tmp/ai-dev-team"
    mkdir -p "$PIPE_DIR"
    PIPE="$PIPE_DIR/llm_pipe"
    
    # Remove pipe if it exists
    if [ -p "$PIPE" ]; then
        rm "$PIPE"
    fi
    
    # Create a new pipe
    mkfifo "$PIPE"
    
    # Start LLM server with pipe for input
    # The 'n' response is for 'Run on CPU only? (y/N):' prompt
    echo "n" > "$PIPE" &
    
    # Pass configuration to LLM server
    export LLM_MODEL="${config_llm_default_model}"
    export LLM_PORT="${LLM_PORT}"
    export LLM_HOST="${config_llm_host}"
    export LLM_THREADS="${config_llm_threads}"
    export LLM_CONTEXT_SIZE="${config_llm_context_size}"
    export LLM_GPU_LAYERS="${config_llm_gpu_layers}"
    export LLM_TEMPERATURE="${config_llm_temperature}"
    export LLM_EXTRA_PARAMS="${config_llm_extra_params}"
    
    # Start the LLM server with input from the pipe
    scripts/run_llama_server.sh < "$PIPE" > /tmp/llm_server.log 2>&1 &
    LLM_PID=$!
    
    # Check if LLM server started successfully
    sleep 5
    
    if port_in_use "${LLM_PORT}"; then
        echo -e "${GREEN}✅ LLM server started successfully (PID: $LLM_PID).${NC}"
        echo -e "  Log available at: /tmp/llm_server.log"
    else
        echo -e "${RED}❌ Failed to start LLM server.${NC}"
        echo -e "  Check log for details: /tmp/llm_server.log"
        cat /tmp/llm_server.log
        error_handler "Failed to start LLM server"
    fi
fi

# Check if VS Code agent is already running
if port_in_use "${BACKEND_PORT}"; then
    echo -e "${YELLOW}⚠️ Port ${BACKEND_PORT} is already in use.${NC}"
    # Find an available port
    BACKEND_PORT=$(find_available_port "${BACKEND_PORT}")
    echo -e "${GREEN}✅ Found available port: ${BACKEND_PORT}${NC}"
    export BACKEND_PORT
    
    # Save port to a file that the VS Code extension can read
    echo "${BACKEND_PORT}" > /tmp/vscode_ai_agent_port.txt
    chmod 644 /tmp/vscode_ai_agent_port.txt
else
    # Start VS Code agent server in background
    echo -e "${YELLOW}Starting VS Code agent server...${NC}"
    
    # Save port to a file that the VS Code extension can read
    echo "${BACKEND_PORT}" > /tmp/vscode_ai_agent_port.txt
    chmod 644 /tmp/vscode_ai_agent_port.txt
    
    # Pass configuration to VS Code agent
    export VSCODE_AGENT_PORT="${BACKEND_PORT}"
    export VSCODE_AGENT_HOST="${config_backend_host}"
    export VSCODE_AGENT_DEBUG="${config_backend_debug}"
    export VSCODE_AGENT_USE_MEMORY="${config_backend_use_memory}"
    export VSCODE_AGENT_LLM_HOST="${config_llm_host}"
    export VSCODE_AGENT_LLM_PORT="${LLM_PORT}"
    # Make VSCODE_AGENT_LLM_URL available for direct use
    export VSCODE_AGENT_LLM_URL="http://${config_llm_host}:${LLM_PORT}/v1"
    
    scripts/start_vscode_agent.sh > /tmp/vscode_agent.log 2>&1 &
    AGENT_PID=$!
    
    # Check if VS Code agent started successfully - give it more time
    sleep 10
    
    if port_in_use "${BACKEND_PORT}"; then
        echo -e "${GREEN}✅ VS Code agent started successfully (PID: $AGENT_PID).${NC}"
        echo -e "  Log available at: /tmp/vscode_agent.log"
    else
        echo -e "${RED}❌ Failed to start VS Code agent.${NC}"
        echo -e "  Check log for details: /tmp/vscode_agent.log"
        cat /tmp/vscode_agent.log
        error_handler "Failed to start VS Code agent"
    fi
fi

# Final status
if [ $HAD_ERROR -eq 0 ]; then
    echo -e ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${BLUE}  All services are now running!                       ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e ""
    echo -e "${GREEN}✅ Weaviate database: Running in Docker${NC}"
    echo -e "${GREEN}✅ LLM server: http://${config_llm_host}:${LLM_PORT}${NC}"
    echo -e "${GREEN}✅ VS Code agent: http://${config_backend_host}:${BACKEND_PORT}${NC}"
    echo -e ""
    echo -e "You can now use the VS Code extension commands:"
    echo -e "  - Ask AI (Ctrl+Shift+A)"
    echo -e "  - Explain Code (Ctrl+Shift+E)"
    echo -e "  - Code Chat (Ctrl+Shift+C)"
    echo -e ""
    echo -e "To stop all services, run: ${YELLOW}./stop_all.sh${NC}"
else
    echo -e ""
    echo -e "${RED}======================================================${NC}"
    echo -e "${RED}  Some services failed to start                       ${NC}"
    echo -e "${RED}======================================================${NC}"
    echo -e ""
    echo -e "Please check the error messages above and logs for details."
    echo -e "You can try to restart the service manually or check the documentation."
    echo -e ""
    echo -e "To stop all running services, run: ${YELLOW}./stop_all.sh${NC}"
    # Commented out exit so script continues for debugging
    # exit 1
fi

# Keep the terminal open
echo -e "${YELLOW}Terminal will remain open. Use Ctrl+C to exit.${NC}"
# Wait for all background processes, but don't exit if a background process fails
set +e  # Disable exit on error for the wait command
wait
set -e  # Re-enable exit on error
#!/bin/bash

# VS Code AI Dev Team - All-in-One Startup Script
# This script starts all required services for the VS Code AI Dev Team extension

# Track if we had any errors
HAD_ERROR=0
error_handler() {
    HAD_ERROR=1
    echo -e "${RED}❌ Error occurred: $1${NC}"
}

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
  default_model: "models/Mistral-7B-Instruct-v0.2.Q4_K_M.gguf"
  # Server host
  host: "127.0.0.1"
  # Server port
  port: 8080
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
    if ! docker ps | grep -q weaviate; then
        echo -e "${YELLOW}Starting Weaviate database...${NC}"
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
    export LLM_PORT="${config_llm_port}"
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
    
    if port_in_use "${config_llm_port}"; then
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
if port_in_use "${config_backend_port}"; then
    echo -e "${GREEN}✅ VS Code agent is already running on port ${config_backend_port}.${NC}"
else
    # Start VS Code agent
    echo -e "${YELLOW}Starting VS Code agent...${NC}"
    
    # Pass configuration to VS Code agent
    export BACKEND_PORT="${config_backend_port}"
    export BACKEND_HOST="${config_backend_host}"
    export BACKEND_DEBUG="${config_backend_debug}"
    export USE_MEMORY="${config_backend_use_memory}"
    export WEAVIATE_HOST="${config_weaviate_host}"
    export WEAVIATE_PORT="${config_weaviate_port}"
    export WEAVIATE_SCHEMA="${config_weaviate_schema_name}"
    export WEAVIATE_CLASS="${config_weaviate_class_name}"
    export LLM_API_URL="http://${config_llm_host}:${config_llm_port}"
    
    scripts/start_vscode_agent.sh > /tmp/vscode_agent.log 2>&1 &
    AGENT_PID=$!
    
    # Check if agent started successfully
    sleep 5
    
    if port_in_use "${config_backend_port}"; then
        echo -e "${GREEN}✅ VS Code agent started successfully (PID: $AGENT_PID).${NC}"
        echo -e "  Log available at: /tmp/vscode_agent.log"
    else
        echo -e "${RED}❌ Failed to start VS Code agent.${NC}"
        echo -e "  Check log for details: /tmp/vscode_agent.log"
        cat /tmp/vscode_agent.log
        error_handler "Failed to start VS Code agent"
    fi
fi

echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  All services are now running!                       ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""
if [ "${config_backend_use_memory}" = "true" ]; then
    echo -e "${GREEN}✅ Weaviate database: Running in Docker${NC}"
fi
echo -e "${GREEN}✅ LLM server: http://${config_llm_host}:${config_llm_port}${NC}"
echo -e "${GREEN}✅ VS Code agent: http://${config_backend_host}:${config_backend_port}${NC}"
echo ""
echo -e "${YELLOW}You can now use the VS Code extension commands:${NC}"
echo -e "  - Ask AI (Ctrl+Shift+A)"
echo -e "  - Explain Code (Ctrl+Shift+E)"
echo -e "  - Complete Code (Ctrl+Shift+C)"
echo -e "  - Improve Code (Ctrl+Shift+I)"
echo ""
echo -e "${YELLOW}To stop services, run:${NC} ./stop_all.sh"
echo -e "${BLUE}======================================================${NC}"

# Display status message based on errors
if [ $HAD_ERROR -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ There were errors during startup. Please review the messages above.${NC}"
else
    echo ""
    echo -e "${GREEN}✅ All services started successfully.${NC}"
fi

# Keep the terminal open
echo -e "${YELLOW}Terminal will remain open. Use Ctrl+C to exit.${NC}"
# Wait for all background processes
wait 
#!/bin/bash

# VS Code AI Dev Team - All-in-One Startup Script
# This script starts all required services for the VS Code AI Dev Team extension

# Set script to exit on error
set -e

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if required files exist
if [ ! -f "scripts/run_llama_server.sh" ] || [ ! -f "scripts/start_vscode_agent.sh" ]; then
    echo "Error: Required script files not found. Make sure you're in the project root directory."
    exit 1
fi

# Ensure scripts are executable
chmod +x scripts/run_llama_server.sh
chmod +x scripts/start_vscode_agent.sh

# Display banner
echo "======================================================"
echo "  VS Code AI Dev Team - All-in-One Starter"
echo "======================================================"
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

# Verify Docker is running
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed."
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
elif ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running."
    echo "Please start Docker first."
    exit 1
else
    echo "✅ Docker is running."
fi

# Check if venv exists, create if not
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r backend/requirements.txt
else
    source venv/bin/activate
fi

# Start Weaviate if not running
echo "Checking Weaviate status..."
if ! docker ps | grep -q weaviate; then
    echo "Starting Weaviate database..."
    docker-compose up -d
    
    # Wait for Weaviate to initialize
    echo "Waiting for Weaviate to initialize (10 seconds)..."
    sleep 10
    
    if docker ps | grep -q weaviate; then
        echo "✅ Weaviate started successfully."
    else
        echo "❌ Failed to start Weaviate."
        exit 1
    fi
else
    echo "✅ Weaviate is already running."
fi

# Check if LLM server is already running
if port_in_use 8081; then
    echo "✅ LLM server is already running on port 8081."
else
    # Start LLM server in background
    echo "Starting LLM server..."
    
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
    
    # Start the LLM server with input from the pipe
    scripts/run_llama_server.sh < "$PIPE" > /tmp/llm_server.log 2>&1 &
    LLM_PID=$!
    
    # Check if LLM server started successfully
    sleep 5
    
    if port_in_use 8081; then
        echo "✅ LLM server started successfully (PID: $LLM_PID)."
        echo "  Log available at: /tmp/llm_server.log"
    else
        echo "❌ Failed to start LLM server."
        echo "  Check log for details: /tmp/llm_server.log"
        cat /tmp/llm_server.log
        exit 1
    fi
fi

# Check if VS Code agent is already running
if port_in_use 5000; then
    echo "✅ VS Code agent is already running on port 5000."
else
    # Start VS Code agent
    echo "Starting VS Code agent..."
    scripts/start_vscode_agent.sh > /tmp/vscode_agent.log 2>&1 &
    AGENT_PID=$!
    
    # Check if agent started successfully
    sleep 5
    
    if port_in_use 5000; then
        echo "✅ VS Code agent started successfully (PID: $AGENT_PID)."
        echo "  Log available at: /tmp/vscode_agent.log"
    else
        echo "❌ Failed to start VS Code agent."
        echo "  Check log for details: /tmp/vscode_agent.log"
        cat /tmp/vscode_agent.log
        exit 1
    fi
fi

echo ""
echo "======================================================"
echo "  All services are now running!"
echo "======================================================"
echo ""
echo "✅ Weaviate database: Running in Docker"
echo "✅ LLM server: http://localhost:8081"
echo "✅ VS Code agent: http://localhost:5000"
echo ""
echo "You can now use the VS Code extension commands:"
echo "  - Ask AI (Ctrl+Shift+A)"
echo "  - Explain Code (Ctrl+Shift+E)"
echo "  - Complete Code (Ctrl+Shift+C)"
echo "  - Improve Code (Ctrl+Shift+I)"
echo ""
echo "To stop services, press Ctrl+C in the terminal where"
echo "each server is running, or use the stop_all.sh script."
echo "======================================================" 
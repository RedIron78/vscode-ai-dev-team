#!/bin/bash

# VS Code AI Dev Team - Service Stopper
# This script stops all services started by start_all.sh

# Display banner
echo "======================================================"
echo "  VS Code AI Dev Team - Stopping All Services"
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

# Stop the VS Code agent
if port_in_use 5000; then
    echo "Stopping VS Code agent..."
    if pgrep -f "vscode_integration.py" > /dev/null; then
        pkill -f "vscode_integration.py"
        echo "✅ VS Code agent stopped."
    else
        echo "⚠️ Could not find VS Code agent process."
        echo "   You may need to manually kill the process."
    fi
else
    echo "✅ VS Code agent is not running."
fi

# Stop the LLM server
if port_in_use 8081; then
    echo "Stopping LLM server..."
    if pgrep -f "llama-server" > /dev/null; then
        pkill -f "llama-server"
        echo "✅ LLM server stopped."
    else
        echo "⚠️ Could not find LLM server process."
        echo "   You may need to manually kill the process."
    fi
else
    echo "✅ LLM server is not running."
fi

# Stop Weaviate
echo "Stopping Weaviate..."
if docker ps | grep -q weaviate; then
    docker-compose down
    echo "✅ Weaviate stopped."
else
    echo "✅ Weaviate is not running."
fi

# Clean up named pipes
PIPE_DIR="/tmp/ai-dev-team"
PIPE="$PIPE_DIR/llm_pipe"
if [ -p "$PIPE" ]; then
    rm "$PIPE"
fi

echo ""
echo "======================================================"
echo "  All services have been stopped!"
echo "======================================================"
echo ""
echo "To start services again, run: ./start_all.sh"
echo "======================================================" 
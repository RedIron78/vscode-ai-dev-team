#!/bin/bash

# Start script for VS Code integration server

# Set the base directory to the repository root
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

# Check if virtual environment exists, create if not
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r backend/requirements.txt
else
    source venv/bin/activate
fi

# Check if Weaviate is running
if ! docker ps | grep -q weaviate; then
    echo "Starting Weaviate server..."
    docker-compose up -d
    echo "Waiting for Weaviate to initialize..."
    sleep 5
fi

# Check for command line arguments
PRODUCTION_MODE=false
DEBUG_MODE=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --production) PRODUCTION_MODE=true ;;
        --debug) DEBUG_MODE=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Set up log directory
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

# Current date/time for log files
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Run the VS Code integration server
if [ "$PRODUCTION_MODE" = true ]; then
    echo "Starting VS Code integration server in production mode..."
    cd "$BASE_DIR"
    python -m backend.vscode_integration --production > "$LOG_DIR/vscode_server_$TIMESTAMP.log" 2>&1 &
    PID=$!
    echo "Server started with PID: $PID (Logs in $LOG_DIR/vscode_server_$TIMESTAMP.log)"
elif [ "$DEBUG_MODE" = true ]; then
    echo "Starting VS Code integration server in debug mode..."
    cd "$BASE_DIR"
    python -m backend.vscode_integration --debug
else
    echo "Starting VS Code integration server..."
    cd "$BASE_DIR"
    python backend/vscode_integration.py
fi

# If running in background, provide instructions to kill
if [ "$PRODUCTION_MODE" = true ]; then
    echo ""
    echo "To stop the server, run: kill $PID"
    echo "Or find the process with: ps aux | grep vscode_integration"
fi 
#!/bin/bash

# Installation script for VS Code AI Dev Team Extension

echo "Setting up VS Code AI Dev Team Extension..."

# Set the base directory to the repository root
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

# Check if Python is installed
if ! command -v python3 &>/dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r backend/requirements.txt

# Check if Node.js and npm are installed
if ! command -v npm &>/dev/null; then
    echo "Warning: npm is not installed. You will need npm to build the VS Code extension."
    echo "Please install Node.js from https://nodejs.org/"
else
    echo "Installing extension dependencies..."
    cd extension
    npm install
    cd ..
fi

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    echo "Warning: Docker is not installed. You will need Docker to run Weaviate."
    echo "Please install Docker from https://docs.docker.com/get-docker/"
else
    echo "Docker is installed. You can start Weaviate with 'docker-compose up -d'"
fi

# Start Weaviate if Docker is available
if command -v docker-compose &>/dev/null; then
    echo "Starting Weaviate server..."
    docker-compose up -d
else
    echo "Warning: docker-compose is not installed. You will need it to run Weaviate."
    echo "Please install docker-compose: https://docs.docker.com/compose/install/"
fi

# Make scripts executable
chmod +x scripts/start_vscode_agent.sh
chmod +x scripts/run_llama_server.sh

# Create directories for models and memory if they don't exist
mkdir -p models memory

# Instructions for running the server
echo ""
echo "Installation completed!"
echo ""
echo "To start the VS Code integration server:"
echo "1. Activate the virtual environment: source venv/bin/activate"
echo "2. Run: ./scripts/start_vscode_agent.sh"
echo ""
echo "To build the VS Code extension:"
echo "1. Go to the extension directory: cd extension"
echo "2. Run: npm run compile"
echo "3. Run: npm run package"
echo ""
echo "To install the VS Code extension:"
echo "1. In VS Code, go to Extensions (Ctrl+Shift+X)"
echo "2. Click the '...' menu and select 'Install from VSIX...'"
echo "3. Navigate to extension/vscode-ai-dev-team-*.vsix and select it"
echo ""

echo "Setup complete!" 
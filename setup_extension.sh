#!/bin/bash

# VS Code AI Dev Team Extension Setup Script
# This script sets up the VS Code extension from the original repository structure

set -e  # Exit on any error

echo "============================================="
echo "VS Code AI Dev Team Extension Setup"
echo "============================================="

# Detect operating system
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS="windows"
fi

echo "Detected operating system: $OS"

# Detect if this is being run from the source repository or from a new clone
if [ -d "vscode-extension" ] && [ ! -d "extension" ]; then
    echo "Original repository structure detected. Converting to extension structure..."
    
    # Create the directory structure
    mkdir -p extension/src extension/resources backend scripts
    
    # Copy extension files
    echo "Copying extension files..."
    cp -r vscode-extension/src/* extension/src/ 2>/dev/null || true
    cp -r vscode-extension/resources/* extension/resources/ 2>/dev/null || true
    cp vscode-extension/package.json extension/ 2>/dev/null || true
    cp vscode-extension/tsconfig.json extension/ 2>/dev/null || true
    cp vscode-extension/.gitignore extension/ 2>/dev/null || true
    cp vscode-extension/.vscodeignore extension/ 2>/dev/null || true
    cp vscode-extension/README.md extension/ 2>/dev/null || true
    cp vscode-extension/ARCHITECTURE.md extension/ 2>/dev/null || true
    cp vscode-extension/LICENSE.txt extension/ 2>/dev/null || true
    
    # Copy backend files
    echo "Copying backend files..."
    cp agent_roles.py backend/ 2>/dev/null || true
    cp vscode_agent.py backend/ 2>/dev/null || true
    cp vscode_integration.py backend/ 2>/dev/null || true
    cp llm_interface.py backend/ 2>/dev/null || true
    cp requirements.txt backend/ 2>/dev/null || true
    
    # Copy scripts
    echo "Copying scripts..."
    cp install.sh scripts/ 2>/dev/null || true
    cp start_vscode_agent.sh scripts/ 2>/dev/null || true
    cp run_llama_server.sh scripts/ 2>/dev/null || true
    
    # Create Python setup file to enable imports
    echo "Creating Python package files..."
    touch backend/__init__.py
    
    echo "# VS Code AI Dev Team Extension" > README.md
    cat << 'EOF' >> README.md
This extension integrates an AI agent with vector memory into Visual Studio Code, providing intelligent code assistance, explanation, and completion capabilities.

## Features

- AI-powered code explanations
- Intelligent code completion
- Code improvement suggestions
- Chat with AI for project-related questions
- Vector memory for context-aware responses

## Quick Start

### Linux/macOS

Run the setup script to organize the repository:

```bash
./setup_extension.sh
```

Then run the installation script:

```bash
./scripts/install.sh
```

### Windows

Run the setup script to organize the repository:

```
setup_extension.bat
```

Then run the installation script:

```
scripts\install.bat
```

For detailed instructions, see [INSTALL.md](INSTALL.md).

## Project Structure

```
vscode-ai-dev-team/
├── extension/                 # VS Code extension code
│   ├── src/                   # TypeScript source
│   ├── resources/             # Extension resources
│   ├── package.json           # Extension manifest
│   └── ...                    # Other extension files
├── backend/                   # Python backend services
│   ├── agent_roles.py         # Agent definitions
│   ├── vscode_agent.py        # VS Code agent implementation
│   ├── vscode_integration.py  # API server for VS Code
│   ├── llm_interface.py       # LLM connection interface
│   └── requirements.txt       # Python dependencies
├── scripts/                   # Helper scripts
│   ├── install.sh             # Installation script (Linux/macOS)
│   ├── install.bat            # Installation script (Windows)
│   ├── start_vscode_agent.sh  # Start the agent server (Linux/macOS)
│   ├── start_vscode_agent.bat # Start the agent server (Windows)
│   └── run_llama_server.sh    # Run LLM server
└── docker-compose.yml         # Weaviate Docker compose
```
EOF

    # Create updated installation script for Linux/macOS
    cat << 'EOF' > scripts/install.sh
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
EOF

    # Create Windows installation script
    cat << 'EOF' > scripts/install.bat
@echo off
REM Installation script for VS Code AI Dev Team Extension on Windows

echo Setting up VS Code AI Dev Team Extension...

REM Set the base directory to the repository root
set "BASE_DIR=%~dp0.."
cd /d "%BASE_DIR%"

REM Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python is required but not installed.
    exit /b 1
)

REM Create virtual environment
echo Creating virtual environment...
python -m venv venv
call venv\Scripts\activate.bat

REM Install Python dependencies
echo Installing Python dependencies...
pip install --upgrade pip
pip install -r backend\requirements.txt

REM Check if Node.js and npm are installed
npm --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: npm is not installed. You will need npm to build the VS Code extension.
    echo Please install Node.js from https://nodejs.org/
) else (
    echo Installing extension dependencies...
    cd extension
    npm install
    cd ..
)

REM Check if Docker is installed
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Docker is not installed. You will need Docker to run Weaviate.
    echo Please install Docker from https://docs.docker.com/get-docker/
) else (
    echo Docker is installed. You can start Weaviate with 'docker-compose up -d'
)

REM Start Weaviate if Docker is available
docker-compose --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Starting Weaviate server...
    docker-compose up -d
) else (
    echo Warning: docker-compose is not installed. You will need it to run Weaviate.
    echo Please install docker-compose: https://docs.docker.com/compose/install/
)

REM Create directories for models and memory if they don't exist
if not exist models mkdir models
if not exist memory mkdir memory

REM Instructions for running the server
echo.
echo Installation completed!
echo.
echo To start the VS Code integration server:
echo 1. Activate the virtual environment: venv\Scripts\activate.bat
echo 2. Run: scripts\start_vscode_agent.bat
echo.
echo To build the VS Code extension:
echo 1. Go to the extension directory: cd extension
echo 2. Run: npm run compile
echo 3. Run: npm run package
echo.
echo To install the VS Code extension:
echo 1. In VS Code, go to Extensions (Ctrl+Shift+X)
echo 2. Click the '...' menu and select 'Install from VSIX...'
echo 3. Navigate to extension\vscode-ai-dev-team-*.vsix and select it
echo.

echo Setup complete!
pause
EOF

    # Create updated start script for Linux/macOS
    cat << 'EOF' > scripts/start_vscode_agent.sh
#!/bin/bash

# Start script for VS Code integration server

# Set the base directory to the repository root
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

# Ensure Python can find our backend modules
export PYTHONPATH="$BASE_DIR:$PYTHONPATH"

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
    python backend/vscode_integration.py --production > "$LOG_DIR/vscode_server_$TIMESTAMP.log" 2>&1 &
    PID=$!
    echo "Server started with PID: $PID (Logs in $LOG_DIR/vscode_server_$TIMESTAMP.log)"
elif [ "$DEBUG_MODE" = true ]; then
    echo "Starting VS Code integration server in debug mode..."
    cd "$BASE_DIR"
    python backend/vscode_integration.py --debug
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
EOF

    # Create Windows start script
    cat << 'EOF' > scripts/start_vscode_agent.bat
@echo off
REM Start script for VS Code integration server on Windows

REM Set the base directory to the repository root
set "BASE_DIR=%~dp0.."
cd /d "%BASE_DIR%"

REM Ensure Python can find our backend modules
set PYTHONPATH=%BASE_DIR%;%PYTHONPATH%

REM Check if virtual environment exists, create if not
if not exist venv (
    echo Virtual environment not found. Creating one...
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install --upgrade pip
    pip install -r backend\requirements.txt
) else (
    call venv\Scripts\activate.bat
)

REM Check if Weaviate is running
docker ps | findstr "weaviate" >nul
if %ERRORLEVEL% NEQ 0 (
    echo Starting Weaviate server...
    docker-compose up -d
    echo Waiting for Weaviate to initialize...
    timeout /t 5
)

REM Default mode
set PRODUCTION_MODE=false
set DEBUG_MODE=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :done_args
if "%~1"=="--production" (
    set PRODUCTION_MODE=true
    shift
    goto :parse_args
)
if "%~1"=="--debug" (
    set DEBUG_MODE=true
    shift
    goto :parse_args
)
echo Unknown parameter: %1
exit /b 1
:done_args

REM Set up log directory
set LOG_DIR=%BASE_DIR%\logs
if not exist %LOG_DIR% mkdir %LOG_DIR%

REM Current date/time for log files
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set DATETIME=%%I
set TIMESTAMP=%DATETIME:~0,8%-%DATETIME:~8,6%

REM Run the VS Code integration server
if "%PRODUCTION_MODE%"=="true" (
    echo Starting VS Code integration server in production mode...
    cd /d "%BASE_DIR%"
    start /b cmd /c "python backend\vscode_integration.py --production > %LOG_DIR%\vscode_server_%TIMESTAMP%.log 2>&1"
    echo Server started in background. Logs in %LOG_DIR%\vscode_server_%TIMESTAMP%.log
) else if "%DEBUG_MODE%"=="true" (
    echo Starting VS Code integration server in debug mode...
    cd /d "%BASE_DIR%"
    python backend\vscode_integration.py --debug
) else (
    echo Starting VS Code integration server...
    cd /d "%BASE_DIR%"
    python backend\vscode_integration.py
)
EOF

    # Create updated run_llama_server script
    cat << 'EOF' > scripts/run_llama_server.sh
#!/bin/bash

# Run script for llama.cpp server
# This script sets up and runs the llama.cpp server for LLM capabilities

# Set the base directory to the repository root
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

# Configuration
MODEL_DIR="$BASE_DIR/models"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

# Check if llama-server is in the path
if ! command -v llama-server &> /dev/null && [ ! -f "$BASE_DIR/llama-server" ]; then
    echo "llama-server not found. Please install llama.cpp or provide the binary."
    echo "See https://github.com/ggerganov/llama.cpp for installation instructions."
    exit 1
fi

# Determine the server path
if command -v llama-server &> /dev/null; then
    LLAMA_SERVER_PATH="llama-server"
else
    LLAMA_SERVER_PATH="$BASE_DIR/llama-server"
    chmod +x "$LLAMA_SERVER_PATH"
fi

# Check for model file
if [ -z "$(ls -A $MODEL_DIR 2>/dev/null)" ]; then
    echo "No model files found in $MODEL_DIR"
    echo "Please download a model in GGUF format and place it in the models directory."
    exit 1
fi

# Find the first GGUF model file
MODEL_FILE=$(find "$MODEL_DIR" -name "*.gguf" | head -n 1)

if [ -z "$MODEL_FILE" ]; then
    echo "No GGUF model files found in $MODEL_DIR"
    echo "Please download a model in GGUF format and place it in the models directory."
    exit 1
fi

echo "Using model: $MODEL_FILE"
echo "Starting LLM server..."

# Start the server with the model
"$LLAMA_SERVER_PATH" \
    -m "$MODEL_FILE" \
    --host 127.0.0.1 \
    --port 8080 \
    --log-format json \
    --context-size 2048 \
    --threads 4 \
    > "$LOG_DIR/llama_server.log" 2>&1 &

SERVER_PID=$!
echo "Server started with PID: $SERVER_PID"
echo "Logs available at: $LOG_DIR/llama_server.log"
echo ""
echo "To stop the server, run: kill $SERVER_PID"
EOF

    # Create Windows version of the llama script
    cat << 'EOF' > scripts/run_llama_server.bat
@echo off
REM Run script for llama.cpp server on Windows
REM This script sets up and runs the llama.cpp server for LLM capabilities

REM Set the base directory to the repository root
set "BASE_DIR=%~dp0.."
cd /d "%BASE_DIR%"

REM Configuration
set MODEL_DIR=%BASE_DIR%\models
set LOG_DIR=%BASE_DIR%\logs
if not exist %LOG_DIR% mkdir %LOG_DIR%

REM Check if llama-server is in the path or exists locally
where llama-server >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if not exist "%BASE_DIR%\llama-server.exe" (
        echo llama-server not found. Please install llama.cpp or provide the binary.
        echo See https://github.com/ggerganov/llama.cpp for installation instructions.
        exit /b 1
    )
    set "LLAMA_SERVER_PATH=%BASE_DIR%\llama-server.exe"
) else (
    set "LLAMA_SERVER_PATH=llama-server"
)

REM Check for model file
dir /b "%MODEL_DIR%\*.gguf" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo No GGUF model files found in %MODEL_DIR%
    echo Please download a model in GGUF format and place it in the models directory.
    exit /b 1
)

REM Find the first GGUF model file
for /f "tokens=*" %%f in ('dir /b "%MODEL_DIR%\*.gguf" 2^>nul') do (
    set "MODEL_FILE=%MODEL_DIR%\%%f"
    goto :found_model
)

:found_model
echo Using model: %MODEL_FILE%
echo Starting LLM server...

REM Start the server with the model
start /b cmd /c "%LLAMA_SERVER_PATH% -m "%MODEL_FILE%" --host 127.0.0.1 --port 8080 --log-format json --context-size 2048 --threads 4 > "%LOG_DIR%\llama_server.log" 2>&1"

echo Server started in background
echo Logs available at: %LOG_DIR%\llama_server.log
EOF

    # Create setup.bat for Windows
    cat << 'EOF' > setup_extension.bat
@echo off
REM VS Code AI Dev Team Extension Setup Script for Windows
REM This script sets up the VS Code extension from the original repository structure

echo =============================================
echo VS Code AI Dev Team Extension Setup
echo =============================================

REM Detect if this is being run from the source repository or from a new clone
if exist vscode-extension (
    if not exist extension (
        echo Original repository structure detected. Converting to extension structure...
        
        REM Create the directory structure
        mkdir extension\src extension\resources backend scripts 2>nul
        
        REM Copy extension files
        echo Copying extension files...
        xcopy /E /Y /Q vscode-extension\src\* extension\src\ 2>nul
        xcopy /E /Y /Q vscode-extension\resources\* extension\resources\ 2>nul
        copy /Y vscode-extension\package.json extension\ 2>nul
        copy /Y vscode-extension\tsconfig.json extension\ 2>nul
        copy /Y vscode-extension\.gitignore extension\ 2>nul
        copy /Y vscode-extension\.vscodeignore extension\ 2>nul
        copy /Y vscode-extension\README.md extension\ 2>nul
        copy /Y vscode-extension\ARCHITECTURE.md extension\ 2>nul
        copy /Y vscode-extension\LICENSE.txt extension\ 2>nul
        
        REM Copy backend files
        echo Copying backend files...
        copy /Y agent_roles.py backend\ 2>nul
        copy /Y vscode_agent.py backend\ 2>nul
        copy /Y vscode_integration.py backend\ 2>nul
        copy /Y llm_interface.py backend\ 2>nul
        copy /Y requirements.txt backend\ 2>nul
        
        REM Copy scripts
        echo Copying scripts...
        copy /Y install.sh scripts\ 2>nul
        copy /Y start_vscode_agent.sh scripts\ 2>nul
        copy /Y run_llama_server.sh scripts\ 2>nul
        
        REM Create Python setup file to enable imports
        echo Creating Python package files...
        echo. > backend\__init__.py
        
        echo Conversion complete! Run scripts\install.bat to get started.
    ) else (
        echo Extension structure already set up.
    )
) else (
    echo Extension structure already set up.
)

echo =============================================
echo Setup Complete!
echo Run scripts\install.bat to install dependencies
echo =============================================
pause
EOF

    # Make the scripts executable
    chmod +x scripts/install.sh
    chmod +x scripts/start_vscode_agent.sh
    chmod +x scripts/run_llama_server.sh
    chmod +x setup_extension.sh
    
    # Create or update .gitignore
    cat << 'EOF' > .gitignore
# Node
node_modules/
out/
dist/
*.vsix

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
venv/
.env

# System
.DS_Store
Thumbs.db

# AI Models
models/
memory/
weaviate/data/

# Logs
*.log
logs/

# VS Code
.vscode/
.vs/
EOF

    echo "Conversion complete! Run ./scripts/install.sh to get started."
    
else
    echo "Extension structure already set up."
fi

# Make self executable
chmod +x setup_extension.sh

echo "============================================="
echo "Setup Complete!"
if [[ "$OS" == "windows" ]]; then
    echo "Run scripts\\install.bat to install dependencies"
else
    echo "Run ./scripts/install.sh to install dependencies"
fi
echo "=============================================" 
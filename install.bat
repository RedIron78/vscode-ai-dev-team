@echo off
REM VS Code AI Dev Team - One-Click Installer for Windows
REM This script installs and sets up the VS Code AI Dev Team extension

echo =========================================================
echo      VS Code AI Dev Team - One-Click Installer
echo =========================================================
echo.

REM Check system requirements
echo Checking system requirements...

REM Check for Python
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python not found. Please install Python 3.8+ before continuing.
    exit /b 1
)

REM Check for pip
pip --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: pip not found. Please install pip for Python before continuing.
    exit /b 1
)

REM Check for Node.js
node --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Node.js not found. Please install Node.js before continuing.
    exit /b 1
)

REM Check for npm
npm --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: npm not found. Please install npm before continuing.
    exit /b 1
)

REM Check for Docker
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Docker not found. Vector database features will not be available.
    echo Do you want to continue without Docker? (y/n)
    set /p docker_choice=
    if /i not "%docker_choice%"=="y" (
        echo Installation aborted. Please install Docker and try again.
        exit /b 1
    )
)

REM Create Python virtual environment
echo.
echo Setting up Python virtual environment...
if not exist venv (
    python -m venv venv
    echo Virtual environment created.
) else (
    echo Virtual environment already exists.
)

REM Activate virtual environment
call venv\Scripts\activate.bat
echo Virtual environment activated.

REM Install Python dependencies
echo.
echo Installing Python dependencies...
pip install --upgrade pip
pip install -r backend\requirements.txt
echo Python dependencies installed.

REM Build the extension
echo.
echo Building VS Code extension...
cd extension
call npm install
call npm run compile
call npm run package
cd ..
echo VS Code extension built.

REM Setup Weaviate (if Docker is available)
docker --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo.
    echo Setting up Weaviate vector database...
    docker-compose pull
    echo Weaviate image pulled.
)

REM Setup llama.cpp
echo.
echo Setting up llama.cpp...
if exist llama.cpp (
    cd llama.cpp
    git pull
    cd ..
    echo llama.cpp updated.
) else (
    git clone https://github.com/ggerganov/llama.cpp.git
    echo llama.cpp cloned.
)

REM Build llama.cpp
echo.
echo Building llama.cpp...
cd llama.cpp
REM Check for NVIDIA GPU using nvidia-smi
nvidia-smi >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Building with CUDA support...
    call cmake -B build -DLLAMA_CUBLAS=ON
    call cmake --build build --config Release
) else (
    echo Building with CPU support...
    call cmake -B build
    call cmake --build build --config Release
)
cd ..
echo llama.cpp built.

REM Create necessary directories
echo.
echo Creating necessary directories...
if not exist models mkdir models
if not exist logs mkdir logs
if not exist memory mkdir memory
echo Directories created.

REM Check if model exists
echo.
echo Checking for LLM models...
dir /b models\*.gguf >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo No models found in the models directory.
    echo You need to download a compatible model (e.g., Mistral-7B-Instruct-v0.2.Q4_K_M.gguf).
    echo Place downloaded models in the 'models' directory.
    
    echo Would you like to see instructions for downloading models? (y/n)
    set /p model_choice=
    if /i "%model_choice%"=="y" (
        echo.
        echo Model Download Instructions:
        echo 1. Visit https://huggingface.co/models?pipeline_tag=text-generation^&sort=downloads
        echo 2. Choose a model (Mistral-7B or Llama 2 7B are good starting points)
        echo 3. Download the GGUF version of the model (Q4_K_M is a good balance)
        echo 4. Place the downloaded .gguf file in the 'models' directory
    )
) else (
    echo Models found in the models directory.
    dir models\*.gguf
)

REM Install VS Code extension
echo.
echo Installing the VS Code extension...
code --install-extension extension\vscode-ai-dev-team-0.1.0.vsix >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo VS Code extension installed.
) else (
    echo VS Code CLI not found. Please install the extension manually:
    echo 1. Open VS Code
    echo 2. Go to Extensions panel (Ctrl+Shift+X)
    echo 3. Click the '...' menu in the top-right corner
    echo 4. Select 'Install from VSIX...'
    echo 5. Navigate to %CD%\extension\vscode-ai-dev-team-0.1.0.vsix
)

echo.
echo ==================================================
echo   Installation complete! Here's how to get started:
echo ==================================================
echo.
echo 1. Start all services with: start_all.bat
echo 2. Open VS Code and use the command palette (Ctrl+Shift+P):
echo    - AI Dev Team: Ask AI
echo    - AI Dev Team: Explain Selected Code
echo    - AI Dev Team: Complete Code
echo 3. Stop all services with: stop_all.bat
echo.
echo For more details, see README.md and COMPLETE-GUIDE.md

pause 
@echo off
REM VS Code AI Dev Team - All-in-One Startup Script for Windows
REM This script starts all required services for the VS Code AI Dev Team extension

echo ======================================================
echo  VS Code AI Dev Team - All-in-One Starter
echo ======================================================
echo.

REM Check if config.yml exists, create if not
if not exist config.yml (
    echo Warning: config.yml not found, creating with default settings...
    (
        echo # VS Code AI Dev Team Configuration
        echo.
        echo # LLM Server Configuration
        echo llm:
        echo   # Default model to use
        echo   default_model: "models/Mistral-7B-Instruct-v0.2.Q4_K_M.gguf"
        echo   # Server host
        echo   host: "127.0.0.1"
        echo   # Server port
        echo   port: 8080
        echo   # Number of CPU threads (0 = auto)
        echo   threads: 0
        echo   # Context size
        echo   context_size: 4096
        echo   # GPU layers (0 = CPU only)
        echo   gpu_layers: 35
        echo   # Temperature (higher = more creative, lower = more deterministic)
        echo   temperature: 0.7
        echo   # Additional model parameters
        echo   extra_params: ""
        echo.
        echo # Python Backend Configuration
        echo backend:
        echo   # Host for the Flask backend
        echo   host: "127.0.0.1"
        echo   # Port for the Flask backend
        echo   port: 5000
        echo   # Debug mode (true/false)
        echo   debug: false
        echo   # Memory integration (true/false)
        echo   use_memory: true
        echo.
        echo # Weaviate Configuration
        echo weaviate:
        echo   # Host
        echo   host: "localhost"
        echo   # Port
        echo   port: 8090
        echo   # Schema name
        echo   schema_name: "VSCodeAssistant"
        echo   # Class name
        echo   class_name: "Memory"
    ) > config.yml
    echo Created default config.yml
)

REM Parse config.yml using a simple method (not as robust as bash version)
REM We'll set some defaults and then override with values from config if found
set LLM_MODEL=models\Mistral-7B-Instruct-v0.2.Q4_K_M.gguf
set LLM_PORT=8080
set LLM_HOST=127.0.0.1
set BACKEND_PORT=5000
set BACKEND_HOST=127.0.0.1
set USE_MEMORY=true

REM Simple config parser (this is a basic implementation)
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"default_model:" config.yml') do set LLM_MODEL=%%b
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"port:" config.yml') do (
    echo %%a | findstr "llm" >nul && set LLM_PORT=%%b
    echo %%a | findstr "backend" >nul && set BACKEND_PORT=%%b
)
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"host:" config.yml') do (
    echo %%a | findstr "llm" >nul && set LLM_HOST=%%b
    echo %%a | findstr "backend" >nul && set BACKEND_HOST=%%b
)
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"use_memory:" config.yml') do set USE_MEMORY=%%b

REM Remove quotes and spaces from values
set LLM_MODEL=%LLM_MODEL:"=%
set LLM_MODEL=%LLM_MODEL: =%
set LLM_PORT=%LLM_PORT:"=%
set LLM_PORT=%LLM_PORT: =%
set LLM_HOST=%LLM_HOST:"=%
set LLM_HOST=%LLM_HOST: =%
set BACKEND_PORT=%BACKEND_PORT:"=%
set BACKEND_PORT=%BACKEND_PORT: =%
set BACKEND_HOST=%BACKEND_HOST:"=%
set BACKEND_HOST=%BACKEND_HOST: =%
set USE_MEMORY=%USE_MEMORY:"=%
set USE_MEMORY=%USE_MEMORY: =%

echo Configuration loaded:
echo   LLM Model: %LLM_MODEL%
echo   LLM Port: %LLM_PORT%
echo   Backend Port: %BACKEND_PORT%
echo   Use Memory: %USE_MEMORY%

REM Check if Docker is needed and running
if "%USE_MEMORY%"=="true" (
    docker --version >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Docker is not installed but memory integration is enabled.
        echo Please install Docker first or disable memory in config.yml.
        exit /b 1
    )
    
    docker info >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Docker is not running but memory integration is enabled.
        echo Please start Docker first or disable memory in config.yml.
        exit /b 1
    )
    
    echo Docker is running.
)

REM Activate virtual environment
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install --upgrade pip
    pip install -r backend\requirements.txt
) else (
    call venv\Scripts\activate.bat
)

REM Start Weaviate if memory is enabled
if "%USE_MEMORY%"=="true" (
    echo Checking Weaviate status...
    docker ps | findstr "weaviate" >nul
    if %ERRORLEVEL% NEQ 0 (
        echo Starting Weaviate database...
        docker-compose up -d
        
        echo Waiting for Weaviate to initialize (10 seconds)...
        timeout /t 10 /nobreak >nul
        
        docker ps | findstr "weaviate" >nul
        if %ERRORLEVEL% EQU 0 (
            echo Weaviate started successfully.
        ) else (
            echo Failed to start Weaviate.
            exit /b 1
        )
    ) else (
        echo Weaviate is already running.
    )
) else (
    echo Memory integration is disabled in config.yml. Skipping Weaviate startup.
)

REM Check if LLM model exists
if not exist "%LLM_MODEL%" (
    echo Error: Model file not found: %LLM_MODEL%
    echo You can download models using scripts\download_model.sh
    exit /b 1
)

REM Check if LLM server is already running
set LLM_RUNNING=0
netstat -an | findstr ":%LLM_PORT%" >nul
if %ERRORLEVEL% EQU 0 set LLM_RUNNING=1

if %LLM_RUNNING% EQU 1 (
    echo LLM server is already running on port %LLM_PORT%.
) else (
    echo Starting LLM server...
    
    REM Set environment variables for LLM server
    set "MODEL_PATH=%LLM_MODEL%"
    set "SERVER_PORT=%LLM_PORT%"
    
    REM Start LLM server in a new window
    start "LLM Server" cmd /c "cd llama.cpp && build\bin\Release\server.exe --model ..\\%MODEL_PATH% --port %SERVER_PORT% --log-disable"
    
    echo Waiting for LLM server to start (10 seconds)...
    timeout /t 10 /nobreak >nul
    
    netstat -an | findstr ":%LLM_PORT%" >nul
    if %ERRORLEVEL% EQU 0 (
        echo LLM server started successfully.
    ) else (
        echo Failed to start LLM server.
        exit /b 1
    )
)

REM Check if VS Code agent is already running
set AGENT_RUNNING=0
netstat -an | findstr ":%BACKEND_PORT%" >nul
if %ERRORLEVEL% EQU 0 set AGENT_RUNNING=1

if %AGENT_RUNNING% EQU 1 (
    echo VS Code agent is already running on port %BACKEND_PORT%.
) else (
    echo Starting VS Code agent...
    
    REM Set environment variables for backend
    set "FLASK_APP=backend/vscode_integration.py"
    set "FLASK_PORT=%BACKEND_PORT%"
    set "FLASK_HOST=%BACKEND_HOST%"
    set "USE_MEMORY=%USE_MEMORY%"
    set "LLM_API_URL=http://%LLM_HOST%:%LLM_PORT%"
    
    REM Start VS Code agent in a new window
    start "VS Code Agent" cmd /c "python -m flask run --host=%FLASK_HOST% --port=%FLASK_PORT%"
    
    echo Waiting for VS Code agent to start (5 seconds)...
    timeout /t 5 /nobreak >nul
    
    netstat -an | findstr ":%BACKEND_PORT%" >nul
    if %ERRORLEVEL% EQU 0 (
        echo VS Code agent started successfully.
    ) else (
        echo Failed to start VS Code agent.
        exit /b 1
    )
)

echo.
echo ======================================================
echo  All services are now running!
echo ======================================================
echo.
if "%USE_MEMORY%"=="true" echo Weaviate database: Running in Docker
echo LLM server: http://%LLM_HOST%:%LLM_PORT%
echo VS Code agent: http://%BACKEND_HOST%:%BACKEND_PORT%
echo.
echo You can now use the VS Code extension commands:
echo   - Ask AI (Ctrl+Shift+A)
echo   - Explain Code (Ctrl+Shift+E)
echo   - Complete Code (Ctrl+Shift+C)
echo   - Improve Code (Ctrl+Shift+I)
echo.
echo To stop services, run: stop_all.bat
echo ======================================================

REM Keep the window open
pause 
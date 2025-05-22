@echo off
REM VS Code AI Dev Team - All-in-One Startup Script for Windows
REM This script starts all required services for the VS Code AI Dev Team extension
setlocal EnableDelayedExpansion

REM Ensure we're running from the script's directory
cd /d "%~dp0"

REM Track if we had any errors
set "HAD_ERROR=0"

echo ======================================================
echo  VS Code AI Dev Team - All-in-One Starter
echo ======================================================
echo.

REM Function to check for used port and find an available one
:CheckPort
setlocal
set "PORT=%~1"
set "SERVICE_NAME=%~2"
call :IsPortInUse %PORT% USED
if "%USED%"=="1" (
    echo Warning: Port %PORT% for %SERVICE_NAME% is already in use.
    call :FindAvailablePort %PORT% NEW_PORT
    echo Using alternative port: !NEW_PORT!
    endlocal & set "RESULT=!NEW_PORT!"
) else (
    endlocal & set "RESULT=%PORT%"
)
exit /b

:IsPortInUse
setlocal
netstat -an | findstr ":%~1 " | findstr "LISTENING" >nul
if %ERRORLEVEL% EQU 0 (
    endlocal & set "%~2=1"
) else (
    endlocal & set "%~2=0"
)
exit /b

:FindAvailablePort
setlocal
set "START_PORT=%~1"
set "CURRENT_PORT=%START_PORT%"
:PortLoop
set /a "CURRENT_PORT+=1"
call :IsPortInUse !CURRENT_PORT! IS_USED
if "%IS_USED%"=="1" (
    goto :PortLoop
)
if !CURRENT_PORT! GTR %START_PORT%+100 (
    echo Cannot find available port within reasonable range.
    endlocal & set "%~2=%START_PORT%"
) else (
    endlocal & set "%~2=!CURRENT_PORT!"
)
exit /b

REM Check if config.yml exists, create if not
if not exist config.yml (
    echo Warning: config.yml not found, creating with default settings...
    (
        echo # VS Code AI Dev Team Configuration
        echo.
        echo # LLM Server Configuration
        echo llm:
        echo   # Default model to use
        echo   default_model: "models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        echo   # Server host
        echo   host: "127.0.0.1"
        echo   # Server port
        echo   port: 8081
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
set LLM_MODEL=models\mistral-7b-instruct-v0.2.Q4_K_M.gguf
set LLM_PORT=8081
set LLM_HOST=127.0.0.1
set BACKEND_PORT=5000
set BACKEND_HOST=127.0.0.1
set USE_MEMORY=true
set WEAVIATE_PORT=8090

REM Simple config parser (this is a basic implementation)
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"default_model:" config.yml') do set LLM_MODEL=%%b
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"port:" config.yml') do (
    echo %%a | findstr "llm" >nul && set LLM_PORT=%%b
    echo %%a | findstr "backend" >nul && set BACKEND_PORT=%%b
    echo %%a | findstr "weaviate" >nul && set WEAVIATE_PORT=%%b
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
set WEAVIATE_PORT=%WEAVIATE_PORT:"=%
set WEAVIATE_PORT=%WEAVIATE_PORT: =%

echo Configuration loaded:
echo   LLM Model: %LLM_MODEL%
echo   LLM Port: %LLM_PORT%
echo   Backend Port: %BACKEND_PORT%
echo   Use Memory: %USE_MEMORY%

REM Check for port conflicts and find available ports
call :CheckPort %LLM_PORT% "LLM Server"
set LLM_PORT=%RESULT%

call :CheckPort %BACKEND_PORT% "Backend Server"
set BACKEND_PORT=%RESULT% 

REM Save port to a file that the VS Code extension can read
echo %BACKEND_PORT% > %TEMP%\vscode_ai_agent_port.txt

if "%USE_MEMORY%"=="true" (
    call :CheckPort %WEAVIATE_PORT% "Weaviate"
    set WEAVIATE_PORT=%RESULT%
)

REM Check if Docker is needed and running
if "%USE_MEMORY%"=="true" (
    docker --version >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Docker is not installed but memory integration is enabled.
        echo Please install Docker first or disable memory in config.yml.
        set "HAD_ERROR=1"
        goto :error_exit
    )
    
    docker info >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Docker is not running but memory integration is enabled.
        echo Please start Docker first or disable memory in config.yml.
        set "HAD_ERROR=1"
        goto :error_exit
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
        
        REM Check if we need to update the port in docker-compose.yml
        powershell -Command "(Get-Content docker-compose.yml) -replace '- \"[0-9]+:8080\"', '- \"%WEAVIATE_PORT%:8080\"' | Set-Content docker-compose.yml"
        
        docker-compose up -d
        
        echo Waiting for Weaviate to initialize (10 seconds)...
        timeout /t 10 /nobreak >nul
        
        docker ps | findstr "weaviate" >nul
        if %ERRORLEVEL% EQU 0 (
            echo Weaviate started successfully.
        ) else (
            echo Failed to start Weaviate.
            set "HAD_ERROR=1"
            goto :error_exit
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
    set "HAD_ERROR=1"
    goto :error_exit
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
    set "LLM_MODEL=%LLM_MODEL%"
    
    REM Start LLM server in a new window
    start "LLM Server" cmd /c "scripts\run_llama_server.bat < con: > logs\llm_server.log"
    
    echo Waiting for LLM server to start (10 seconds)...
    timeout /t 10 /nobreak >nul
    
    netstat -an | findstr ":%LLM_PORT%" >nul
    if %ERRORLEVEL% EQU 0 (
        echo LLM server started successfully.
        echo Log available at: logs\llm_server.log
    ) else (
        echo Failed to start LLM server.
        echo Check log for details: logs\llm_server.log
        type logs\llm_server.log
        set "HAD_ERROR=1"
        goto :error_exit
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
    
    echo Waiting for VS Code agent to start (10 seconds)...
    timeout /t 10 /nobreak >nul
    
    netstat -an | findstr ":%BACKEND_PORT%" >nul
    if %ERRORLEVEL% EQU 0 (
        echo VS Code agent started successfully.
    ) else (
        echo Failed to start VS Code agent.
        set "HAD_ERROR=1"
        goto :error_exit
    )
)

if "%HAD_ERROR%"=="0" (
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
    echo   - Code Chat (Ctrl+Shift+C)
    echo.
    echo To stop services, run: stop_all.bat
) else (
    :error_exit
    echo.
    echo ======================================================
    echo  Some services failed to start
    echo ======================================================
    echo.
    echo Please check the error messages above and logs for details.
    echo You can try to restart the service manually or check the documentation.
    echo.
    echo To stop all running services, run: stop_all.bat
    rem Commented out exit so script continues for debugging
    rem exit /b 1
)

exit /b 0 
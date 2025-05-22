@echo off
REM Start script for VS Code integration server
setlocal EnableDelayedExpansion

REM Set the base directory to the repository root
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%.."
cd "%BASE_DIR%"

REM Check if virtual environment exists, create if not
if not exist "venv" (
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
    timeout /t 5 /nobreak >nul
)

REM Check for command line arguments
set "PRODUCTION_MODE=false"
set "DEBUG_MODE=false"

:parseArgs
if "%~1"=="" goto :endArgs
if "%~1"=="--production" set "PRODUCTION_MODE=true"
if "%~1"=="--debug" set "DEBUG_MODE=true"
shift
goto :parseArgs
:endArgs

REM Set up log directory
set "LOG_DIR=%BASE_DIR%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Current date/time for log files
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,8%-%dt:~8,6%"

REM Set the agent port from environment variable if available
set "PORT_OPTION="
if defined VSCODE_AGENT_PORT (
    set "PORT_OPTION=--port %VSCODE_AGENT_PORT%"
)

REM Run the VS Code integration server
if "%PRODUCTION_MODE%"=="true" (
    echo Starting VS Code integration server in production mode...
    cd "%BASE_DIR%"
    start "VS Code Agent" /b cmd /c "python -m backend.vscode_integration --production %PORT_OPTION% > "%LOG_DIR%\vscode_server_%TIMESTAMP%.log" 2>&1"
    for /f "tokens=2" %%p in ('tasklist /fi "windowtitle eq VS Code Agent" /fo list ^| find "PID:"') do set PID=%%p
    echo Server started with PID: !PID! (Logs in %LOG_DIR%\vscode_server_%TIMESTAMP%.log)
) else if "%DEBUG_MODE%"=="true" (
    echo Starting VS Code integration server in debug mode...
    cd "%BASE_DIR%"
    python -m backend.vscode_integration --debug %PORT_OPTION%
) else (
    echo Starting VS Code integration server...
    cd "%BASE_DIR%"
    python backend\vscode_integration.py %PORT_OPTION%
)

REM If running in background, provide instructions to kill
if "%PRODUCTION_MODE%"=="true" (
    echo.
    echo To stop the server, run: taskkill /PID !PID! /F
    echo Or find the process with: tasklist | findstr "python"
)

exit /b 0 
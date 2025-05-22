@echo off
REM VS Code AI Dev Team - All-in-One Shutdown Script for Windows
REM This script stops all services started by start_all.bat

echo ======================================================
echo  VS Code AI Dev Team - All-in-One Shutdown
echo ======================================================
echo.

REM Parse config.yml for port numbers (basic implementation)
set LLM_PORT=8080
set BACKEND_PORT=5000
set USE_MEMORY=true

REM Simple config parser
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"port:" config.yml') do (
    echo %%a | findstr "llm" >nul && set LLM_PORT=%%b
    echo %%a | findstr "backend" >nul && set BACKEND_PORT=%%b
)
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"use_memory:" config.yml') do set USE_MEMORY=%%b

REM Remove quotes and spaces from values
set LLM_PORT=%LLM_PORT:"=%
set LLM_PORT=%LLM_PORT: =%
set BACKEND_PORT=%BACKEND_PORT:"=%
set BACKEND_PORT=%BACKEND_PORT: =%
set USE_MEMORY=%USE_MEMORY:"=%
set USE_MEMORY=%USE_MEMORY: =%

REM Stop LLM server
echo Stopping LLM server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%LLM_PORT%"') do (
    echo Found LLM server process: %%a
    taskkill /F /PID %%a
    if %ERRORLEVEL% EQU 0 (
        echo LLM server stopped successfully.
    ) else (
        echo Failed to stop LLM server.
    )
)

REM Stop VS Code agent
echo Stopping VS Code agent...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%BACKEND_PORT%"') do (
    echo Found VS Code agent process: %%a
    taskkill /F /PID %%a
    if %ERRORLEVEL% EQU 0 (
        echo VS Code agent stopped successfully.
    ) else (
        echo Failed to stop VS Code agent.
    )
)

REM Stop Weaviate
if "%USE_MEMORY%"=="true" (
    echo Stopping Weaviate...
    docker ps | findstr "weaviate" >nul
    if %ERRORLEVEL% EQU 0 (
        docker-compose down
        echo Weaviate stopped successfully.
    ) else (
        echo Weaviate is not running.
    )
)

echo.
echo ======================================================
echo  All services have been stopped.
echo ======================================================
echo.
echo To start services again, run: start_all.bat
echo ======================================================

pause 
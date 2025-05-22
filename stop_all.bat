@echo off
REM VS Code AI Dev Team - All-in-One Shutdown Script for Windows
REM This script stops all services started by start_all.bat
setlocal EnableDelayedExpansion

echo ======================================================
echo  VS Code AI Dev Team - All-in-One Shutdown
echo ======================================================
echo.

REM Function to check if a port is in use
:IsPortInUse
setlocal
netstat -an | findstr ":%~1 " | findstr "LISTENING" >nul
if %ERRORLEVEL% EQU 0 (
    endlocal & set "%~2=1"
) else (
    endlocal & set "%~2=0"
)
exit /b

REM Parse config.yml for port numbers (basic implementation)
set LLM_PORT=8081
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

echo Configuration loaded:
echo   LLM Port: %LLM_PORT%
echo   Backend Port: %BACKEND_PORT%
echo   Use Memory: %USE_MEMORY%

REM Stop LLM server
call :IsPortInUse %LLM_PORT% LLM_RUNNING
if "%LLM_RUNNING%"=="1" (
    echo Stopping LLM server on port %LLM_PORT%...
    
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%LLM_PORT%" ^| findstr "LISTENING"') do (
        echo Found LLM server process: %%a
        taskkill /F /PID %%a 2>nul

        if !ERRORLEVEL! EQU 0 (
            echo LLM server stopped successfully.
        ) else (
            echo Failed to stop LLM server process. You may need to stop it manually.
        )
    )
) else (
    echo LLM server is not running.
)

REM Stop VS Code agent
call :IsPortInUse %BACKEND_PORT% AGENT_RUNNING
if "%AGENT_RUNNING%"=="1" (
    echo Stopping VS Code agent on port %BACKEND_PORT%...
    
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%BACKEND_PORT%" ^| findstr "LISTENING"') do (
        echo Found VS Code agent process: %%a
        taskkill /F /PID %%a 2>nul

        if !ERRORLEVEL! EQU 0 (
            echo VS Code agent stopped successfully.
        ) else (
            echo Failed to stop VS Code agent process. You may need to stop it manually.
        )
    )
) else (
    echo VS Code agent is not running.
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

REM To keep the console window open, uncomment the next line:
REM pause 
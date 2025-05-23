@echo off
REM VS Code AI Dev Team - All-in-One Shutdown Script for Windows
REM This script stops all services started by start_all.bat
setlocal EnableDelayedExpansion

REM Set error tracking
set HAD_ERROR=0

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

REM Function to handle errors
:ErrorHandler
set HAD_ERROR=1
echo [ERROR] %~1
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

REM Load port information from the central location if available
set PORT_INFO_FILE=%TEMP%\ai-dev-team\ports.json
if exist "%PORT_INFO_FILE%" (
    echo Loading port information from %PORT_INFO_FILE%
    for /f "tokens=2 delims=:," %%a in ('findstr "weaviate_port" "%PORT_INFO_FILE%"') do set WEAVIATE_PORT=%%a
    for /f "tokens=2 delims=:}" %%a in ('findstr "weaviate_grpc_port" "%PORT_INFO_FILE%"') do set WEAVIATE_GRPC_PORT=%%a
    
    set WEAVIATE_PORT=%WEAVIATE_PORT: =%
    set WEAVIATE_GRPC_PORT=%WEAVIATE_GRPC_PORT: =%
    
    echo Using Weaviate port: %WEAVIATE_PORT%
)

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
            call :ErrorHandler "Failed to stop LLM server process"
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
            call :ErrorHandler "Failed to stop VS Code agent process"
        )
    )
) else (
    echo VS Code agent is not running.
)

REM Stop Weaviate
if "%USE_MEMORY%"=="true" (
    echo Stopping Weaviate...
    
    REM Check if Docker is available
    docker --version >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo Docker not available. Cannot check or stop Weaviate.
        call :ErrorHandler "Docker not available"
    ) else (
        REM Check if docker-compose.yml exists
        if not exist docker-compose.yml (
            echo docker-compose.yml not found.
            call :ErrorHandler "docker-compose.yml not found"
        ) else (
            docker ps | findstr "weaviate" >nul
            if %ERRORLEVEL% EQU 0 (
                docker-compose down
                if %ERRORLEVEL% EQU 0 (
                    echo Weaviate stopped successfully.
                ) else (
                    echo Failed to stop Weaviate.
                    call :ErrorHandler "Failed to stop Weaviate with docker-compose"
                )
            ) else (
                echo Weaviate is not running.
            )
        )
    )
)

REM Clean up temporary files
echo Cleaning up temporary files...

if exist "%TEMP%\ai-dev-team\llm_pipe" del "%TEMP%\ai-dev-team\llm_pipe" 2>nul
if exist "%TEMP%\ai-dev-team\ports.json" del "%TEMP%\ai-dev-team\ports.json" 2>nul
if exist "%TEMP%\vscode_ai_agent_port.txt" del "%TEMP%\vscode_ai_agent_port.txt" 2>nul

echo Temporary files cleaned up.

REM Final status
if "%HAD_ERROR%"=="0" (
    echo.
    echo ======================================================
    echo  All services have been stopped!
    echo ======================================================
    echo.
    echo To start services again, run: start_all.bat
    echo ======================================================
) else (
    echo.
    echo ======================================================
    echo  Some services may not have been stopped properly
    echo ======================================================
    echo.
    echo Please check the error messages above for details.
    echo You might need to manually stop some services.
    echo.
    echo To start services again, run: start_all.bat
    echo ======================================================
)

REM Keep the console window open
echo Terminal will remain open. Press any key to exit.
pause > nul 
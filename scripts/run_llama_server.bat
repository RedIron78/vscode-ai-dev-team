@echo off
REM Llama.cpp Server Launcher for AI Dev Team
setlocal EnableDelayedExpansion

REM Get script directory and set paths
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "MODELS_DIR=%PROJECT_ROOT%\models"

REM Default values - use environment variables if set, otherwise use defaults
if not defined LLM_MODEL set "MODEL_PATH="
if not defined LLM_HOST set "HOST=127.0.0.1"
if not defined LLM_PORT set "PORT=8081"
if not defined LLM_THREADS set "THREADS=4"
if not defined LLM_GPU_LAYERS set "GPU_LAYERS=35"
if not defined LLM_CONTEXT_SIZE set "CONTEXT_SIZE=2048"

REM Function to check if port is in use
:IsPortInUse
setlocal
netstat -an | findstr ":%~1 " | findstr "LISTENING" >nul
if %ERRORLEVEL% EQU 0 (
    endlocal & set "%~2=1"
) else (
    endlocal & set "%~2=0"
)
exit /b

REM Function to find available port
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

REM Check if port is in use and find alternative
call :IsPortInUse %PORT% PORT_USED
if "%PORT_USED%"=="1" (
    echo Warning: Port %PORT% is already in use.
    call :FindAvailablePort %PORT% NEW_PORT
    echo Using alternative port: !NEW_PORT!
    set "PORT=!NEW_PORT!"
)

REM Display banner
echo ======================================================
echo  Llama.cpp Server Launcher for AI Dev Team
echo ======================================================

REM Check for models in the models directory
if exist "%MODELS_DIR%" (
    echo Models found in %MODELS_DIR%:
    dir /b "%MODELS_DIR%\*.gguf" 2>nul || echo No .gguf models found.
    
    REM Try to find a GGUF model
    for /f "delims=" %%i in ('dir /b "%MODELS_DIR%\*.gguf" 2^>nul') do (
        set "MODEL_PATH=%MODELS_DIR%\%%i"
        echo Using model: !MODEL_PATH!
        goto :found_model
    )
) else (
    echo No models directory found at %MODELS_DIR%
    mkdir "%MODELS_DIR%" 2>nul
)

:found_model

REM Try to locate llama-server executable
set "LLAMA_SERVER_PATH="
if exist "%PROJECT_ROOT%\llama.cpp\build\bin\Release\server.exe" (
    set "LLAMA_SERVER_PATH=%PROJECT_ROOT%\llama.cpp\build\bin\Release\server.exe"
) else if exist "%PROJECT_ROOT%\llama.cpp\build\bin\server.exe" (
    set "LLAMA_SERVER_PATH=%PROJECT_ROOT%\llama.cpp\build\bin\server.exe"
) else if exist "%PROJECT_ROOT%\llama-server.exe" (
    set "LLAMA_SERVER_PATH=%PROJECT_ROOT%\llama-server.exe"
)

REM Check if llama.cpp is installed
if not defined LLAMA_SERVER_PATH (
    echo Error: llama-server executable not found!
    echo Please install llama.cpp from: https://github.com/ggerganov/llama.cpp
    echo.
    echo Quick setup (requires build tools):
    echo   git clone https://github.com/ggerganov/llama.cpp
    echo   cd llama.cpp
    echo   mkdir build
    echo   cd build
    echo   cmake .. -DGGML_CUDA=ON  # Use -DGGML_CUDA=OFF for CPU only
    echo   cmake --build . --config Release
    echo.
    echo Then download a .gguf model to the %MODELS_DIR% directory.
    echo You can find models at: https://huggingface.co/models?search=gguf
    exit /b 1
)

REM If no model was found, ask for path
if not defined MODEL_PATH (
    echo No .gguf model files found in %MODELS_DIR%
    set /p MODEL_PATH=Enter path to your .gguf model file: 
    
    if not exist "!MODEL_PATH!" (
        echo Error: Model file not found at: !MODEL_PATH!
        exit /b 1
    )
)

REM Allow user to specify CPU-only mode
set /p CPU_ONLY=Run on CPU only? (y/N): 
if /i "%CPU_ONLY%"=="y" (
    set "GPU_LAYERS=0"
    echo Running in CPU-only mode
)

echo Using model: %MODEL_PATH%
echo Using llama-server at: %LLAMA_SERVER_PATH%
echo Starting server on http://%HOST%:%PORT%
if %GPU_LAYERS% GTR 0 (
    echo GPU enabled with %GPU_LAYERS% layers offloaded to GPU
) else (
    echo Running in CPU-only mode
)
echo.
echo Press Ctrl+C to stop the server
echo ======================================================

REM Start the server
"%LLAMA_SERVER_PATH%" ^
    --model "%MODEL_PATH%" ^
    -c %CONTEXT_SIZE% ^
    --host %HOST% ^
    --port %PORT% ^
    -t %THREADS% ^
    --log-disable ^
    -ngl %GPU_LAYERS%

exit /b 0 
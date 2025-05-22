@echo off
REM VS Code AI Dev Team - Model Downloader
setlocal EnableDelayedExpansion

REM Get script directory and set paths
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "MODELS_DIR=%PROJECT_ROOT%\models"

REM Ensure models directory exists
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

echo =========================================================
echo      VS Code AI Dev Team - Model Downloader
echo =========================================================

REM List of popular models with their HuggingFace URLs
set "MODEL[1]=mistral-7b-instruct"
set "URL[1]=https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"

set "MODEL[2]=mistral-7b-instruct-v0.2"
set "URL[2]=https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"

set "MODEL[3]=llama2-7b"
set "URL[3]=https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf"

set "MODEL[4]=llama2-7b-chat"
set "URL[4]=https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf"

set "MODEL[5]=codellama-7b-instruct"
set "URL[5]=https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf"

set "MODEL[6]=phi-2"
set "URL[6]=https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"

set "MODEL[7]=openchat-3.5"
set "URL[7]=https://huggingface.co/TheBloke/openchat-3.5-0106-GGUF/resolve/main/openchat-3.5-0106.Q4_K_M.gguf"

REM Display available models
echo.
echo Available models:
for /L %%i in (1,1,7) do (
    echo %%i^) !MODEL[%%i]!
)
echo 8^) Custom URL

REM Get user choice
echo.
set /p choice=Enter the number of the model you want to download: 

REM Handle user choice
if %choice% geq 1 if %choice% leq 7 (
    REM Selected one of the pre-defined models
    echo.
    echo Selected model: !MODEL[%choice%]!
    set "MODEL_URL=!URL[%choice%]!"
    goto :download
) else if %choice% equ 8 (
    REM Custom URL option
    echo.
    set /p MODEL_URL=Enter the custom model URL: 
    
    echo %MODEL_URL% | findstr /i "^http:" >nul
    if !errorlevel! neq 0 (
        echo %MODEL_URL% | findstr /i "^https:" >nul
        if !errorlevel! neq 0 (
            echo Invalid URL format. URL must start with http:// or https://
            exit /b 1
        )
    )
    goto :download
) else (
    echo Invalid choice.
    exit /b 1
)

:download
REM Extract filename from URL
for %%a in ("%MODEL_URL%") do set "FILENAME=%%~nxa"

echo.
echo Downloading model to %MODELS_DIR%\%FILENAME%
echo This may take a while depending on your internet speed...

REM Download using PowerShell (available on all modern Windows versions)
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%MODEL_URL%' -OutFile '%MODELS_DIR%\%FILENAME%' }"

if %ERRORLEVEL% equ 0 (
    echo.
    echo Model downloaded successfully!
    echo Location: %MODELS_DIR%\%FILENAME%
) else (
    echo.
    echo Failed to download the model.
    exit /b 1
)

echo.
echo You can now use this model with the VS Code AI Dev Team.
echo Make sure to update your config.yml file with the model path:
echo   default_model: "models/%FILENAME%"

exit /b 0 
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
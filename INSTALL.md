# VS Code Extension Installation Guide

This document explains how to install and use the VS Code extension for the AI Dev Team agent.

## Prerequisites

1. VS Code installed on your system
2. Python 3.8+ with venv module
3. Required Python packages:
   - flask
   - waitress (for production deployment)
   - All other dependencies in the project

## Installation Steps

### 1. Install the Extension

There are two ways to install the extension:

#### Method 1: Install from VSIX file

1. Open VS Code
2. Go to Extensions panel (Ctrl+Shift+X)
3. Click the "..." menu in the top-right corner
4. Select "Install from VSIX..."
5. Navigate to the project root directory and select `vscode-ai-dev-team-0.1.0.vsix`

#### Method 2: Install using VS Code CLI

```bash
code --install-extension vscode-ai-dev-team-0.1.0.vsix
```

### 2. Configure the Extension

1. Open VS Code settings (File > Preferences > Settings)
2. Search for "AI Dev Team"
3. Configure the following settings:
   - **Agent API URL**: Default is `http://localhost:5000/api/agent`
   - **Auto Start Services**: Set to true to automatically start services when the extension activates
   - **Use Memory**: Enable/disable Weaviate memory integration
   - **LLM Model**: Select which LLM model to use

## Usage

### Starting the Agent Services

1. Open your project in VS Code
2. Open the Command Palette (Ctrl+Shift+P)
3. Type "AI Dev Team: Start Services" and select it
4. Wait for the services to initialize

Alternatively, run the agent server manually:

```bash
# For development
python vscode_integration.py --debug

# For production (with waitress)
python vscode_integration.py --production
```

### Using the AI Features

The extension provides several commands:

- **AI Dev Team: Ask AI** (Ctrl+Shift+A): Ask a general question
- **AI Dev Team: Explain Selected Code** (Ctrl+Shift+E): Get an explanation of selected code
- **AI Dev Team: Complete Code** (Ctrl+Shift+C): Get code completion suggestions
- **AI Dev Team: Improve Selected Code** (Ctrl+Shift+I): Get suggestions to improve selected code

## Troubleshooting

If you encounter issues:

1. Check the "VS Code Agent" output channel in VS Code
2. Verify that the agent server is running at http://localhost:5000
3. Check the terminal running the server for any error messages

## Development

To modify the extension:

1. Navigate to the vscode-extension directory
2. Make changes to the TypeScript files in src/
3. Compile with `npm run compile`
4. Package with `npm run package` 
# VS Code AI Dev Team Extension

This extension integrates an AI agent with vector memory into Visual Studio Code, providing intelligent code assistance, explanation, and completion capabilities.

## Features

- AI-powered code explanations
- Intelligent code completion
- Code improvement suggestions
- Chat with AI for project-related questions
- Vector memory for context-aware responses

## Installation and Setup

### Prerequisites

Before installing the extension, make sure you have:

- Python 3.8+ with venv module
- Node.js and npm
- Docker and docker-compose (for Weaviate vector database)
- Visual Studio Code

### Step 1: Set up the Project

First, run the setup script to organize the repository structure:

```bash
chmod +x setup_extension.sh
./setup_extension.sh
```

### Step 2: Install Dependencies

Run the installation script to set up all required components:

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

This script will:
- Create a Python virtual environment and install dependencies
- Install Node.js dependencies for the extension
- Start Weaviate in Docker (if Docker is installed)
- Create necessary directories for models and memory

### Step 3: Start the Backend Server

Start the VS Code integration server:

```bash
source venv/bin/activate
./scripts/start_vscode_agent.sh
```

The server will run at http://localhost:5000 and provide AI capabilities to the VS Code extension.

### Step 4: Build and Install the VS Code Extension

Build and package the extension:

```bash
cd extension
npm run compile
npm run package
```

Install the extension in VS Code:
1. Open VS Code
2. Go to Extensions panel (Ctrl+Shift+X)
3. Click "..." menu in the top-right corner
4. Select "Install from VSIX..."
5. Navigate to `extension/vscode-ai-dev-team-0.1.0.vsix` and select it

## Using the Extension

Once installed, you can use these keyboard shortcuts:

- **Ask AI**: `Ctrl+Shift+A` - Ask a general question about your code
- **Explain Code**: `Ctrl+Shift+E` - Get an explanation of selected code
- **Complete Code**: `Ctrl+Shift+C` - Get code completion suggestions
- **Improve Code**: `Ctrl+Shift+I` - Get suggestions to improve selected code

You can also access these features through the Command Palette (`Ctrl+Shift+P`):
- AI Dev Team: Ask AI
- AI Dev Team: Explain Selected Code
- AI Dev Team: Complete Code
- AI Dev Team: Improve Selected Code

## Troubleshooting

If you encounter issues:

1. Check the "VS Code Agent" output channel in VS Code
2. Verify that the agent server is running:
   ```bash
   ps aux | grep vscode_integration.py
   ```
3. Check that Weaviate is running:
   ```bash
   docker ps | grep weaviate
   ```
4. Restart the server if needed:
   ```bash
   ./scripts/start_vscode_agent.sh
   ```

## Project Structure

```
vscode-ai-dev-team/
├── extension/                 # VS Code extension code
│   ├── src/                   # TypeScript source
│   ├── resources/             # Extension resources
│   ├── package.json           # Extension manifest
│   └── ...                    # Other extension files
├── backend/                   # Python backend services
│   ├── agent_roles.py         # Agent definitions
│   ├── vscode_agent.py        # VS Code agent implementation
│   ├── vscode_integration.py  # API server for VS Code
│   ├── llm_interface.py       # LLM connection interface
│   └── requirements.txt       # Python dependencies
├── scripts/                   # Helper scripts
│   ├── install.sh             # Installation script
│   ├── start_vscode_agent.sh  # Start the agent server
│   └── run_llama_server.sh    # Run LLM server
└── docker-compose.yml         # Weaviate Docker compose file
``` 
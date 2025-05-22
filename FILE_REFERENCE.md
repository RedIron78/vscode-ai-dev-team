# VS Code AI Dev Team File Reference

This document explains the purpose and functionality of each file in the VS Code AI Dev Team project.

## Directory Structure Overview

```
vscode-ai-dev-team/
├── backend/                 # Python backend services
├── extension/               # VS Code extension (TypeScript)
├── llama.cpp/               # LLM inference engine
├── models/                  # LLM model storage
├── scripts/                 # Helper scripts
├── start_all.sh             # All-in-one starter script
├── stop_all.sh              # All-in-one stop script
└── docker-compose.yml       # Weaviate Docker configuration
```

## Core Files

### Root Directory

| File | Description |
|------|-------------|
| `README.md` | Project overview, installation, and usage instructions |
| `INSTALL.md` | Detailed installation guide for the VS Code extension |
| `DOCUMENTATION.md` | Comprehensive documentation including architecture, troubleshooting, and FAQs |
| `FILE_REFERENCE.md` | This file - documentation of all files in the project |
| `setup_extension.sh` | Script to organize the repository structure |
| `start_all.sh` | All-in-one script to start all required services |
| `stop_all.sh` | Script to stop all running services |
| `docker-compose.yml` | Docker Compose configuration for Weaviate vector database |
| `.gitignore` | Specifies files and directories to ignore in version control |

### Backend Directory (`backend/`)

| File | Description |
|------|-------------|
| `__init__.py` | Python package initializer |
| `agent_roles.py` | Defines specialized AI agents (frontend, backend, QA, DevOps) |
| `vscode_agent.py` | Core agent implementation for VS Code integration |
| `vscode_integration.py` | Flask server that connects VS Code to the AI agents |
| `llm_interface.py` | Interface to the LLM server (llama.cpp) |
| `requirements.txt` | Python package dependencies |

### Extension Directory (`extension/`)

| File | Description |
|------|-------------|
| `package.json` | Extension manifest with metadata, dependencies, and commands |
| `tsconfig.json` | TypeScript compiler configuration |
| `src/extension.ts` | Main extension entry point |
| `src/agent-services.ts` | Services for communicating with the Python backend |
| `src/test/runTest.ts` | Extension test runner |
| `.vscodeignore` | Files to exclude from the packaged extension |
| `LICENSE.txt` | License information |
| `ARCHITECTURE.md` | Technical architecture of the extension |
| `README.md` | Extension-specific readme |

### Scripts Directory (`scripts/`)

| File | Description |
|------|-------------|
| `install.sh` | Installation script for dependencies |
| `start_vscode_agent.sh` | Script to start the VS Code agent server |
| `run_llama_server.sh` | Script to run the LLM server |

### Models Directory (`models/`)

This directory stores the LLM models in GGUF format. It may include:

| File | Description |
|------|-------------|
| `*.gguf` | Quantized LLM models (e.g., Mistral, Llama, etc.) |

### llama.cpp Directory (`llama.cpp/`)

This is a subproject containing the llama.cpp repository. Key files include:

| File | Description |
|------|-------------|
| `build/bin/llama-server` | The built llama-server executable |
| `examples/server/README.md` | Documentation for the llama.cpp server |
| `CMakeLists.txt` | Build configuration for llama.cpp |

## Files Created During Setup

| File | Description |
|------|-------------|
| `venv/` | Python virtual environment |
| `memory/` | Directory for storing vector memory data |
| `logs/` | Log files for the various services |
| `extension/vscode-ai-dev-team-*.vsix` | Packaged VS Code extension |

## How Components Work Together

1. **VS Code Extension** (`extension/`) communicates with the Python backend via HTTP.
2. **Python Backend** (`backend/`) coordinates between VS Code and the LLM models.
3. **llama.cpp** provides LLM inference capabilities for the backend.
4. **Weaviate** (via `docker-compose.yml`) provides vector storage for memory.
5. **Scripts** help with installation, startup, and shutdown of services.

## File Dependencies

- `vscode_integration.py` depends on `vscode_agent.py` and `agent_roles.py`
- `vscode_agent.py` depends on `llm_interface.py`
- `extension.ts` depends on `agent-services.ts`
- `start_all.sh` depends on `scripts/run_llama_server.sh` and `scripts/start_vscode_agent.sh`
- `llm_interface.py` depends on the llama.cpp server running

## Building and Packaging

- The extension is built and packaged using Node.js and npm
- llama.cpp is built using CMake with CUDA support
- Backend uses Python virtualenv for dependency management
- Docker Compose is used for Weaviate

## Understanding the Model Files

The models directory should contain one or more GGUF format models. Examples:
- `mistral-7b-instruct-v0.2.Q4_K_M.gguf` - Mistral 7B Instruct model, quantized to 4-bit
- `openchat-3.5-0106.Q4_K_M.gguf` - OpenChat model, quantized to 4-bit

These models are loaded by the llama-server and used for AI code assistance. 
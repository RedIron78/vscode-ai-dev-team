# VS Code AI Dev Team

A VS Code extension that provides an AI coding assistant powered by local Large Language Models. Bring the power of AI into your development workflow while keeping all your code and data private and secure on your own machine.

![VS Code AI Dev Team Banner](https://i.imgur.com/DsRhFQh.png)

## Features

- 🤖 **Local AI Coding Assistant**: Run powerful Large Language Models on your own machine
- 🧠 **Contextual Memory**: The AI remembers your project structure and previous conversations
- 🔍 **Code Explanations**: Get explanations for complex code snippets
- ✨ **Code Improvements**: Receive suggestions to improve your code
- 📝 **Code Completion**: Get context-aware code completions
- 🔒 **Privacy-Focused**: All processing happens locally - your code never leaves your computer
- ⚙️ **Fully Configurable**: Easy configuration via simple YAML file
- 🔌 **Plug and Play**: One-click installation and startup

## Complete Documentation

For detailed installation instructions, usage guide, and troubleshooting:

- [Complete Guide (Markdown)](./COMPLETE-GUIDE.md)
- [File Reference](./FILE_REFERENCE.md)

## Quick Start

### One-Click Installation

We provide simple one-click installers for all platforms:

```bash
# Linux/macOS
./install.sh

# Windows
install.bat
```

The installer will set up everything you need, including:
- Checking system requirements
- Installing dependencies
- Building llama.cpp with appropriate GPU optimizations
- Setting up the VS Code extension
- Configuring the system for optimal performance

### Starting the Extension

Once installed, start using the extension with these simple steps:

1. Start the backend services:
   ```bash
   ./start_all.sh  # Linux/macOS
   start_all.bat   # Windows
   ```

2. Open VS Code and access AI features via:
   - Command Palette (Ctrl+Shift+P or ⌘+Shift+P)
   - Type "AI Dev Team" to see available commands

3. Try these commands:
   - **Ask AI** (Ctrl+Shift+A): Ask questions about coding
   - **Explain Selected Code** (Ctrl+Shift+E): Get explanations
   - **Complete Code** (Ctrl+Shift+C): Get code completion suggestions
   - **Improve Selected Code** (Ctrl+Shift+I): Get improvement suggestions

## Configuration

The extension is fully configurable through the `config.yml` file in the root directory:

```yaml
# Sample configuration (partial)
llm:
  default_model: "models/Mistral-7B-Instruct-v0.2.Q4_K_M.gguf"
  host: "127.0.0.1"
  port: 8080
  gpu_layers: 35  # Number of layers to offload to GPU

backend:
  host: "127.0.0.1"
  port: 5000
  use_memory: true  # Set to false to disable Weaviate integration
```

See [Complete Guide](./COMPLETE-GUIDE.md#configuration) for all configuration options.

## System Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: 5GB for minimal installation
- **GPU**: Optional but recommended for faster performance
  - NVIDIA GPU with CUDA support (for NVIDIA users)
  - Apple Silicon M1/M2/M3 (optimized for Mac users)

## Models

The extension works with any GGUF model. We provide easy model download functionality:

```bash
# Download a model interactively
./scripts/download_model.sh
```

Or choose from our recommended models for different system capabilities:

### Entry-Level Systems (2-4GB RAM, Integrated Graphics)
- **[TinyLlama-1.1B-Chat-v1.0 (Q4_K_M)](https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf)** (1.1GB)
  - Perfect for systems with limited resources
  - Works well on laptops with integrated graphics
  - Fast responses, but less capable than larger models
  - Memory usage: ~2GB RAM

### Mid-Range Systems (8-16GB RAM, Basic GPU)
- **[Mistral-7B-Instruct-v0.2 (Q5_K_M)](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q5_K_M.gguf)** (5.3GB)
  - Great balance between quality and resource usage
  - Excellent code understanding and generation
  - Memory usage: ~8GB RAM
  - Recommended for most users

### High-End Systems (16GB+ RAM, Dedicated GPU)
- **[Mixtral-8x7B-Instruct-v0.1 (Q4_K_M)](https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf)** (13.4GB)
  - State-of-the-art code understanding and generation
  - Excellent reasoning and problem-solving
  - Memory usage: ~24GB RAM
  - Requires a powerful GPU with 8GB+ VRAM for good performance

## Architecture

The VS Code AI Dev Team extension consists of several components:

1. **VS Code Extension**: TypeScript extension integrating with VS Code
2. **Python Backend**: Coordinates between VS Code and the AI
3. **LLM Server**: Local large language model running via llama.cpp
4. **Weaviate**: Vector database for storing project knowledge (optional)

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   VS Code       │    │   Python        │    │   LLM           │
│   Extension     │◄───┤   Backend       │◄───┤   Server        │
│   (TypeScript)  │    │   (Flask)       │    │   (llama.cpp)   │
│                 │    │                 │    │                 │
└─────────────────┘    └───────┬─────────┘    └─────────────────┘
                               │
                               ▼
                       ┌─────────────────┐
                       │                 │
                       │   Weaviate      │
                       │   Vector DB     │
                       │   (Docker)      │
                       │   (Optional)    │
                       └─────────────────┘
```

## Extensibility

The extension is designed to be easily extensible:

1. **Custom Models**: Any GGUF model can be used
2. **Configuration**: All components are configurable via `config.yml`
3. **Scripts**: Modular scripts in the `scripts/` directory
4. **Open Architecture**: Each component can be replaced or extended

## Stopping the Services

When you're done, stop all services:

```bash
./stop_all.sh    # Linux/macOS
stop_all.bat     # Windows
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [llama.cpp](https://github.com/ggerganov/llama.cpp) for the efficient LLM inference
- [Weaviate](https://weaviate.io/) for the vector database
- [All contributors](https://github.com/YOUR-USERNAME/vscode-ai-dev-team/graphs/contributors)

---

Made with ❤️ for developers who want AI assistance without sacrificing privacy or performance. 
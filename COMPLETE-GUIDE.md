# VS Code AI Dev Team - Complete Guide

![VS Code AI Dev Team Banner](https://i.imgur.com/DsRhFQh.png)

**Version 1.2.0**

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [System Requirements](#system-requirements)
4. [Model Selection Guide](#model-selection-guide)
5. [Installation Guide](#installation-guide)
   - [One-Click Installation](#one-click-installation)
   - [Linux Installation (Manual)](#linux-installation-manual)
   - [Windows Installation (Manual)](#windows-installation-manual)
   - [macOS Installation (Manual)](#macos-installation-manual)
6. [Configuration](#configuration)
7. [Using the Extension](#using-the-extension)
   - [Commands](#commands)
   - [Tips for Best Results](#tips-for-best-results)
8. [Advanced Features](#advanced-features)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)

## Introduction

The VS Code AI Dev Team extension brings the power of local Large Language Models (LLMs) directly into your VS Code environment. Unlike cloud-based AI coding assistants, this extension runs entirely on your machine, providing complete privacy and control over your code and the AI models used.

With this extension, you can have an AI coding assistant that:
- Explains code in plain language
- Suggests improvements to your code
- Provides context-aware code completions
- Answers programming questions
- Remembers your project context through conversations

All of this happens locally on your own machine - your code never leaves your computer!

## Features

- 🤖 **Local AI Coding Assistant**: Run powerful Large Language Models on your own machine
- 🧠 **Contextual Memory**: The AI remembers your project structure and previous conversations
- 🔍 **Code Explanations**: Get explanations for complex code snippets
- ✨ **Code Improvements**: Receive suggestions to improve your code
- 📝 **Code Completion**: Get context-aware code completions
- 🔒 **Privacy-Focused**: All processing happens locally - your code never leaves your computer
- ⚙️ **Fully Configurable**: Easy configuration via simple YAML file
- 🔌 **Cross-Platform**: Full support for Windows, Linux, and macOS
- 🛠️ **Smart Port Management**: Automatic port conflict detection and resolution

## System Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: 5GB for minimal installation
- **GPU**: Optional but recommended for faster performance
  - NVIDIA GPU with CUDA support (for NVIDIA users)
  - Apple Silicon M1/M2/M3 (optimized for Mac users)

## Model Selection Guide

The extension works with any GGUF model. We provide an easy model downloader and direct links for models tailored to different system capabilities:

### Interactive Model Downloader

The easiest way to get models is using our interactive downloader script:

```bash
# On Linux/macOS
./scripts/download_model.sh

# On Windows
scripts\download_model.bat
```

This script will present you with a list of optimized models and download your selection directly to the models directory.

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

## Installation Guide

We now offer a simplified one-click installation method as well as the detailed manual installation instructions for advanced users.

### One-Click Installation

The easiest way to install is using our one-click installer:

#### Linux/macOS

1. Open a terminal
2. Clone the repository:
   ```bash
   git clone https://github.com/YOUR-USERNAME/vscode-ai-dev-team.git
   cd vscode-ai-dev-team
   ```
3. Run the installer:
   ```bash
   ./install.sh
   ```

This script will automatically:
- Check your system requirements
- Install all dependencies
- Set up Python virtual environment
- Build the VS Code extension
- Clone and build llama.cpp with GPU support (if available)
- Create necessary directories
- Make all scripts executable

#### Windows

1. Open Command Prompt or PowerShell
2. Clone the repository:
   ```cmd
   git clone https://github.com/YOUR-USERNAME/vscode-ai-dev-team.git
   cd vscode-ai-dev-team
   ```
3. Run the installer:
   ```cmd
   install.bat
   ```

This script performs the same steps as the Linux/macOS installer but adapted for Windows environments.

### Linux Installation (Manual)

Follow these steps to install the VS Code AI Dev Team extension on Linux manually:

#### Step 1: Install Required Software

First, we need to install some programs that our AI assistant needs to work.

Open a Terminal window (usually by pressing `Ctrl+Alt+T` or finding "Terminal" in your applications menu).

##### Install Python

Most Linux distributions come with Python, but let's make sure we have the right version:

```bash
python3 --version
```

If the version is 3.8 or higher, you're good! If not, install it:

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

> If you're using Fedora or another non-Debian distribution, use `dnf` or your system's package manager instead of `apt`.

##### Install Git

Git helps us download the code:

```bash
sudo apt install git
```

##### Install Node.js and npm

This is needed for the VS Code extension:

```bash
sudo apt install nodejs npm
```

##### Install Docker and Docker Compose

Docker is used for the vector database:

```bash
# Install Docker
sudo apt install docker.io

# Install Docker Compose
sudo apt install docker-compose

# Start Docker and enable it to start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to the docker group so you can run Docker without sudo
sudo usermod -aG docker $USER
```

> **Important**: After running these commands, you need to log out and log back in for the docker group changes to take effect.

##### Install Build Tools

These are needed to build llama.cpp:

```bash
sudo apt install build-essential cmake
```

##### Install VS Code

If you don't have VS Code installed:

```bash
sudo apt install software-properties-common apt-transport-https wget
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install code
```

##### Install CUDA (for NVIDIA GPU users only)

If you have an NVIDIA GPU and want to use it to run the AI models faster:

1. Check if you have an NVIDIA GPU:
   ```bash
   lspci | grep -i nvidia
   ```

2. If you see a NVIDIA GPU listed, install CUDA:
   ```bash
   sudo apt install nvidia-cuda-toolkit
   ```

3. Verify CUDA installation:
   ```bash
   nvcc --version
   ```

#### Step 2: Download the VS Code AI Dev Team Code

Now let's get the code:

```bash
# Go to your home directory
cd ~

# Clone the repository
git clone https://github.com/YOUR-USERNAME/vscode-ai-dev-team.git

# Go into the project directory
cd vscode-ai-dev-team
```

#### Step 3: Setup the Extension

Let's run the setup script:

```bash
# Make the script executable
chmod +x setup_extension.sh

# Run the setup script
./setup_extension.sh
```

You should see a message saying "Setup complete!" when it's done.

#### Step 4: Install Dependencies

Next, let's install all the required packages:

```bash
# Make the install script executable
chmod +x scripts/install.sh

# Run the install script
./scripts/install.sh
```

This will:
- Create a Python virtual environment
- Install Python packages
- Install Node.js packages for the extension
- Start Weaviate in Docker
- Create necessary directories

#### Step 5: Build llama.cpp with GPU Support

Now, let's build llama.cpp to run AI models:

```bash
# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp

# Go into the llama.cpp directory
cd llama.cpp

# Create a build directory and go into it
mkdir -p build && cd build

# Configure the build with CUDA support (if you have an NVIDIA GPU)
# If you don't have an NVIDIA GPU, use -DGGML_CUDA=OFF instead
cmake .. -DGGML_CUDA=ON

# Build llama.cpp
cmake --build . --config Release

# Go back to the project root
cd ../..
```

#### Step 6: Download an AI Model

Choose a model that best fits your system (see the [Model Selection Guide](#model-selection-guide) above):

```bash
# Create the models directory if it doesn't exist
mkdir -p models
cd models

# Download your chosen model (example for mid-range systems)
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q5_K_M.gguf

# Go back to the project root
cd ..
```

After downloading your chosen model, update the model path in `scripts/run_llama_server.sh` to point to your downloaded model.

#### Step 7: Build and Install the VS Code Extension

Now let's build the VS Code extension:

```bash
# Go to the extension directory
cd extension

# Compile the extension
npm run compile

# Package the extension
npm run package

# Go back to the project root
cd ..
```

This will create a file named `vscode-ai-dev-team-0.1.0.vsix` in the extension directory.

#### Step 8: Make the Start and Stop Scripts Executable

```bash
chmod +x start_all.sh
chmod +x stop_all.sh
```

#### Step 9: Start All Services

Let's start everything:

```bash
./start_all.sh
```

This will:
- Start the Weaviate database
- Start the llama.cpp server with your model
- Start the VS Code agent

You should see green checkmarks (✅) for each service that starts successfully.

#### Step 10: Install the Extension in VS Code

1. Open VS Code
2. Click on the Extensions icon in the sidebar (or press `Ctrl+Shift+X`)
3. Click the "..." menu in the top-right corner of the Extensions panel
4. Select "Install from VSIX..."
5. Navigate to `~/vscode-ai-dev-team/extension/vscode-ai-dev-team-0.1.0.vsix` and select it
6. Click "Install"

### Windows Installation (Manual)

Follow these steps to install the VS Code AI Dev Team extension on Windows manually:

#### Step 1: Install Required Software

First, we need to install some programs that our AI assistant needs to work.

##### Install Python

1. Visit the [Python website](https://www.python.org/downloads/windows/)
2. Click the "Download Python 3.10" button (or newer version)
3. Run the installer
4. **IMPORTANT**: Check the box that says "Add Python to PATH"
5. Click "Install Now"

##### Install Git

1. Visit the [Git website](https://git-scm.com/download/win)
2. The download should start automatically
3. Run the installer
4. Click "Next" through the installation with default options
5. Click "Install"

##### Install Node.js and npm

1. Visit the [Node.js website](https://nodejs.org/)
2. Download the "LTS" (Long Term Support) version
3. Run the installer
4. Click through with default options
5. Click "Install"

##### Install Visual Studio Code

1. Visit the [VS Code website](https://code.visualstudio.com/)
2. Click "Download for Windows"
3. Run the installer
4. Click through with default options
5. Click "Install"

##### Install Docker Desktop

Docker is used for the vector database:

1. Visit the [Docker Desktop website](https://www.docker.com/products/docker-desktop/)
2. Click "Download for Windows"
3. Run the installer
4. Follow the installation instructions
5. Restart your computer if prompted

> **Note**: Docker Desktop requires Windows 10 or 11 with Hyper-V enabled or WSL 2 installed.

##### Install Visual Studio Build Tools (for C++ compilation)

1. Visit the [Visual Studio Build Tools page](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Click "Download Build Tools"
3. Run the installer
4. Select "Desktop development with C++"
5. Click "Install"

##### Install CUDA (for NVIDIA GPU users only)

If you have an NVIDIA GPU and want to use it to run the AI models faster:

1. Visit the [NVIDIA CUDA download page](https://developer.nvidia.com/cuda-downloads)
2. Select "Windows" and your Windows version
3. Choose "exe (local)" installer type
4. Download and run the installer
5. Follow the installation instructions

#### Step 2: Download the VS Code AI Dev Team Code

1. Open Command Prompt
   - Press Windows key
   - Type "cmd"
   - Click "Command Prompt"

2. Navigate to where you want to download the code (e.g., Documents folder):
   ```cmd
   cd %USERPROFILE%\Documents
   ```

3. Clone the repository:
   ```cmd
   git clone https://github.com/YOUR-USERNAME/vscode-ai-dev-team.git
   ```

4. Go into the project directory:
   ```cmd
   cd vscode-ai-dev-team
   ```

#### Step 3: Setup the Extension

Let's run the setup script:

```cmd
setup_extension.bat
```

You should see a message saying "Setup complete!" when it's done.

#### Step 4: Install Dependencies

Next, let's install all the required packages:

```cmd
scripts\install.bat
```

This will:
- Create a Python virtual environment
- Install Python packages
- Install Node.js packages for the extension
- Start Weaviate in Docker
- Create necessary directories

#### Step 5: Build llama.cpp with GPU Support

Now, let's build llama.cpp to run AI models:

```cmd
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
mkdir build
cd build
```

If you have an NVIDIA GPU:
```cmd
cmake .. -DGGML_CUDA=ON
```

If you don't have an NVIDIA GPU:
```cmd
cmake ..
```

Then build it:
```cmd
cmake --build . --config Release
cd ..\..
```

#### Step 6: Download an AI Model

Choose a model that best fits your system (see the [Model Selection Guide](#model-selection-guide) above):

```cmd
mkdir models
cd models

# Download your chosen model (example for mid-range systems)
curl -L -o mistral-7b-instruct-v0.2.Q5_K_M.gguf https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q5_K_M.gguf

cd ..
```

After downloading your chosen model, update the model path in `scripts\run_llama_server.bat` to point to your downloaded model.

#### Step 7: Build and Install the VS Code Extension

Now let's build the VS Code extension:

```cmd
cd extension
npm run compile
npm run package
cd ..
```

This will create a file named `vscode-ai-dev-team-0.1.0.vsix` in the extension directory.

#### Step 8: Start All Services

Let's start everything:

```cmd
start_all.bat
```

This will:
- Start the Weaviate database
- Start the llama.cpp server with your model
- Start the VS Code agent

You should see success messages for each service that starts correctly.

#### Step 9: Install the Extension in VS Code

1. Open VS Code
2. Click on the Extensions icon in the sidebar (or press `Ctrl+Shift+X`)
3. Click the "..." menu in the top-right corner of the Extensions panel
4. Select "Install from VSIX..."
5. Navigate to your project folder, then the "extension" folder, select `vscode-ai-dev-team-0.1.0.vsix`
6. Click "Install"

### macOS Installation (Manual)

Follow these steps to install the VS Code AI Dev Team extension on macOS manually:

#### Step 1: Install Required Software

First, we need to install some programs that our AI assistant needs to work.

##### Install Homebrew

Homebrew is a package manager for macOS that makes it easy to install software. Open Terminal (you can find it in Applications > Utilities > Terminal) and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the prompts on the screen. After installation, follow the instructions shown to add Homebrew to your PATH.

##### Install Python

Install Python using Homebrew:

```bash
brew install python@3.10
```

Verify the installation:

```bash
python3 --version
```

You should see something like `Python 3.10.x`.

##### Install Git

Git helps us download the code:

```bash
brew install git
```

##### Install Node.js and npm

This is needed for the VS Code extension:

```bash
brew install node
```

##### Install Docker Desktop

Docker is used for the vector database:

1. Visit the [Docker Desktop for Mac website](https://www.docker.com/products/docker-desktop)
2. Click "Download for Mac"
3. Run the installer
4. Drag Docker to your Applications folder
5. Open Docker from your Applications folder
6. Wait for Docker to start (you'll see a whale icon in your menu bar)

##### Install VS Code

If you don't have VS Code installed:

1. Visit the [VS Code website](https://code.visualstudio.com/)
2. Click "Download for Mac"
3. Open the downloaded zip file
4. Drag Visual Studio Code to your Applications folder
5. Open Visual Studio Code from your Applications folder

##### Install Build Tools

These are needed to build llama.cpp:

```bash
brew install cmake
```

#### Step 2: Download the VS Code AI Dev Team Code

Now let's get the code:

```bash
# Go to your home directory
cd ~

# Clone the repository
git clone https://github.com/YOUR-USERNAME/vscode-ai-dev-team.git

# Go into the project directory
cd vscode-ai-dev-team
```

#### Step 3: Setup the Extension

Let's run the setup script:

```bash
# Make the script executable
chmod +x setup_extension.sh

# Run the setup script
./setup_extension.sh
```

You should see a message saying "Setup complete!" when it's done.

#### Step 4: Install Dependencies

Next, let's install all the required packages:

```bash
# Make the install script executable
chmod +x scripts/install.sh

# Run the install script
./scripts/install.sh
```

This will:
- Create a Python virtual environment
- Install Python packages
- Install Node.js packages for the extension
- Start Weaviate in Docker
- Create necessary directories

#### Step 5: Build llama.cpp

Now, let's build llama.cpp to run AI models:

```bash
# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp

# Go into the llama.cpp directory
cd llama.cpp

# Create a build directory and go into it
mkdir -p build && cd build

# Configure the build
# For Apple Silicon (M1/M2/M3):
cmake .. -DCMAKE_C_FLAGS="-O3 -mcpu=apple-m1" -DCMAKE_CXX_FLAGS="-O3 -mcpu=apple-m1"

# For Intel Macs:
# cmake .. 

# Build llama.cpp
cmake --build . --config Release

# Go back to the project root
cd ../..
```

#### Step 6: Download an AI Model

Choose a model that best fits your system (see the [Model Selection Guide](#model-selection-guide) above):

```bash
# Create the models directory if it doesn't exist
mkdir -p models
cd models

# Download your chosen model (example for mid-range systems)
curl -L -o mistral-7b-instruct-v0.2.Q5_K_M.gguf https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q5_K_M.gguf

# Go back to the project root
cd ..
```

After downloading your chosen model, update the model path in `scripts/run_llama_server.sh` to point to your downloaded model.

#### Step 7: Build and Install the VS Code Extension

Now let's build the VS Code extension:

```bash
# Go to the extension directory
cd extension

# Install dependencies
npm install

# Compile the extension
npm run compile

# Package the extension
npm run package

# Go back to the project root
cd ..
```

This will create a file named `vscode-ai-dev-team-0.1.0.vsix` in the extension directory.

#### Step 8: Make the Start and Stop Scripts Executable

```bash
chmod +x start_all.sh
chmod +x stop_all.sh
```

#### Step 9: Start All Services

Let's start everything:

```bash
./start_all.sh
```

This will:
- Start the Weaviate database
- Start the llama.cpp server with your model
- Start the VS Code agent

You should see green checkmarks (✅) for each service that starts successfully.

#### Step 10: Install the Extension in VS Code

1. Open VS Code
2. Click on the Extensions icon in the sidebar (or press `⌘+Shift+X`)
3. Click the "..." menu in the top-right corner of the Extensions panel
4. Select "Install from VSIX..."
5. Navigate to `~/vscode-ai-dev-team/extension/vscode-ai-dev-team-0.1.0.vsix` and select it
6. Click "Install"

## Configuration

The VS Code AI Dev Team extension uses a simple YAML configuration file (`config.yml`) in the project root directory to control all aspects of its behavior.

### Default Configuration

If no configuration file exists, a default one will be created automatically when you start the services. Here's what the default configuration looks like:

```yaml
# VS Code AI Dev Team Configuration

# LLM Server Configuration
llm:
  # Default model to use
  default_model: "models/Mistral-7B-Instruct-v0.2.Q4_K_M.gguf"
  # Server host
  host: "127.0.0.1"
  # Server port
  port: 8080
  # Number of CPU threads (0 = auto)
  threads: 0
  # Context size
  context_size: 4096
  # GPU layers (0 = CPU only)
  gpu_layers: 35
  # Temperature (higher = more creative, lower = more deterministic)
  temperature: 0.7
  # Additional model parameters
  extra_params: ""

# Python Backend Configuration
backend:
  # Host for the Flask backend
  host: "127.0.0.1"
  # Port for the Flask backend
  port: 5000
  # Debug mode (true/false)
  debug: false
  # Memory integration (true/false)
  use_memory: true

# Weaviate Configuration
weaviate:
  # Host
  host: "localhost"
  # Port
  port: 8090
  # Schema name
  schema_name: "VSCodeAssistant"
  # Class name
  class_name: "Memory"
```

### Common Configuration Changes

Here are some common configuration changes you might want to make:

1. **Using a different model**:
   ```yaml
   llm:
     default_model: "models/YOUR-MODEL-NAME.gguf"
   ```

2. **Disabling memory to run without Docker**:
   ```yaml
   backend:
     use_memory: false
   ```

3. **Adjusting GPU usage** (higher values use more GPU memory but are faster):
   ```yaml
   llm:
     gpu_layers: 50  # Increase for more GPU usage
   ```

4. **Changing inference temperature** (higher values = more creative, lower = more deterministic):
   ```yaml
   llm:
     temperature: 0.5  # Lower for more deterministic responses
   ```

## Using the Extension

### Starting the Services

Before using the extension, you need to start the backend services:

1. Open a terminal and navigate to the project directory
2. Run `./start_all.sh` (Linux/macOS) or `start_all.bat` (Windows)
3. Wait for all services to start successfully

The start script will:
- Read settings from `config.yml`
- Check if Docker is running (if memory integration is enabled)
- Start Weaviate (if memory integration is enabled)
- Start the LLM server with your configured model
- Start the VS Code backend agent

### Accessing Commands

After starting the services, you can access the extension features through VS Code commands:

1. Press `Ctrl+Shift+P` (Windows/Linux) or `⌘+Shift+P` (macOS) to open the Command Palette
2. Type "AI Dev Team" to see available commands
3. Select the command you want to use

### Commands

The VS Code AI Dev Team extension provides several powerful commands:

#### Ask AI
**Command**: `AI Dev Team: Ask AI`  
**Shortcut**: `Ctrl+Shift+A` (Windows/Linux) or `⌘+Shift+A` (macOS)

This command lets you ask any question to the AI assistant. It's perfect for general questions about programming, technologies, or concepts.

**Example uses**:
- "How do I convert a string to an integer in Python?"
- "Explain how React hooks work"
- "What's the difference between var, let, and const in JavaScript?"

#### Explain Selected Code
**Command**: `AI Dev Team: Explain Selected Code`  
**Shortcut**: `Ctrl+Shift+E` (Windows/Linux) or `⌘+Shift+E` (macOS)

Select some code in your editor, then use this command to get an explanation of what the code does.

**How to use**:
1. Select code in your editor
2. Run the command
3. The AI will explain what the selected code does

#### Complete Code
**Command**: `AI Dev Team: Complete Code`  
**Shortcut**: `Ctrl+Shift+C` (Windows/Linux) or `⌘+Shift+C` (macOS)

Get code completion suggestions for your current code. This is useful when you're not sure how to finish a function or implement a feature.

**How to use**:
1. Place your cursor where you want code to be completed
2. Run the command
3. The AI will suggest code to complete what you're working on

#### Improve Selected Code
**Command**: `AI Dev Team: Improve Selected Code`  
**Shortcut**: `Ctrl+Shift+I` (Windows/Linux) or `⌘+Shift+I` (macOS)

Select code that you want to improve, then use this command to get suggestions on how to make it better, more efficient, or more readable.

**How to use**:
1. Select code in your editor
2. Run the command
3. The AI will suggest improvements to the selected code

### Tips for Best Results

For the best experience with the AI Dev Team extension:

1. **Ask specific questions** rather than vague ones
2. **Provide context** when asking about your code
3. **Use the right command** for your task (explain, complete, improve)
4. **Start with small models** if you have limited RAM
5. **Keep services running** while you work to avoid restart delays

## Advanced Features

### Memory Integration

The extension uses Weaviate as a vector database to remember previous conversations. This means the AI can reference things you've discussed before to provide more relevant answers.

You can disable memory integration in `config.yml` if you don't want to use Docker or prefer not to keep conversation history:

```yaml
backend:
  use_memory: false
```

To clear the memory:
1. Stop all services using `./stop_all.sh` (Linux/macOS) or `stop_all.bat` (Windows)
2. Run `docker-compose down -v` in the project directory
3. Start the services again

### Custom Models

You can use different AI models with the extension in two ways:

1. **Interactive downloader**:
   Run `./scripts/download_model.sh` and follow the prompts

2. **Manual download**:
   - Download a GGUF model from [Hugging Face](https://huggingface.co/models?library=gguf)
   - Place it in the `models` directory
   - Update the model path in `config.yml`:
     ```yaml
     llm:
       default_model: "models/YOUR-MODEL-NAME.gguf"
     ```

### GPU Acceleration

If you have a compatible GPU, the extension can use it to run models faster:

- **NVIDIA GPUs**: Automatic detection and CUDA support during installation
- **AMD GPUs**: Currently limited support through ROCm
- **Apple Silicon**: Uses optimized Metal API automatically on M1/M2/M3 Macs

You can adjust GPU usage in `config.yml`:
```yaml
llm:
  gpu_layers: 35  # Higher value uses more GPU, lower uses more CPU
```

## Automatic Port Conflict Detection and Resolution

The extension now includes automatic port conflict detection and resolution in all scripts. If any of the default ports (8081 for LLM, 5000 for backend, 8090 for Weaviate) are already in use, the system will:

1. Detect the conflict automatically
2. Find an available port
3. Update the configuration
4. Start the service on the new port
5. Ensure all components communicate correctly

This means you no longer need to manually change ports or stop other services - the system handles it all automatically.

Example from the logs when a port conflict is detected:
```
⚠️ Port 8081 is already in use.
✅ Found available port: 8082
✅ Updated config.yml with new port
✅ Starting llama.cpp server on port 8082
```

## Cross-Platform Compatibility

All scripts and commands now have full cross-platform compatibility, ensuring the extension works identically on:

- Windows (using .bat scripts)
- Linux (using .sh scripts)
- macOS (using .sh scripts)

The following scripts are available in both bash (.sh) and batch (.bat) versions:

- `install.{sh,bat}` - Install all dependencies
- `start_all.{sh,bat}` - Start all services
- `stop_all.{sh,bat}` - Stop all services
- `run_tests.{sh,bat}` - Run automated tests
- `scripts/download_model.{sh,bat}` - Download LLM models
- `scripts/start_vscode_agent.{sh,bat}` - Start the VS Code agent
- `scripts/run_llama_server.{sh,bat}` - Start the LLM server
- `scripts/run_tests.{sh,bat}` - Test the scripts

All scripts maintain consistent functionality and user experience across platforms, allowing for seamless workflow regardless of operating system.

## Testing

To run the automated test suite:

```bash
# On Linux/macOS
./run_tests.sh

# On Windows
run_tests.bat
```

This will run a comprehensive test suite that checks:
- Configuration validation
- Service startup and status
- Port availability and conflict resolution
- LLM query functionality
- Code completion functionality
- VS Code extension integration

Test results are saved to the `test_results` directory with detailed logs and an HTML report.

## FAQ

### Q: Can I use the extension offline?
A: Yes, once installed and with a model downloaded, the extension can work without an internet connection.

### Q: How much RAM do I need?
A: It depends on the model size:
- TinyLlama-1.1B: ~2GB RAM
- Mistral-7B: ~8GB RAM
- Llama-2-13B: ~16GB RAM
- Mixtral-8x7B: ~24GB RAM

### Q: Does it support code in all programming languages?
A: Yes, but performance may vary depending on the model's training data. Most models work best with popular languages like Python, JavaScript, Java, C++, etc.

### Q: Will the AI replace my job?
A: No, the AI is designed to be a helpful assistant, not a replacement for human developers. It's best used as a tool to enhance your productivity, explain complex code, and help you learn new concepts.

### Q: Can I create my own custom commands?
A: Advanced users can modify the extension code to add custom commands, but this requires TypeScript knowledge.

### Q: How is this different from GitHub Copilot or other cloud AI tools?
A: The main difference is that this extension runs entirely on your local machine. Your code never leaves your computer, providing complete privacy and control over your data. Additionally, you can choose which models to use based on your preferences.

### Q: Why is my model file not being detected?

If your model file is not being detected, check the following:

1. Model name case sensitivity: Ensure that the model filename matches exactly with what's in your config.yml. The config is case-sensitive (e.g., "mistral-7b-instruct-v0.2.Q4_K_M.gguf" vs. "Mistral-7B-Instruct-v0.2.Q4_K_M.gguf").

2. Model path: Make sure the model is in the correct directory. The default is the "models/" directory in the project root.

3. File permissions: Ensure the model file has read permissions.

### The services don't start or I get port conflicts. What should I do?

The extension now includes automatic port conflict detection and resolution. If a port is already in use, the system will find an available port automatically. However, if you're still experiencing issues:

1. Check if another program is using the default ports (8081 for LLM, 5000 for backend, 8090 for Weaviate)
2. Use the `stop_all.sh` or `stop_all.bat` script to ensure all previous instances are stopped
3. Manually specify different ports in your config.yml file
4. Restart your computer to clear any hung processes

### How do I troubleshoot other issues?

1. Check the log files in the `logs/` directory
2. Run the automated tests with `run_tests.sh` or `run_tests.bat` to identify specific issues
3. Make sure Docker is running if you're using Weaviate memory integration
4. Check your GPU drivers are up-to-date if using GPU acceleration

## Command Reference

Here's a quick reference of all available commands and their shortcuts:

| Command | Shortcut (Windows/Linux) | Shortcut (macOS) | Description |
|---------|--------------------------|------------------|-------------|
| Ask AI | Ctrl+Shift+A | ⌘+Shift+A | Ask any question to the AI |
| Explain Selected Code | Ctrl+Shift+E | ⌘+Shift+E | Get an explanation of selected code |
| Complete Code | Ctrl+Shift+C | ⌘+Shift+C | Get code completion suggestions |
| Improve Selected Code | Ctrl+Shift+I | ⌘+Shift+I | Get suggestions to improve code |
| Start Services | N/A | N/A | Start the backend services |
| Stop Services | N/A | N/A | Stop the backend services |

---

Made with ❤️ for developers who want AI assistance without sacrificing privacy or performance. 
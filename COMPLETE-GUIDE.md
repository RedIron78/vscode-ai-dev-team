# VS Code AI Dev Team - Complete Guide

![VS Code AI Dev Team Banner](https://i.imgur.com/DsRhFQh.png)

**Version 1.0.0**

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [System Requirements](#system-requirements)
4. [Model Selection Guide](#model-selection-guide)
5. [Installation Guide](#installation-guide)
   - [Linux Installation](#linux-installation)
   - [Windows Installation](#windows-installation)
   - [macOS Installation](#macos-installation)
6. [Using the Extension](#using-the-extension)
   - [Commands](#commands)
   - [Tips for Best Results](#tips-for-best-results)
7. [Advanced Features](#advanced-features)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

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

## System Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: 5GB for minimal installation
- **GPU**: Optional but recommended for faster performance
  - NVIDIA GPU with CUDA support (for NVIDIA users)
  - Apple Silicon M1/M2/M3 (optimized for Mac users)

## Model Selection Guide

The extension works with any GGUF model. We provide direct download links for models tailored to different system capabilities:

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

Choose your operating system below for installation instructions.

### Linux Installation

Follow these steps to install the VS Code AI Dev Team extension on Linux:

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

### Windows Installation

Follow these steps to install the VS Code AI Dev Team extension on Windows:

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

### macOS Installation

Follow these steps to install the VS Code AI Dev Team extension on macOS:

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

## Using the Extension

### Starting the Services

Before using the extension, you need to start the backend services:

1. Open a terminal and navigate to the project directory
2. Run `./start_all.sh` (Linux/macOS) or `start_all.bat` (Windows)
3. Wait for all services to start successfully

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

To clear the memory:
1. Stop all services using `./stop_all.sh` (Linux/macOS) or `stop_all.bat` (Windows)
2. Run `docker-compose down -v` in the project directory
3. Start the services again

### Custom Models

You can use different AI models with the extension:

1. Download a GGUF model from [Hugging Face](https://huggingface.co/models?library=gguf)
2. Place it in the `models` directory
3. Update the model path in `scripts/run_llama_server.sh` (Linux/macOS) or `scripts\run_llama_server.bat` (Windows)

### GPU Acceleration

If you have a compatible GPU, the extension can use it to run models faster:

- **NVIDIA GPUs**: Ensure CUDA is installed and the model is built with CUDA support
- **AMD GPUs**: Currently limited support through ROCm
- **Apple Silicon**: Uses optimized Metal API automatically on M1/M2/M3 Macs

## Troubleshooting

### Common Issues

#### Extension Shows "Failed to start AI services"

**Possible causes and solutions**:
1. Services aren't running - Run `./start_all.sh` or `start_all.bat`
2. Llama.cpp server executable not found - Check if it was built correctly
3. Port conflict - Another application might be using port 5000 or 8080

#### AI Responses Are Slow

**Possible solutions**:
1. Use a smaller model (e.g., TinyLlama instead of Mistral)
2. Enable GPU acceleration if available
3. Increase the server's allocated memory

#### AI Gives Incorrect or Irrelevant Responses

**Possible solutions**:
1. Try using a larger, more capable model
2. Be more specific in your questions
3. Clear the memory if the AI seems confused by previous context

### Checking Logs

If you encounter issues, check the log files:

- **Linux/macOS**: `/tmp/llm_server.log` and `/tmp/vscode_agent.log`
- **Windows**: `%TEMP%\llm_server.log` and `%TEMP%\vscode_agent.log`

### Stopping and Restarting Services

When you're done using the extension, you can stop all the services:

```bash
./stop_all.sh  # or stop_all.bat on Windows
```

The next time you want to use the extension, just run:

```bash
./start_all.sh  # or start_all.bat on Windows
```

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
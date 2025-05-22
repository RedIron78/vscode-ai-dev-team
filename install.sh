#!/bin/bash

set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}     VS Code AI Dev Team - One-Click Installer          ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Check system requirements
echo -e "\n${YELLOW}Checking system requirements...${NC}"

# Check OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    MINGW*|MSYS*) OS_TYPE=Windows;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

echo -e "Detected OS: ${GREEN}${OS_TYPE}${NC}"

# Check for Python
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
    echo -e "Python version: ${GREEN}${PYTHON_VERSION}${NC}"
else
    echo -e "${RED}Python 3 not found. Please install Python 3.8+ before continuing.${NC}"
    exit 1
fi

# Check for pip
if ! command -v pip3 &>/dev/null; then
    echo -e "${RED}pip3 not found. Please install pip for Python 3 before continuing.${NC}"
    exit 1
fi

# Check for Node.js
if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "Node.js version: ${GREEN}${NODE_VERSION}${NC}"
else
    echo -e "${RED}Node.js not found. Please install Node.js before continuing.${NC}"
    exit 1
fi

# Check for npm
if command -v npm &>/dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "npm version: ${GREEN}${NPM_VERSION}${NC}"
else
    echo -e "${RED}npm not found. Please install npm before continuing.${NC}"
    exit 1
fi

# Check for Docker
if command -v docker &>/dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f 3 | tr -d ',')
    echo -e "Docker version: ${GREEN}${DOCKER_VERSION}${NC}"
else
    echo -e "${YELLOW}Warning: Docker not found. Vector database features will not be available.${NC}"
    read -p "Do you want to continue without Docker? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation aborted. Please install Docker and try again.${NC}"
        exit 1
    fi
fi

# Check for GPU support
GPU_SUPPORT="No"
if [ "$OS_TYPE" = "Linux" ]; then
    if command -v nvidia-smi &>/dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader)
        echo -e "GPU detected: ${GREEN}${GPU_INFO}${NC}"
        GPU_SUPPORT="Yes"
    else
        echo -e "${YELLOW}No NVIDIA GPU detected. Will configure for CPU-only operation.${NC}"
    fi
elif [ "$OS_TYPE" = "Mac" ]; then
    if [[ $(sysctl -n machdep.cpu.brand_string) == *"Apple"* ]]; then
        echo -e "Apple Silicon detected: ${GREEN}Will use Metal acceleration${NC}"
        GPU_SUPPORT="Metal"
    else
        echo -e "${YELLOW}No Apple Silicon detected. Will configure for CPU-only operation.${NC}"
    fi
else
    echo -e "${YELLOW}GPU detection not implemented for Windows. Will configure for CPU-only operation.${NC}"
fi

# Create Python virtual environment
echo -e "\n${YELLOW}Setting up Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}Virtual environment created.${NC}"
else
    echo -e "${GREEN}Virtual environment already exists.${NC}"
fi

# Activate virtual environment
if [ "$OS_TYPE" = "Windows" ]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi
echo -e "${GREEN}Virtual environment activated.${NC}"

# Install Python dependencies
echo -e "\n${YELLOW}Installing Python dependencies...${NC}"
pip install --upgrade pip
pip install -r backend/requirements.txt
echo -e "${GREEN}Python dependencies installed.${NC}"

# Build the extension
echo -e "\n${YELLOW}Building VS Code extension...${NC}"
cd extension
npm install
npm run compile
npm run package
cd ..
echo -e "${GREEN}VS Code extension built.${NC}"

# Setup Weaviate (if Docker is available)
if command -v docker &>/dev/null; then
    echo -e "\n${YELLOW}Setting up Weaviate vector database...${NC}"
    docker-compose pull
    echo -e "${GREEN}Weaviate image pulled.${NC}"
fi

# Setup llama.cpp
echo -e "\n${YELLOW}Setting up llama.cpp...${NC}"
if [ -d "llama.cpp" ]; then
    cd llama.cpp
    git pull
    cd ..
    echo -e "${GREEN}llama.cpp updated.${NC}"
else
    git clone https://github.com/ggerganov/llama.cpp.git
    echo -e "${GREEN}llama.cpp cloned.${NC}"
fi

# Build llama.cpp
echo -e "\n${YELLOW}Building llama.cpp...${NC}"
cd llama.cpp
if [ "$GPU_SUPPORT" = "Yes" ]; then
    # Build with CUDA support
    echo -e "${YELLOW}Building with CUDA support...${NC}"
    make LLAMA_CUBLAS=1
elif [ "$GPU_SUPPORT" = "Metal" ]; then
    # Build with Metal support
    echo -e "${YELLOW}Building with Metal support...${NC}"
    make LLAMA_METAL=1
else
    # Build with CPU only
    make
fi
cd ..
echo -e "${GREEN}llama.cpp built.${NC}"

# Create necessary directories
echo -e "\n${YELLOW}Creating necessary directories...${NC}"
mkdir -p models logs memory
echo -e "${GREEN}Directories created.${NC}"

# Make scripts executable
echo -e "\n${YELLOW}Setting up scripts...${NC}"
chmod +x scripts/*.sh
chmod +x start_all.sh
chmod +x stop_all.sh
echo -e "${GREEN}Scripts are now executable.${NC}"

# Check if model exists
echo -e "\n${YELLOW}Checking for LLM models...${NC}"
if [ -z "$(ls -A models 2>/dev/null)" ]; then
    echo -e "${YELLOW}No models found in the models directory.${NC}"
    echo -e "${YELLOW}You need to download a compatible model (e.g., Mistral-7B-Instruct-v0.2.Q4_K_M.gguf).${NC}"
    echo -e "${YELLOW}Place downloaded models in the 'models' directory.${NC}"
    
    read -p "Would you like to see instructions for downloading models? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${BLUE}Model Download Instructions:${NC}"
        echo -e "1. Visit https://huggingface.co/models?pipeline_tag=text-generation&sort=downloads"
        echo -e "2. Choose a model (Mistral-7B or Llama 2 7B are good starting points)"
        echo -e "3. Download the GGUF version of the model (Q4_K_M is a good balance)"
        echo -e "4. Place the downloaded .gguf file in the 'models' directory"
    fi
else
    echo -e "${GREEN}Models found in the models directory.${NC}"
    ls -la models
fi

# Install VS Code extension
echo -e "\n${YELLOW}Installing the VS Code extension...${NC}"
if command -v code &>/dev/null; then
    code --install-extension extension/vscode-ai-dev-team-0.1.0.vsix
    echo -e "${GREEN}VS Code extension installed.${NC}"
else
    echo -e "${YELLOW}VS Code CLI not found. Please install the extension manually:${NC}"
    echo -e "${YELLOW}1. Open VS Code${NC}"
    echo -e "${YELLOW}2. Go to Extensions panel (Ctrl+Shift+X)${NC}"
    echo -e "${YELLOW}3. Click the '...' menu in the top-right corner${NC}"
    echo -e "${YELLOW}4. Select 'Install from VSIX...'${NC}"
    echo -e "${YELLOW}5. Navigate to ${PWD}/extension/vscode-ai-dev-team-0.1.0.vsix${NC}"
fi

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}  Installation complete! Here's how to get started:${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "\n1. Start all services with: ${YELLOW}./start_all.sh${NC}"
echo -e "2. Open VS Code and use the command palette (Ctrl+Shift+P):"
echo -e "   - ${YELLOW}AI Dev Team: Ask AI${NC}"
echo -e "   - ${YELLOW}AI Dev Team: Explain Selected Code${NC}"
echo -e "   - ${YELLOW}AI Dev Team: Complete Code${NC}"
echo -e "3. Stop all services with: ${YELLOW}./stop_all.sh${NC}"
echo -e "\nFor more details, see ${YELLOW}README.md${NC} and ${YELLOW}COMPLETE-GUIDE.md${NC}" 
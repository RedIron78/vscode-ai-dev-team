#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MODELS_DIR="../models"

# Ensure models directory exists
mkdir -p "$MODELS_DIR"

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}     VS Code AI Dev Team - Model Downloader              ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# List of popular models with their HuggingFace URLs
declare -A MODELS
MODELS["mistral-7b-instruct"]="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
MODELS["mistral-7b-instruct-v0.2"]="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
MODELS["llama2-7b"]="https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf"
MODELS["llama2-7b-chat"]="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf"
MODELS["codellama-7b-instruct"]="https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf"
MODELS["phi-2"]="https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
MODELS["openchat-3.5"]="https://huggingface.co/TheBloke/openchat-3.5-0106-GGUF/resolve/main/openchat-3.5-0106.Q4_K_M.gguf"

show_models() {
    echo -e "\n${YELLOW}Available models:${NC}"
    
    local i=1
    for model in "${!MODELS[@]}"; do
        echo -e "${GREEN}$i)${NC} $model"
        i=$((i+1))
    done
    echo -e "${GREEN}$i)${NC} Custom URL"
}

download_model() {
    local url=$1
    local filename=$(basename "$url")
    
    echo -e "\n${YELLOW}Downloading model to ${MODELS_DIR}/${filename}${NC}"
    echo -e "${YELLOW}This may take a while depending on your internet speed...${NC}"
    
    # Check if wget or curl is available
    if command -v wget &>/dev/null; then
        wget -O "${MODELS_DIR}/${filename}" "$url"
    elif command -v curl &>/dev/null; then
        curl -L -o "${MODELS_DIR}/${filename}" "$url"
    else
        echo -e "${RED}Error: Neither wget nor curl is installed.${NC}"
        echo -e "${RED}Please install one of them and try again.${NC}"
        exit 1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Model downloaded successfully!${NC}"
        echo -e "${GREEN}Location: ${MODELS_DIR}/${filename}${NC}"
    else
        echo -e "\n${RED}Failed to download the model.${NC}"
        exit 1
    fi
}

# Main menu
show_models

echo -e "\n${YELLOW}Enter the number of the model you want to download:${NC}"
read -r choice

# Convert choice to array index
models_array=("${!MODELS[@]}")
choice=$((choice-1))

if [ $choice -ge 0 ] && [ $choice -lt ${#MODELS[@]} ]; then
    # Selected one of the pre-defined models
    selected_model=${models_array[$choice]}
    model_url=${MODELS[$selected_model]}
    
    echo -e "\n${GREEN}Selected model: ${selected_model}${NC}"
    download_model "$model_url"
elif [ $choice -eq ${#MODELS[@]} ]; then
    # Custom URL option
    echo -e "\n${YELLOW}Enter the custom model URL:${NC}"
    read -r custom_url
    
    if [[ $custom_url == http* ]]; then
        download_model "$custom_url"
    else
        echo -e "${RED}Invalid URL format. URL must start with http:// or https://".${NC}"
        exit 1
    fi
else
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
fi

echo -e "\n${BLUE}You can now use this model with the VS Code AI Dev Team.${NC}"
echo -e "${BLUE}Make sure to update your config.yml file with the model path:${NC}"
echo -e "${GREEN}  default_model: \"models/$(basename "${MODELS_DIR}/${filename}")\"${NC}" 
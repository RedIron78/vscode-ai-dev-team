#!/bin/bash

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$PROJECT_ROOT/models"

# Function to get appropriate GPU layers based on model size
get_gpu_layers() {
    local model_path="$1"
    local default_layers="$2"
    
    # Check if model name contains certain strings indicating large models
    if [[ "$model_path" == *"17B"* ]]; then
        echo "Model is very large, using minimal GPU acceleration (1 layer) to avoid out-of-memory errors"
        echo "1"  # Use 1 GPU layer for 17B models
    elif [[ "$model_path" == *"34B"* ]] || [[ "$model_path" == *"70B"* ]]; then
        echo "Model is extremely large for consumer GPUs, using CPU-only mode (0 GPU layers)"
        echo "0"  # Use CPU only for extremely large models
    else
        echo "$default_layers"
    fi
}

# Default values
MODEL_PATH="$1"  # First argument is model path
HOST="${LLM_HOST:-127.0.0.1}"
PORT="${LLM_PORT:-8081}"
THREADS="${LLM_THREADS:-4}"
DEFAULT_GPU_LAYERS="${LLM_GPU_LAYERS:-35}"

# Determine appropriate GPU layers based on model size
GPU_LAYERS=$(get_gpu_layers "$MODEL_PATH" "$DEFAULT_GPU_LAYERS")

# Function to check if a port is in use
port_in_use() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -i :"$port" >/dev/null 2>&1
        return $?
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port "
        return $?
    else
        # Default to assuming port is free if we can't check
        return 1
    fi
}

# Function to find an available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    
    while port_in_use "$port"; do
        port=$((port + 1))
        # Safety check to prevent infinite loop
        if [ "$port" -gt "$((start_port + 100))" ]; then
            echo "Cannot find available port within reasonable range."
            return 1
        fi
    done
    
    echo "$port"
}

# Check if the port is in use and find an available one if needed
if port_in_use "$PORT"; then
    echo "Warning: Port $PORT is already in use."
    PORT=$(find_available_port "$PORT")
    echo "Using alternative port: $PORT"
fi

# Display banner
echo "======================================================"
echo "  Llama.cpp Server Launcher for AI Dev Team"
echo "======================================================"

# Check if we have models in our models directory
if [ -d "$MODELS_DIR" ] && [ "$(ls -A "$MODELS_DIR" 2>/dev/null)" ]; then
    echo "Models found in $MODELS_DIR:"
    ls -1 "$MODELS_DIR"/*.gguf 2>/dev/null || echo "No .gguf models found."
    
    # Check if LLM_MODEL is set from environment (from start_all.sh)
    if [ -n "$LLM_MODEL" ]; then
        MODEL_PATH="$LLM_MODEL"
        echo "Using model from environment: $MODEL_PATH"
        
        # Check if this is a multi-part model (part 1 of N)
        if [[ "$MODEL_PATH" == *"-00001-of-"* ]]; then
            echo "Detected split GGUF model. Will use the base part."
        fi
        
        # Set lower GPU layers for large models (Llama-4 models)
        if [[ "$MODEL_PATH" == *"Llama-4"* ]] && [[ "$MODEL_PATH" == *"17B"* ]]; then
            echo "Large model detected. Reducing GPU layers to avoid out-of-memory errors."
            GPU_LAYERS=4
        fi
    else
        # Try to find a GGUF model if LLM_MODEL not set
        FIRST_MODEL=$(find "$MODELS_DIR" -name "*.gguf" | head -n 1)
        if [ -n "$FIRST_MODEL" ]; then
            MODEL_PATH="$FIRST_MODEL"
            echo "Using model: $MODEL_PATH"
            
            # Set lower GPU layers for large models (Llama-4 models)
            if [[ "$MODEL_PATH" == *"Llama-4"* ]] && [[ "$MODEL_PATH" == *"17B"* ]]; then
                echo "Large model detected. Reducing GPU layers to avoid out-of-memory errors."
                GPU_LAYERS=4
            fi
        fi
    fi
else
    echo "No models found in $MODELS_DIR directory."
    mkdir -p "$MODELS_DIR"
fi

# Try to locate llama-server executable - priority on our local build
LLAMA_SERVER_PATH=""
if [ -f "$PROJECT_ROOT/llama.cpp/build/bin/llama-server" ]; then
    LLAMA_SERVER_PATH="$PROJECT_ROOT/llama.cpp/build/bin/llama-server"
elif command -v llama-server &> /dev/null; then
    LLAMA_SERVER_PATH=$(which llama-server)
elif [ -f "/home/rediron78/LLM/llama.cpp/build/bin/llama-server" ]; then
    LLAMA_SERVER_PATH="/home/rediron78/LLM/llama.cpp/build/bin/llama-server"
fi

# Check if llama.cpp is installed
if [ -z "$LLAMA_SERVER_PATH" ]; then
    echo "Error: llama-server executable not found!"
    echo "Please install llama.cpp from: https://github.com/ggerganov/llama.cpp"
    echo ""
    echo "Quick setup (requires build tools):"
    echo "  git clone https://github.com/ggerganov/llama.cpp"
    echo "  cd llama.cpp"
    echo "  mkdir -p build && cd build"
    echo "  cmake .. -DGGML_CUDA=ON  # Use -DGGML_CUDA=OFF for CPU only"
    echo "  cmake --build . --config Release"
    echo ""
    echo "Then download a .gguf model to the $MODELS_DIR directory."
    echo "You can find models at: https://huggingface.co/models?search=gguf"
    exit 1
fi

# If no model was found, ask for path
if [ -z "$MODEL_PATH" ]; then
    echo "No .gguf model files found in $MODELS_DIR"
    read -p "Enter path to your .gguf model file: " MODEL_PATH
    
    if [ ! -f "$MODEL_PATH" ]; then
        echo "Error: Model file not found at: $MODEL_PATH"
        exit 1
    fi
fi

echo "Using model: $MODEL_PATH"
echo "Using llama-server at: $LLAMA_SERVER_PATH"
echo "Starting server on http://$HOST:$PORT"
if [ $GPU_LAYERS -gt 0 ]; then
    echo "GPU enabled with $GPU_LAYERS layers offloaded to GPU"
else
    echo "Running in CPU-only mode"
fi
echo ""
echo "Press Ctrl+C to stop the server"
echo "======================================================"

# Start the server with the appropriate model
"$LLAMA_SERVER_PATH" \
    -m "$MODEL_PATH" \
    -c 2048 \
    --host "$HOST" \
    --port "$PORT" \
    -t "$THREADS" \
    --log-disable \
    -ngl "$GPU_LAYERS" 
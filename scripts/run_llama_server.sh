#!/bin/bash

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$PROJECT_ROOT/models"

# Default values
MODEL_PATH=""  # Will be set after checking models directory
HOST="127.0.0.1"
PORT="8081"
THREADS=4
GPU_LAYERS=35  # Number of layers to offload to GPU, set to 0 for CPU only

# Display banner
echo "======================================================"
echo "  Llama.cpp Server Launcher for AI Dev Team"
echo "======================================================"

# Check if we have models in our models directory
if [ -d "$MODELS_DIR" ] && [ "$(ls -A "$MODELS_DIR" 2>/dev/null)" ]; then
    echo "Models found in $MODELS_DIR:"
    ls -1 "$MODELS_DIR"/*.gguf 2>/dev/null || echo "No .gguf models found."
    
    # Try to find a GGUF model
    FIRST_MODEL=$(find "$MODELS_DIR" -name "*.gguf" | head -n 1)
    if [ -n "$FIRST_MODEL" ]; then
        MODEL_PATH="$FIRST_MODEL"
        echo "Using model: $MODEL_PATH"
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

# Allow user to specify CPU-only mode
read -p "Run on CPU only? (y/N): " CPU_ONLY
if [[ "$CPU_ONLY" =~ ^[Yy]$ ]]; then
    GPU_LAYERS=0
    echo "Running in CPU-only mode"
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

# Start the server
"$LLAMA_SERVER_PATH" \
    -m "$MODEL_PATH" \
    -c 2048 \
    --host "$HOST" \
    --port "$PORT" \
    -t "$THREADS" \
    --log-disable \
    -ngl "$GPU_LAYERS" 
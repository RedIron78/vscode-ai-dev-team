#!/bin/bash

# Default values
MODEL_PATH="/home/rediron78/LLM/Ddrivemigration/Ddrive/text-generation-webui/user_data/models/openchat-3.5-0106.Q4_K_M.gguf"
HOST="127.0.0.1"
PORT="8081"
THREADS=4
GPU_LAYERS=35  # Number of layers to offload to GPU

# Display banner
echo "======================================================"
echo "  Llama.cpp Server Launcher for AI Dev Team"
echo "======================================================"

# Set the path to llama-server executable (using the GPU-enabled build)
LLAMA_SERVER_PATH="/home/rediron78/LLM/llama.cpp/build/bin/llama-server"

# Check if llama.cpp is installed
if [ ! -f "$LLAMA_SERVER_PATH" ]; then
    echo "Error: llama-server not found at $LLAMA_SERVER_PATH!"
    echo "Please install llama.cpp from: https://github.com/ggerganov/llama.cpp"
    echo ""
    echo "Quick setup (requires build tools):"
    echo "  git clone https://github.com/ggerganov/llama.cpp"
    echo "  cd llama.cpp"
    echo "  mkdir -p build && cd build"
    echo "  cmake .. -DGGML_CUDA=ON"
    echo "  cmake --build . --config Release"
    echo "  mkdir -p ../models"
    echo "  # Download a .gguf model to the models directory"
    exit 1
fi

# Check if model file exists and ask for path if not
if [ ! -f "$MODEL_PATH" ]; then
    echo "Default model not found at: $MODEL_PATH"
    read -p "Enter path to your .gguf model file: " MODEL_PATH
    
    if [ ! -f "$MODEL_PATH" ]; then
        echo "Error: Model file not found at: $MODEL_PATH"
        exit 1
    fi
fi

echo "Using model: $MODEL_PATH"
echo "Starting server on http://$HOST:$PORT"
echo "GPU enabled with $GPU_LAYERS layers offloaded to GPU"
echo ""
echo "Press Ctrl+C to stop the server"
echo "======================================================"

# Start the server with GPU support
"$LLAMA_SERVER_PATH" \
    -m "$MODEL_PATH" \
    -c 2048 \
    --host "$HOST" \
    --port "$PORT" \
    -t "$THREADS" \
    --log-disable \
    -ngl "$GPU_LAYERS"
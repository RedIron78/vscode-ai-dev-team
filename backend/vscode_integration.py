import os
import sys
import json
import argparse
from typing import Dict, Any
from flask import Flask, request, jsonify, Response, make_response
from datetime import datetime

# Try different import approaches to support various ways of running the script
try:
    # Direct import when run as python -m backend.vscode_integration
    from .port_utils import get_backend_port, save_port_info
except (ImportError, ModuleNotFoundError):
    try:
        # Direct import when run within the backend directory
        from port_utils import get_backend_port, save_port_info
    except (ImportError, ModuleNotFoundError):
        # Absolute import when run from project root
        sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        from backend.port_utils import get_backend_port, save_port_info

from vscode_agent import VSCodeAgent

# Initialize the VSCodeAgent
agent = VSCodeAgent()

def parse_vscode_request(request_json: str) -> Dict[str, Any]:
    """Parse a request from VS Code IDE."""
    try:
        return json.loads(request_json)
    except json.JSONDecodeError:
        return {"error": "Invalid JSON format"}

def handle_vscode_request(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle a request from VS Code IDE and return a response."""
    request_type = request_data.get("type", "")
    
    if request_type == "code_completion":
        return handle_code_completion(request_data)
    elif request_type == "code_explanation":
        return handle_code_explanation(request_data)
    elif request_type == "code_improvement":
        return handle_code_improvement(request_data)
    elif request_type == "general_query":
        return handle_general_query(request_data)
    else:
        return {
            "status": "error",
            "message": f"Unknown request type: {request_type}"
        }

def handle_code_completion(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle a code completion request."""
    code_context = request_data.get("code_context", "")
    file_type = request_data.get("file_type", "")
    user_request = request_data.get("request", "")
    
    if not code_context or not file_type or not user_request:
        return {
            "status": "error",
            "message": "Missing required parameters for code completion"
        }
    
    completion = agent.code_completion(
        code_context=code_context,
        file_type=file_type,
        request=user_request
    )
    
    return {
        "status": "success",
        "completion": completion
    }

def handle_code_explanation(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle a code explanation request."""
    code = request_data.get("code", "")
    file_type = request_data.get("file_type", "")
    
    if not code or not file_type:
        return {
            "status": "error",
            "message": "Missing required parameters for code explanation"
        }
    
    explanation = agent.code_explanation(
        code=code,
        file_type=file_type
    )
    
    return {
        "status": "success",
        "explanation": explanation
    }

def handle_code_improvement(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle a code improvement request."""
    code = request_data.get("code", "")
    file_type = request_data.get("file_type", "")
    
    if not code or not file_type:
        return {
            "status": "error",
            "message": "Missing required parameters for code improvement"
        }
    
    improvements = agent.suggest_improvements(
        code=code,
        file_type=file_type
    )
    
    return {
        "status": "success",
        "improvements": improvements
    }

def handle_general_query(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle a general query request."""
    query = request_data.get("query", "")
    system_prompt = request_data.get("system_prompt", None)
    use_memory = request_data.get("use_memory", True)
    
    # Extract context if provided (for VS Code extension)
    context = request_data.get("context", {})
    file_path = context.get("file", None)
    file_language = context.get("language", None)
    
    # Add file context to prompt if available
    enhanced_query = query
    if file_path and file_language:
        enhanced_query = f"Context: Working in a {file_language} file: {file_path}\n\nQuery: {query}"
    
    if not query:
        return {
            "status": "error",
            "message": "Missing required parameters for general query"
        }
    
    # Add memory context if available for VS Code extension
    memory_query = query
    if file_language:
        memory_query = f"{file_language} {query}"
    
    response = agent.get_completion(
        prompt=enhanced_query,
        system_prompt=system_prompt,
        use_memory=use_memory,
        memory_query=memory_query
    )
    
    # For VS Code extension, track the memory ID used
    memory_id = ""
    if use_memory:
        recent_memories = agent.search_memory(memory_query, limit=1)
        if recent_memories and len(recent_memories) > 0:
            memory_id = recent_memories[0].get("id", "")
    
    return {
        "status": "success",
        "response": response,
        "memoryId": memory_id
    }

# OpenAI-compatible handlers
def handle_openai_completion(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle OpenAI-style completion requests."""
    # Print the request for debugging
    print(f"Received completion request: {json.dumps(request_data)}")
    
    prompt = request_data.get("prompt", "")
    if not prompt:
        # Try to extract from messages for chat completions
        messages = request_data.get("messages", [])
        if messages:
            # Extract the last user message
            for msg in reversed(messages):
                if msg.get("role") == "user":
                    prompt = msg.get("content", "")
                    break
    
    if not prompt:
        return {
            "error": {
                "message": "No prompt or messages provided",
                "type": "invalid_request_error"
            }
        }
    
    system_prompt = None
    # Check for system message in chat completions
    messages = request_data.get("messages", [])
    for msg in messages:
        if msg.get("role") == "system":
            system_prompt = msg.get("content")
            break
    
    response_text = agent.get_completion(
        prompt=prompt,
        system_prompt=system_prompt,
        use_memory=True
    )
    
    # Format response in OpenAI style
    if request_data.get("stream", False):
        # Implement streaming if needed
        pass
    
    # Return in chat completions format if it was a chat request
    if "messages" in request_data:
        return {
            "id": "weaviate-vscode-" + str(hash(response_text))[:10],
            "object": "chat.completion",
            "created": int(__import__('time').time()),
            "model": "vscode-agent",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": response_text
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 0,  # Simplified, no real token counting
                "completion_tokens": 0,
                "total_tokens": 0
            }
        }
    
    # Regular completions format
    return {
        "id": "weaviate-vscode-" + str(hash(response_text))[:10],
        "object": "text_completion",
        "created": int(__import__('time').time()),
        "model": "vscode-agent",
        "choices": [
            {
                "text": response_text,
                "index": 0,
                "logprobs": None,
                "finish_reason": "stop"
            }
        ],
        "usage": {
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "total_tokens": 0
        }
    }

def create_app():
    """Create the Flask app instance."""
    app = Flask(__name__)

    # Configure CORS headers for all routes
    @app.after_request
    def after_request(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
        return response

    # Handle preflight OPTIONS requests for CORS
    @app.route('/v1/<path:path>', methods=['OPTIONS'])
    def options_handler(path):
        return make_response('', 204)

    # API endpoint for VS Code extension
    @app.route("/api/agent", methods=["POST"])
    def api_request():
        """Handle general API requests from VS Code extension."""
        try:
            request_data = parse_vscode_request(request.data.decode('utf-8'))
            response_data = handle_vscode_request(request_data)
            return jsonify(response_data)
        except Exception as e:
            return jsonify({
                "status": "error",
                "message": f"An error occurred: {str(e)}"
            })

    # API endpoint for specific queries
    @app.route("/api/agent/query", methods=["POST"])
    def api_query_request():
        """Handle query requests from VS Code extension."""
        try:
            request_data = parse_vscode_request(request.data.decode('utf-8'))
            # Ensure the type is set to general_query for backward compatibility
            if "type" not in request_data:
                request_data["type"] = "general_query"
            response_data = handle_vscode_request(request_data)
            return jsonify(response_data)
        except Exception as e:
            return jsonify({
                "status": "error",
                "message": f"An error occurred: {str(e)}"
            })

    # Test API endpoint
    @app.route("/api/test", methods=["GET"])
    def api_test():
        return jsonify({
            "status": "success",
            "message": "VS Code Agent API is working!",
            "version": "0.2.0"
        })

    # Test query API endpoint
    @app.route("/api/agent/query/test", methods=["GET"])
    def api_query_test():
        """Test endpoint for query API."""
        return jsonify({
            "status": "success",
            "message": "VS Code Agent Query API is working!",
            "version": "0.2.0"
        })

    # OpenAI-compatible completions endpoint
    @app.route("/v1/completions", methods=["POST"])
    def completions():
        """Handle OpenAI-style completion requests."""
        try:
            request_data = request.json
            response_data = handle_openai_completion(request_data)
            return jsonify(response_data)
        except Exception as e:
            return jsonify({
                "error": {
                    "message": f"An error occurred: {str(e)}",
                    "type": "server_error"
                }
            })

    # OpenAI-compatible chat completions endpoint
    @app.route("/v1/chat/completions", methods=["POST"])
    def chat_completions():
        """Handle OpenAI-style chat completion requests."""
        try:
            request_data = request.json
            response_data = handle_openai_completion(request_data)
            return jsonify(response_data)
        except Exception as e:
            return jsonify({
                "error": {
                    "message": f"An error occurred: {str(e)}",
                    "type": "server_error"
                }
            })

    # Validation routes for OpenAI compatibility
    @app.route("/v1/chat/completions", methods=["GET"])
    def chat_validate():
        """Validate OpenAI-style chat completions endpoint."""
        return jsonify({
            "object": "list",
            "data": [],
            "model": "weaviate-vscode-assistant"
        })

    @app.route("/v1/completions", methods=["GET"])
    def completions_validate():
        """Validate OpenAI-style completions endpoint."""
        return jsonify({
            "object": "list",
            "data": [],
            "model": "weaviate-vscode-assistant"
        })

    # Models list for OpenAI compatibility
    @app.route("/v1/models", methods=["GET"])
    def list_models():
        """List available models (OpenAI compatibility)."""
        return jsonify({
            "object": "list",
            "data": [
                {
                    "id": "weaviate-vscode-assistant",
                    "object": "model",
                    "created": int(__import__('time').time()),
                    "owned_by": "user"
                }
            ]
        })

    @app.route('/', methods=['GET'])
    def index():
        """Root endpoint."""
        return jsonify({
            "message": "VS Code AI Dev Team Agent API",
            "version": "0.2.0",
            "status": "running"
        })

    return app

def main():
    """Run the server."""
    parser = argparse.ArgumentParser(description='VS Code Agent Server')
    parser.add_argument('--host', type=str, default='127.0.0.1', help='Host to bind to')
    parser.add_argument('--port', type=int, default=None, help='Port to bind to')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--production', action='store_true', help='Run in production mode')
    
    args = parser.parse_args()
    
    # If port is not specified, determine it from environment or config
    if args.port is None:
        args.port = get_backend_port()
    
    # Save the port information to central location and for VS Code extension
    save_port_info(backend_port=args.port)
    
    print(f"Starting VS Code integration server on http://{args.host}:{args.port}")
    
    app = create_app()
    app.run(host=args.host, port=args.port, debug=args.debug)

if __name__ == "__main__":
    main() 
import os
import sys
import json
import argparse
from typing import Dict, Any
from flask import Flask, request, jsonify, Response, make_response
from datetime import datetime

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
    """Create the Flask application."""
    app = Flask(__name__)
    app.logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))
    
    @app.after_request
    def after_request(response):
        """Add CORS headers to all responses."""
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
        return response
    
    @app.route('/v1/<path:path>', methods=['OPTIONS'])
    def options_handler(path):
        """Handle OPTIONS requests for CORS."""
        return jsonify({})
    
    # Original endpoint for direct integration
    @app.route("/api/agent", methods=["POST"])
    def api_request():
        try:
            request_json = request.get_json()
            if not request_json:
                return jsonify({"status": "error", "message": "Invalid JSON"}), 400
            
            app.logger.info(f"Received request: {request_json}")
            response = handle_vscode_request(request_json)
            return jsonify(response)
        except Exception as e:
            app.logger.error(f"Error in api_request: {str(e)}", exc_info=True)
            return jsonify({"status": "error", "message": str(e)}), 500
    
    # Add compatibility endpoint for clients using /api/agent/query
    @app.route("/api/agent/query", methods=["POST"])
    def api_query_request():
        try:
            request_json = request.get_json()
            if not request_json:
                return jsonify({"status": "error", "message": "Invalid JSON"}), 400
            
            app.logger.info(f"Received request to /api/agent/query: {request_json}")
            response = handle_vscode_request(request_json)
            return jsonify(response)
        except Exception as e:
            app.logger.error(f"Error in api_query_request: {str(e)}", exc_info=True)
            return jsonify({"status": "error", "message": str(e)}), 500
    
    # Simple test endpoint to verify API connectivity
    @app.route("/api/test", methods=["GET"])
    def api_test():
        return jsonify({
            "status": "available",
            "message": "API connectivity test successful"
        })
    
    # Test endpoint specifically for the query route
    @app.route("/api/agent/query/test", methods=["GET"])
    def api_query_test():
        return jsonify({
            "status": "available",
            "message": "The /api/agent/query endpoint is available",
            "server_time": datetime.now().isoformat()
        })
    
    # OpenAI-compatible endpoints for VS Code integration
    @app.route("/v1/completions", methods=["POST"])
    def completions():
        try:
            request_json = request.get_json()
            response = handle_openai_completion(request_json)
            return jsonify(response)
        except Exception as e:
            app.logger.error(f"Error in completions: {str(e)}", exc_info=True)
            return jsonify({
                "error": {
                    "message": str(e),
                    "type": "server_error"
                }
            }), 500
    
    @app.route("/v1/chat/completions", methods=["POST"])
    def chat_completions():
        try:
            request_json = request.get_json()
            response = handle_openai_completion(request_json)
            return jsonify(response)
        except Exception as e:
            app.logger.error(f"Error in chat_completions: {str(e)}", exc_info=True)
            return jsonify({
                "error": {
                    "message": str(e),
                    "type": "server_error"
                }
            }), 500
    
    @app.route("/v1/chat/completions", methods=["GET"])
    def chat_validate():
        return jsonify({
            "object": "list",
            "data": [],
            "first_id": None,
            "last_id": None,
            "has_more": False
        })
    
    @app.route("/v1/completions", methods=["GET"])
    def completions_validate():
        return jsonify({
            "object": "list",
            "data": [],
            "first_id": None,
            "last_id": None,
            "has_more": False
        })
    
    @app.route("/v1/models", methods=["GET"])
    def list_models():
        return jsonify({
            "object": "list",
            "data": [
                {
                    "id": "vscode-agent",
                    "object": "model",
                    "created": int(__import__('time').time()),
                    "owned_by": "organization-owner"
                }
            ]
        })
    
    @app.route('/', methods=['GET'])
    def index():
        return "VS Code Agent Integration Server"
    
    return app

def main():
    """Main entry point for the VS Code integration script."""
    parser = argparse.ArgumentParser(description="VS Code IDE integration for LLM agent")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="Host to run the server on")
    parser.add_argument("--port", type=int, default=5000, help="Port to run the server on")
    parser.add_argument("--debug", action="store_true", help="Run the server in debug mode")
    parser.add_argument("--input", type=str, help="Process a single request from this JSON string and exit")
    parser.add_argument("--production", action="store_true", help="Run the server in production mode using waitress")
    
    args = parser.parse_args()
    
    # If input is provided, process it and exit
    if args.input:
        request = parse_vscode_request(args.input)
        response = handle_vscode_request(request)
        print(json.dumps(response, indent=2))
        return
    
    # Otherwise, start the server
    app = create_app()
    
    print(f"Starting VS Code integration server on {args.host}:{args.port}")
    print(f"Debug mode: {'enabled' if args.debug else 'disabled'}")
    print("Press Ctrl+C to stop the server")
    
    if args.debug:
        # Use Flask's built-in server for development
        app.run(host=args.host, port=args.port, debug=True)
    elif args.production:
        # Use waitress for production
        from waitress import serve
        serve(app, host=args.host, port=args.port, threads=4)
    else:
        # Default behavior - use Flask's server without debug
        app.run(host=args.host, port=args.port, debug=False)

if __name__ == "__main__":
    main() 
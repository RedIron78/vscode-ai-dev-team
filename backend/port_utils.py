import os
import json
import yaml
import tempfile

def get_weaviate_config():
    """
    Get the Weaviate configuration from various sources.
    Returns a dict with host, port, and grpc_port.
    """
    # Default values
    config = {
        "host": "localhost",
        "port": 8083,
        "grpc_port": 50051
    }
    
    # First try to read from environment variables
    if os.environ.get('WEAVIATE_PORT'):
        config['port'] = int(os.environ.get('WEAVIATE_PORT'))
    if os.environ.get('WEAVIATE_GRPC_PORT'):
        config['grpc_port'] = int(os.environ.get('WEAVIATE_GRPC_PORT'))
    
    # Then try to read from the central port info file
    port_info_path = "/tmp/ai-dev-team/ports.json"
    try:
        if os.path.exists(port_info_path):
            with open(port_info_path, 'r') as f:
                port_info = json.load(f)
                if 'weaviate_port' in port_info:
                    config['port'] = port_info['weaviate_port']
                if 'weaviate_grpc_port' in port_info:
                    config['grpc_port'] = port_info['weaviate_grpc_port']
    except Exception as e:
        print(f"Warning: Could not load port info from {port_info_path}: {e}")
    
    # If central port info not available, try to load from config.yml
    config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'config.yml')
    try:
        with open(config_path, 'r') as f:
            yaml_config = yaml.safe_load(f)
            if yaml_config and 'weaviate' in yaml_config:
                if 'host' in yaml_config['weaviate']:
                    config['host'] = yaml_config['weaviate']['host']
                if 'port' in yaml_config['weaviate']:
                    config['port'] = yaml_config['weaviate']['port']
    except Exception as e:
        print(f"Warning: Could not load config.yml: {e}")
    
    return config

def get_llm_config():
    """
    Get the LLM server configuration from various sources.
    Returns a dict with host, port, model, and other parameters.
    """
    # Default values
    config = {
        "host": "127.0.0.1",
        "port": 8084,
        "model": "models/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
        "context_size": 4096,
        "temperature": 0.7
    }
    
    # First try to read from environment variables
    if os.environ.get('VSCODE_AGENT_LLM_HOST'):
        config['host'] = os.environ.get('VSCODE_AGENT_LLM_HOST')
    if os.environ.get('VSCODE_AGENT_LLM_PORT'):
        config['port'] = int(os.environ.get('VSCODE_AGENT_LLM_PORT'))
    if os.environ.get('VSCODE_AGENT_LLM_URL'):
        config['url'] = os.environ.get('VSCODE_AGENT_LLM_URL')
    else:
        # Construct URL from host and port if not explicitly set
        config['url'] = f"http://{config['host']}:{config['port']}/v1"
    
    # Then try to read from the central port info file
    port_info_path = "/tmp/ai-dev-team/ports.json"
    try:
        if os.path.exists(port_info_path):
            with open(port_info_path, 'r') as f:
                port_info = json.load(f)
                if 'llm_port' in port_info:
                    config['port'] = port_info['llm_port']
                    # Update URL with new port
                    config['url'] = f"http://{config['host']}:{config['port']}/v1"
    except Exception as e:
        print(f"Warning: Could not load port info from {port_info_path}: {e}")
    
    # Finally, try to load from config.yml
    config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'config.yml')
    try:
        with open(config_path, 'r') as f:
            yaml_config = yaml.safe_load(f)
            if yaml_config and 'llm' in yaml_config:
                llm_config = yaml_config['llm']
                if 'host' in llm_config:
                    config['host'] = llm_config['host']
                if 'port' in llm_config:
                    config['port'] = llm_config['port']
                if 'default_model' in llm_config:
                    config['model'] = llm_config['default_model']
                if 'context_size' in llm_config:
                    config['context_size'] = llm_config['context_size']
                if 'temperature' in llm_config:
                    config['temperature'] = llm_config['temperature']
                # Update URL with final host/port
                config['url'] = f"http://{config['host']}:{config['port']}/v1"
    except Exception as e:
        print(f"Warning: Could not load config.yml: {e}")
    
    return config

def get_backend_port():
    """
    Get the backend Flask server port from various sources.
    Returns the port as an integer.
    """
    # Default port
    port = 5002
    
    # First try to read from environment variables
    if os.environ.get('BACKEND_PORT'):
        port = int(os.environ.get('BACKEND_PORT'))
        return port
    
    # Then try to read from the port file that the VS Code extension looks for
    port_file = os.path.join(tempfile.gettempdir(), 'vscode_ai_agent_port.txt')
    try:
        if os.path.exists(port_file):
            with open(port_file, 'r') as f:
                port_str = f.read().strip()
                if port_str and port_str.isdigit():
                    return int(port_str)
    except Exception as e:
        print(f"Warning: Could not read port from {port_file}: {e}")
    
    # Then try to read from the central port info file
    port_info_path = "/tmp/ai-dev-team/ports.json"
    try:
        if os.path.exists(port_info_path):
            with open(port_info_path, 'r') as f:
                port_info = json.load(f)
                if 'backend_port' in port_info:
                    port = port_info['backend_port']
                    return port
    except Exception as e:
        print(f"Warning: Could not load port info from {port_info_path}: {e}")
    
    # Finally, try to load from config.yml
    config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'config.yml')
    try:
        with open(config_path, 'r') as f:
            yaml_config = yaml.safe_load(f)
            if yaml_config and 'backend' in yaml_config:
                if 'port' in yaml_config['backend']:
                    port = yaml_config['backend']['port']
    except Exception as e:
        print(f"Warning: Could not load config.yml: {e}")
    
    return port

def save_port_info(backend_port=None, weaviate_port=None, llm_port=None):
    """
    Save port information to a central location and to the VS Code extension port file.
    """
    # Ensure directory exists
    os.makedirs("/tmp/ai-dev-team", exist_ok=True)
    
    # Load existing port info if available
    port_info = {}
    port_info_path = "/tmp/ai-dev-team/ports.json"
    try:
        if os.path.exists(port_info_path):
            with open(port_info_path, 'r') as f:
                port_info = json.load(f)
    except Exception:
        pass
    
    # Update with new values
    if backend_port is not None:
        port_info['backend_port'] = backend_port
    if weaviate_port is not None:
        port_info['weaviate_port'] = weaviate_port
    if llm_port is not None:
        port_info['llm_port'] = llm_port
    
    # Save to central location
    try:
        with open(port_info_path, 'w') as f:
            json.dump(port_info, f)
    except Exception as e:
        print(f"Warning: Could not save port info to {port_info_path}: {e}")
    
    # Save backend port to VS Code extension port file
    if backend_port is not None:
        port_file = os.path.join(tempfile.gettempdir(), 'vscode_ai_agent_port.txt')
        try:
            with open(port_file, 'w') as f:
                f.write(str(backend_port))
        except Exception as e:
            print(f"Warning: Could not save port to {port_file}: {e}") 
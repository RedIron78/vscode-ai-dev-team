#!/usr/bin/env python3

import requests
import json
import os
import sys
import tempfile

# Add the repository root to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from backend.port_utils import get_backend_port  # This works when running from project root

def test_agent_memory():
    """Test if the agent can remember information across interactions."""
    # Get the backend port
    backend_port = get_backend_port()
    print(f"Using backend port: {backend_port}")
    
    # API URL with dynamic port
    api_url = f"http://localhost:{backend_port}/api/agent"
    print(f"API URL: {api_url}")
    
    # Test query to determine current memory capabilities
    test_query = {
        "type": "general_query",
        "query": "Can you remember information I tell you between sessions?",
        "use_memory": True
    }
    
    try:
        response = requests.post(api_url, json=test_query)
        response.raise_for_status()
        
        result = response.json()
        print("\nMemory test response:")
        if result.get("status") == "success":
            print(f"Response: {result.get('response')}")
            print(f"Memory ID: {result.get('memoryId', 'Not provided')}")
        else:
            print(f"Error: {result.get('message', 'Unknown error')}")
            
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to agent API: {e}")
        print("Please make sure the agent service is running.")

if __name__ == "__main__":
    test_agent_memory() 
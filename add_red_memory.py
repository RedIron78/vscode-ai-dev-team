#!/usr/bin/env python3

import os
import sys
import json
import yaml
import requests
import argparse
import tempfile
from datetime import datetime

# Add the repository root to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from backend.port_utils import get_backend_port, get_weaviate_config  # This works when running from project root

def add_red_memory(force=False):
    """
    Add a memory about calling the user 'Red' to test memory persistence.
    
    Args:
        force: Force adding memory even if it appears to exist
    """
    # Get backend port
    backend_port = get_backend_port()
    api_url = f"http://localhost:{backend_port}/api/agent"
    print(f"Using API URL: {api_url}")
    
    # First check if the memory exists already
    if not force:
        test_query = {
            "type": "general_query",
            "query": "What name should I call you?",
            "use_memory": True
        }
        
        try:
            print("Checking if name memory exists...")
            response = requests.post(api_url, json=test_query)
            response.raise_for_status()
            result = response.json()
            
            if "Red" in result.get("response", ""):
                print("Memory about calling user 'Red' already exists.")
                print(f"Agent response: {result.get('response')}")
                print("Use --force to add memory again if needed.")
                return
        except Exception as e:
            print(f"Error checking for existing memory: {e}")
            print("Will attempt to add memory anyway.")
    
    # Add memory by telling the agent to call the user Red
    memory_query = {
        "type": "general_query",
        "query": "From now on, please call me Red. This is very important to me.",
        "use_memory": True
    }
    
    try:
        print("\nAdding memory about calling user 'Red'...")
        response = requests.post(api_url, json=memory_query)
        response.raise_for_status()
        result = response.json()
        
        print(f"Response: {result.get('response')}")
        print(f"Memory ID: {result.get('memoryId', 'Not provided')}")
        
        # Verify memory was added correctly
        verify_query = {
            "type": "general_query",
            "query": "What name should I call you?",
            "use_memory": True
        }
        
        print("\nVerifying memory was added correctly...")
        response = requests.post(api_url, json=verify_query)
        response.raise_for_status()
        result = response.json()
        
        print(f"Verification response: {result.get('response')}")
        
        if "Red" in result.get("response", ""):
            print("Memory verification successful! The agent remembers to call you 'Red'.")
        else:
            print("Warning: Memory verification failed. The agent may not have stored the name preference correctly.")
            
    except Exception as e:
        print(f"Error adding memory: {e}")
        print("Please make sure the agent service is running.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add a memory about calling the user 'Red'")
    parser.add_argument("--force", action="store_true", help="Force adding memory even if it appears to exist")
    
    args = parser.parse_args()
    add_red_memory(args.force) 
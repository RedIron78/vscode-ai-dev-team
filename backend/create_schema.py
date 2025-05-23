#!/usr/bin/env python3
# Schema creation script for Weaviate database

import weaviate
from weaviate.collections.classes.config import Configure, DataType
from weaviate.collections.classes.config import VectorDistances
import time
import sys
import yaml
import os
import json

def get_config():
    # Default values
    config = {
        "weaviate": {
            "host": "localhost",
            "port": 8080,
            "grpc_port": 50051
        }
    }
    
    # First try to read from environment variables
    if os.environ.get('WEAVIATE_PORT'):
        config['weaviate']['port'] = int(os.environ.get('WEAVIATE_PORT'))
        print(f"Using port from environment: {config['weaviate']['port']}")
    if os.environ.get('WEAVIATE_GRPC_PORT'):
        config['weaviate']['grpc_port'] = int(os.environ.get('WEAVIATE_GRPC_PORT'))
        print(f"Using GRPC port from environment: {config['weaviate']['grpc_port']}")
        
    # Then try to read from the central port info file
    port_info_path = "/tmp/ai-dev-team/ports.json"
    try:
        if os.path.exists(port_info_path):
            with open(port_info_path, 'r') as f:
                port_info = json.load(f)
                if 'weaviate_port' in port_info:
                    config['weaviate']['port'] = port_info['weaviate_port']
                    print(f"Using port from central configuration: {config['weaviate']['port']}")
                if 'weaviate_grpc_port' in port_info:
                    config['weaviate']['grpc_port'] = port_info['weaviate_grpc_port']
                    print(f"Using GRPC port from central configuration: {config['weaviate']['grpc_port']}")
    except Exception as e:
        print(f"Warning: Could not load port info from {port_info_path}: {e}")
    
    # If central port info not available, try to load from config.yml
    config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'config.yml')
    try:
        with open(config_path, 'r') as f:
            yaml_config = yaml.safe_load(f)
            if yaml_config and 'weaviate' in yaml_config:
                config['weaviate'].update(yaml_config['weaviate'])
    except Exception as e:
        print(f"Warning: Could not load config.yml: {e}")
        print(f"Using default configuration for Weaviate: {config['weaviate']}")
    
    return config

def create_schema():
    print("Creating Weaviate schema for VS Code AI Dev Team...")
    
    # Get configuration
    config = get_config()
    weaviate_host = config['weaviate']['host']
    weaviate_port = config['weaviate']['port']
    
    print(f"Using Weaviate at {weaviate_host}:{weaviate_port}")
    
    # Connect to Weaviate
    client = weaviate.WeaviateClient(
        connection_params=weaviate.connect.ConnectionParams.from_url(
            url=f"http://{weaviate_host}:{weaviate_port}",
            grpc_port=config['weaviate']['grpc_port']
        )
    )
    
    try:
        # Ensure we can connect to Weaviate
        client.connect()
        print("Successfully connected to Weaviate")
    except Exception as e:
        print(f"Error connecting to Weaviate: {e}")
        print("Please ensure that Weaviate is running (check docker-compose up -d)")
        sys.exit(1)

    # Check if the collection already exists - if it does, just use it
    try:
        collections = client.collections.list_all()
        collection_names = [c.name for c in collections]
        print(f"Found collections: {', '.join(collection_names) if collection_names else 'none'}")
        
        if "AgentMemory" in collection_names:
            print("AgentMemory collection already exists - will use existing collection")
            # We won't delete existing collection to prevent data loss
            client.close()
            print("Schema verification completed successfully!")
            sys.exit(0)  # Exit with success code since we can use existing collection
    except Exception as e:
        print(f"Warning during collection check: {e}")
        # Continue with creation attempt

    # Create the AgentMemory collection
    try:
        agent_memory = client.collections.create(
            name="AgentMemory",
            description="Memory storage for VS Code AI Dev Team agents",
            vectorizer_config=Configure.Vectorizer.none(),
            vector_index_config=Configure.VectorIndex.hnsw(
                distance_metric=VectorDistances.COSINE
            ),
            properties=[
                {
                    "name": "text",
                    "description": "The text content of the memory",
                    "data_type": DataType.TEXT,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "role",
                    "description": "The role of the agent that created this memory",
                    "data_type": DataType.TEXT,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "tag",
                    "description": "Tags to categorize the memory",
                    "data_type": DataType.TEXT_ARRAY,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "timestamp",
                    "description": "When the memory was created",
                    "data_type": DataType.DATE,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "agentId",
                    "description": "ID of the agent that created this memory",
                    "data_type": DataType.TEXT,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "priority",
                    "description": "Priority level of this memory (1-5)",
                    "data_type": DataType.INT,
                    "indexFilterable": True
                },
                {
                    "name": "status",
                    "description": "Status of this memory (active, pending, completed, archived, failed)",
                    "data_type": DataType.TEXT,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "relatedAgents",
                    "description": "IDs of other agents related to this memory",
                    "data_type": DataType.TEXT_ARRAY,
                    "indexFilterable": True
                },
                {
                    "name": "contextId",
                    "description": "Context ID to group related memories",
                    "data_type": DataType.TEXT,
                    "indexFilterable": True,
                    "indexSearchable": True
                },
                {
                    "name": "metadata",
                    "description": "Additional metadata about this memory (JSON string)",
                    "data_type": DataType.TEXT,
                    "indexSearchable": True
                },
                {
                    "name": "expiryDate",
                    "description": "When this memory should expire (if applicable)",
                    "data_type": DataType.DATE,
                    "indexFilterable": True
                }
            ]
        )
        
        print("Successfully created AgentMemory collection")
        
    except Exception as e:
        # Check if the error is due to the collection already existing
        if "already exists" in str(e) or "class name AgentMemory already exists" in str(e):
            print("Collection AgentMemory already exists! Using existing collection.")
            client.close()
            print("Schema verification completed successfully!")
            sys.exit(0)  # Exit with success code since we can use existing collection
        else:
            print(f"Error creating schema: {e}")
            client.close()
            sys.exit(1)
    
    # Close the client
    client.close()
    
    print("Schema creation completed successfully!")
    print("You can now use the VS Code AI Dev Team with memory enabled.")

if __name__ == "__main__":
    create_schema() 
import weaviate
import json
import sys
import os
from datetime import datetime
from weaviate.classes import query
from weaviate.collections.classes.config import VectorDistances
from sentence_transformers import SentenceTransformer

# Add the project root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from backend.port_utils import get_weaviate_config

# Function to generate embedding
def generate_embedding(text, model):
    return model.encode(text)

# Get Weaviate configuration
config = get_weaviate_config()
print(f"Connecting to Weaviate at {config['host']}:{config['port']} (gRPC: {config['grpc_port']})")

# Connect to Weaviate
client = weaviate.WeaviateClient(
    connection_params=weaviate.connect.ConnectionParams.from_url(
        url=f"http://{config['host']}:{config['port']}",
        grpc_port=config['grpc_port']
    )
)
client.connect()

try:
    # Initialize embedding model
    model = SentenceTransformer('all-MiniLM-L6-v2')
    
    # Get the AgentMemory collection
    collection = client.collections.get('AgentMemory')
    print('Successfully connected to AgentMemory collection')
    
    # Test memory text
    memory_text = "User: Please call me Captain from now on.\nAgent: I'll remember to call you Captain. How can I help you today, Captain?"
    
    # Generate embedding
    embedding = generate_embedding(memory_text, model)
    
    # Create properties
    properties = {
        "text": memory_text,
        "role": "vscode_assistant",
        "tag": ["vscode", "interaction", "name_preference"],
        "timestamp": datetime.now().isoformat() + "Z",
        "agentId": "vscode_agent",
        "priority": 3,
        "status": "active",
        "contextId": "name_preference_context",
    }
    
    # Insert the test memory
    obj_uuid = collection.data.insert(
        properties=properties,
        vector=embedding
    )
    
    print(f"Added test memory with UUID: {obj_uuid}")
    print("Test memory added successfully!")
    
except Exception as e:
    print(f"Error: {e}")
finally:
    client.close() 
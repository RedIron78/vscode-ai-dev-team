import weaviate
import json
import sys
import os
from weaviate.collections.classes.config import VectorDistances
from weaviate.classes import query

# Add the project root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from backend.port_utils import get_weaviate_config

def verify_name_memories(name):
    """
    Verify that memories about a specific name preference exist in Weaviate.
    
    Args:
        name: The name to look for in memories
    """
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
        collection = client.collections.get('AgentMemory')
        print('Successfully connected to AgentMemory collection')
        
        # Search for any objects containing the name or 'call me'
        print(f'\nSearching for memories about name "{name}":')
        text_filter = query.Filter.by_property("text").contains_any([name, 'call me', 'name'])
        results = collection.query.fetch_objects(
            filters=text_filter, 
            limit=10
        )
        
        if results.objects:
            print(f"\nFound {len(results.objects)} relevant memories:")
            for i, obj in enumerate(results.objects):
                print(f'\nMemory {i+1}:')
                print(f'Text: {obj.properties.get("text")}')
                print(f'Role: {obj.properties.get("role")}')
                print(f'Tags: {obj.properties.get("tag")}')
                print(f'Agent ID: {obj.properties.get("agentId")}')
                
            print("\nName preference is successfully stored in memory")
        else:
            print(f'No memories found related to name "{name}"')
            print("Memory storage for name preference failed")
            
    except Exception as e:
        print(f'Error: {e}')
    finally:
        client.close()

if __name__ == "__main__":
    # If run directly, ask for a name to check
    name = input("Enter the name to verify in memories: ")
    verify_name_memories(name) 
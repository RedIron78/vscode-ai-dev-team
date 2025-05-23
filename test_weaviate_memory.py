import weaviate
import json
import sys
import os
from weaviate.collections.classes.config import VectorDistances
from weaviate.classes import query
from sentence_transformers import SentenceTransformer

# Add the project root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from backend.port_utils import get_weaviate_config

# Function to generate embeddings
def generate_embedding(text, model):
    return model.encode(text)

def test_memory():
    print("Testing Weaviate memory...")
    
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
        # Get the AgentMemory collection
        collection = client.collections.get('AgentMemory')
        print('Successfully connected to AgentMemory collection')
        
        # Initialize embedding model
        model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Get all memories
        print("\nRetrieving all memory objects:")
        results = collection.query.fetch_objects(limit=50)
        
        if results.objects:
            print(f"\nFound {len(results.objects)} total memories:")
            for i, obj in enumerate(results.objects):
                print(f'\nMemory {i+1}:')
                print(f'Text: {obj.properties.get("text")}')
                print(f'Role: {obj.properties.get("role")}')
                print(f'Tags: {obj.properties.get("tag")}')
        else:
            print("No memories found in the collection")
        
        # Query for the Captain memory
        print("\nSearching for memories about 'Captain':")
        text_filter = query.Filter.by_property("text").contains_any(["Captain"])
        results = collection.query.fetch_objects(
            filters=text_filter, 
            limit=5
        )
        
        if results.objects:
            print(f"Found {len(results.objects)} memories about 'Captain'")
            for i, obj in enumerate(results.objects):
                print(f'\nMemory {i+1}:')
                print(f'Text: {obj.properties.get("text")}')
                print(f'Role: {obj.properties.get("role")}')
        else:
            print("No memories found about 'Captain'")
            
        # Query for the Red memory
        print("\nSearching for memories about 'Red':")
        text_filter = query.Filter.by_property("text").contains_any(["Red"])
        results = collection.query.fetch_objects(
            filters=text_filter, 
            limit=5
        )
        
        if results.objects:
            print(f"Found {len(results.objects)} memories about 'Red'")
            for i, obj in enumerate(results.objects):
                print(f'\nMemory {i+1}:')
                print(f'Text: {obj.properties.get("text")}')
                print(f'Role: {obj.properties.get("role")}')
        else:
            print("No memories found about 'Red'")
            
        # Test semantic search with embeddings
        print("\nPerforming semantic search for 'What should I call the user?'")
        query_text = "What should I call the user?"
        
        # Generate embedding for the query
        query_embedding = generate_embedding(query_text, model)
        
        # Search using vector similarity
        results = collection.query.near_vector(
            near_vector=query_embedding,
            limit=5
        )
        
        if results.objects:
            print(f"Found {len(results.objects)} semantically relevant memories")
            for i, obj in enumerate(results.objects):
                print(f'\nResult {i+1}:')
                print(f'Text: {obj.properties.get("text")}')
                print(f'Role: {obj.properties.get("role")}')
        else:
            print("No semantically relevant memories found")
            
    except Exception as e:
        print(f'Error: {e}')
    finally:
        client.close()

if __name__ == "__main__":
    test_memory() 
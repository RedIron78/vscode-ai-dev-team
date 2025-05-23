import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "backend"))

# Force CPU usage to avoid CUDA memory issues
os.environ["CUDA_VISIBLE_DEVICES"] = ""
import torch
torch.cuda.is_available = lambda: False

from vscode_agent import VSCodeAgent
import time

def main():
    print("Creating VS Code agent for interactive test...")
    agent = VSCodeAgent(agent_id="test_agent")
    
    # First, tell the agent to call you by a specific name
    name = input("Enter the name you want the agent to call you: ")
    query = f"Please call me {name} from now on."
    print(f"\nYour Request: {query}")
    
    # Get response from agent
    response = agent.get_completion(query, use_memory=True)
    print(f"Agent Response: {response}")
    
    # Wait a moment to ensure memory is stored
    print("\nWaiting for memory to be stored...")
    time.sleep(2)
    
    # First test - ask what name the agent should call you
    print("\n--- TEST 1: Asking about name ---")
    query1 = "What name should I call you?"
    print(f"Test Query: {query1}")
    
    # Get response from agent
    response1 = agent.get_completion(query1, use_memory=True)
    print(f"Agent Response: {response1}")
    
    # Second test - see if the agent uses the name in conversation
    print("\n--- TEST 2: Normal conversation ---")
    query2 = "Just say good morning to me."
    print(f"Test Query: {query2}")
    
    # Get response from agent
    response2 = agent.get_completion(query2, use_memory=True)
    print(f"Agent Response: {response2}")
    
    # Verify in Weaviate memory
    print("\n--- Checking Weaviate memory storage ---")
    # Import the memory verification function
    from query_memories import verify_name_memories
    verify_name_memories(name)
    
if __name__ == "__main__":
    main() 
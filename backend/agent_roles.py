import os
import json
from datetime import datetime, timedelta
from sentence_transformers import SentenceTransformer
import weaviate
from weaviate.collections import Collection
from weaviate.util import generate_uuid5
from weaviate.classes import query
from weaviate.collections.classes.config import DataType
from dotenv import load_dotenv
from uuid import uuid4
import numpy as np
from enum import Enum
from typing import Optional, List, Dict, Union

class Status(Enum):
    ACTIVE = "active"
    PENDING = "pending"
    COMPLETED = "completed"
    ARCHIVED = "archived"
    FAILED = "failed"

class Priority(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    URGENT = 4
    CRITICAL = 5

# Define the Agent class (common functionality for all agents)
class Agent:
    def __init__(self, agent_id, role):
        self.agent_id = agent_id
        self.role = role
        self.model_name = "all-MiniLM-L6-v2"  # Default embedding model
        load_dotenv()
        
        # Initialize embedding model
        self.model = SentenceTransformer(self.model_name)
        print(f"Initializing {role} agent...")
        
        # Connect to Weaviate
        self.client = weaviate.WeaviateClient(
            connection_params=weaviate.connect.ConnectionParams.from_url(
                url="http://localhost:8080",
                grpc_port=50051
            )
        )
        self.client.connect()
        
        # Get collection
        try:
            self.collection = self.client.collections.get("AgentMemory")
            print(f"Connected to AgentMemory collection")
        except Exception as e:
            print(f"Error connecting to AgentMemory collection: {e}")
            print("Please run create_schema.py first to set up the Weaviate schema.")
            raise

    def __del__(self):
        # Clean up resources
        if hasattr(self, 'client'):
            self.client.close()
    
    def _generate_embedding(self, text):
        """Generate an embedding vector for the text"""
        return self.model.encode(text)
    
    def add_memory(self, text, tag=None, priority=Priority.MEDIUM, status=Status.ACTIVE, 
                  related_agents=None, context_id=None, metadata=None, 
                  expiry_days=None, source=None):
        """Add a memory to the agent's memory store"""
        if tag and not isinstance(tag, list):
            tag = [tag]
        
        if related_agents and not isinstance(related_agents, list):
            related_agents = [related_agents]
            
        # Format timestamp in RFC3339 format
        timestamp = datetime.now().isoformat() + "Z"
        
        # Calculate expiry date if provided
        expiry_date = None
        if expiry_days:
            expiry_date = (datetime.now() + timedelta(days=expiry_days)).isoformat() + "Z"
            
        # Convert metadata to string if it's a dict
        if metadata and isinstance(metadata, dict):
            metadata = json.dumps(metadata)
            
        # Generate embedding
        embedding = self._generate_embedding(text)
            
        # Create the object in Weaviate
        properties = {
            "text": text,
            "role": self.role,
            "tag": tag,
            "timestamp": timestamp,
            "agentId": self.agent_id,
            "priority": priority.value if isinstance(priority, Priority) else priority,
            "status": status.value if isinstance(status, Status) else status,
            "relatedAgents": related_agents,
            "contextId": context_id,
            "metadata": metadata,
            "expiryDate": expiry_date,
            "source": source
        }
        
        obj_uuid = self.collection.data.insert(
            properties=properties,
            vector=embedding
        )
        
        print(f"Added memory with UUID: {obj_uuid}")
        return obj_uuid, context_id or str(uuid4())
    
    def search_memory(self, query_text, limit=5, filter_obj=None):
        """
        Search memories based on semantic similarity
        filter_obj: Optional filter dictionary with supported operators like "where_text_contains" 
        """
        embedding = self._generate_embedding(query_text)
        
        # Build the query
        if filter_obj:
            filters = None
            if 'status' in filter_obj:
                status_val = filter_obj['status'].value if isinstance(filter_obj['status'], Status) else filter_obj['status']
                filters = query.Filter.by_property("status").equal(status_val)
                
            if 'priority' in filter_obj:
                priority_val = filter_obj['priority'].value if isinstance(filter_obj['priority'], Priority) else filter_obj['priority']
                priority_filter = query.Filter.by_property("priority").equal(priority_val)
                filters = priority_filter if filters is None else filters & priority_filter
                
            if 'agent_id' in filter_obj:
                agent_filter = query.Filter.by_property("agentId").equal(filter_obj['agent_id'])
                filters = agent_filter if filters is None else filters & agent_filter
                
            if 'context_id' in filter_obj:
                context_filter = query.Filter.by_property("contextId").equal(filter_obj['context_id'])
                filters = context_filter if filters is None else filters & context_filter
                
            result = self.collection.query.near_vector(
                near_vector=embedding,
                limit=limit,
                filters=filters
            )
        else:
            result = self.collection.query.near_vector(
                near_vector=embedding,
                limit=limit
            )
        
        # Return formatted results
        return [obj.properties for obj in result.objects]
    
    def update_memory_status(self, memory_id, new_status):
        """Update the status of a memory"""
        status_val = new_status.value if isinstance(new_status, Status) else new_status
        
        self.collection.data.update(
            uuid=memory_id,
            properties={
                "status": status_val
            }
        )
        print(f"Updated memory {memory_id} status to {status_val}")
    
    def delete_memory(self, memory_id):
        """Delete a memory from the store"""
        self.collection.data.delete_by_id(uuid=memory_id)
        print(f"Deleted memory {memory_id}")
    
    def get_context_memories(self, context_id):
        """Get all memories related to a specific context"""
        context_filter = query.Filter.by_property("contextId").equal(context_id)
        
        result = self.collection.query.fetch_objects(
            limit=50,
            filters=context_filter
        )
        
        return [obj.properties for obj in result.objects]

# Define specialized agent classes
class FrontendAgent(Agent):
    def __init__(self, agent_id):
        super().__init__(agent_id, "frontend")
        self.component_history = {}
        
    def build_ui_component(self, component_name, dependencies=None, priority=Priority.MEDIUM):
        """Build a new UI component"""
        text = f"Building UI component: {component_name}"
        metadata = {
            "component_type": "ui",
            "component_name": component_name,
            "dependencies": dependencies
        }
        
        # Store in memory
        obj_id, context_id = self.add_memory(
            text=text,
            tag=["component", "ui"],
            priority=priority,
            status=Status.ACTIVE,
            metadata=json.dumps(metadata),
            source="build_ui_component"
        )
        
        # Track component in history
        self.component_history[component_name] = {
            "memory_id": obj_id,
            "context_id": context_id,
            "status": Status.ACTIVE,
            "created_at": datetime.now().isoformat(),
            "dependencies": dependencies
        }
        
        # If this component depends on backend services, detect them
        if dependencies:
            self._check_backend_dependencies(dependencies, context_id)
        
        print(f"Started building UI component: {component_name}")
        return context_id
    
    def _check_backend_dependencies(self, dependencies, context_id):
        """Check if backend dependencies are available"""
        for dep in dependencies:
            # Add a memory about requiring this dependency
            self.add_memory(
                text=f"Checking backend dependency: {dep}",
                tag=["dependency", "backend"],
                status=Status.PENDING,
                related_agents=["backend"],
                context_id=context_id,
                priority=Priority.HIGH,
                source="dependency_check"
            )
    
    def update_component_status(self, component_name, new_status):
        """Update the status of a component"""
        if component_name in self.component_history:
            memory_id = self.component_history[component_name]["memory_id"]
            self.update_memory_status(memory_id, new_status)
            self.component_history[component_name]["status"] = new_status
            print(f"Updated component {component_name} status to {new_status.value}")
        else:
            print(f"Component {component_name} not found in history")

class BackendAgent(Agent):
    def __init__(self, agent_id):
        super().__init__(agent_id, "backend")
        self.database_schema = {}
        
    def process_database_query(self, query, priority=Priority.MEDIUM):
        """Process a database query"""
        text = f"Processing database query: {query}"
        
        # Extract table name from simple CREATE queries (basic parsing)
        table_name = None
        if "CREATE TABLE" in query.upper():
            parts = query.split("CREATE TABLE")[1].strip()
            if "IF NOT EXISTS" in parts.upper():
                parts = parts.split("IF NOT EXISTS")[1].strip()
            table_name = parts.split(" ")[0].strip().strip('`').strip('"')
            
        metadata = {
            "query_type": "database",
            "raw_query": query,
            "table": table_name
        }
        
        # Store in memory
        obj_id, context_id = self.add_memory(
            text=text,
            tag=["database", "query"],
            priority=priority,
            status=Status.ACTIVE,
            metadata=json.dumps(metadata),
            source="database_query"
        )
        
        # Update our database schema tracking if we're creating a table
        if table_name:
            self.database_schema[table_name] = {
                "last_modified": datetime.now().isoformat(),
                "memory_id": obj_id
            }
            
        print(f"Processed database query for table: {table_name}")
        return context_id
        
    def create_api_endpoint(self, endpoint_name, method, response_model=None, priority=Priority.MEDIUM):
        """Create a new API endpoint"""
        text = f"Creating API endpoint: {method.upper()} {endpoint_name}"
        
        metadata = {
            "endpoint": endpoint_name,
            "method": method,
            "response_model": response_model
        }
        
        # Store in memory
        obj_id, context_id = self.add_memory(
            text=text,
            tag=["api", "endpoint"],
            priority=priority,
            status=Status.ACTIVE,
            metadata=json.dumps(metadata),
            source="create_api_endpoint"
        )
        
        print(f"Created API endpoint: {method.upper()} {endpoint_name}")
        return context_id

class QAAgent(Agent):
    def __init__(self, agent_id):
        super().__init__(agent_id, "qa")
        
    def create_test_case(self, feature_name, test_description, priority=Priority.MEDIUM):
        """Create a new test case"""
        text = f"Creating test case for {feature_name}: {test_description}"
        
        metadata = {
            "feature": feature_name,
            "description": test_description
        }
        
        # Store in memory
        obj_id, context_id = self.add_memory(
            text=text,
            tag=["test", "qa"],
            priority=priority,
            status=Status.PENDING,
            metadata=json.dumps(metadata),
            source="create_test_case"
        )
        
        print(f"Created test case for {feature_name}")
        return context_id
        
    def report_test_result(self, context_id, passed, details=None):
        """Report the result of a test case"""
        status = Status.COMPLETED if passed else Status.FAILED
        text = f"Test {'passed' if passed else 'failed'}: {details if details else ''}"
        
        metadata = {
            "passed": passed,
            "details": details
        }
        
        # Store in memory
        self.add_memory(
            text=text,
            tag=["test_result", "qa"],
            priority=Priority.HIGH,
            status=status,
            context_id=context_id,
            metadata=json.dumps(metadata),
            source="test_result"
        )
        
        print(f"Reported test result for context {context_id}: {'passed' if passed else 'failed'}")

class DevOpsAgent(Agent):
    def __init__(self, agent_id):
        super().__init__(agent_id, "devops")
        
    def deploy_service(self, service_name, version, environment="staging", priority=Priority.HIGH):
        """Deploy a service to an environment"""
        text = f"Deploying {service_name} v{version} to {environment}"
        
        metadata = {
            "service": service_name,
            "version": version,
            "environment": environment
        }
        
        # Store in memory
        obj_id, context_id = self.add_memory(
            text=text,
            tag=["deployment", "devops"],
            priority=priority,
            status=Status.ACTIVE,
            metadata=json.dumps(metadata),
            source="deploy_service"
        )
        
        print(f"Started deployment of {service_name} to {environment}")
        return context_id
        
    def report_deployment_status(self, context_id, success, details=None):
        """Report the status of a deployment"""
        status = Status.COMPLETED if success else Status.FAILED
        text = f"Deployment {'succeeded' if success else 'failed'}: {details if details else ''}"
        
        metadata = {
            "success": success,
            "details": details
        }
        
        # Store in memory
        self.add_memory(
            text=text,
            tag=["deployment_result", "devops"],
            priority=Priority.HIGH,
            status=status,
            context_id=context_id,
            metadata=json.dumps(metadata),
            source="deployment_result"
        )
        
        print(f"Reported deployment result for context {context_id}: {'success' if success else 'failed'}")

# Create agent instances
frontend_agent = FrontendAgent(agent_id="frontend_agent_01")
backend_agent = BackendAgent(agent_id="backend_agent_01")
qa_agent = QAAgent(agent_id="qa_agent_01")
devops_agent = DevOpsAgent(agent_id="devops_agent_01")

# Test agent actions with prints
print("Testing Frontend Agent...")
frontend_agent.build_ui_component("Login Form")
frontend_agent.search_memory("What UI component was built?")

print("\nTesting Backend Agent...")
backend_agent.process_database_query("SELECT * FROM users")
backend_agent.search_memory("What query was processed?")

print("\nTesting QA Agent...")
qa_agent.create_test_case("User Registration", "Test the registration process")
qa_agent.report_test_result("test_case_1", True)
qa_agent.search_memory("What test case was created?")

print("\nTesting DevOps Agent...")
devops_agent.deploy_service("API Service", "v1.2.3")
devops_agent.report_deployment_status("deployment_1", True)
devops_agent.search_memory("What service was deployed?")


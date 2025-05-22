import os
import json
from typing import Optional, List, Dict, Any, Union
from uuid import uuid4
from datetime import datetime

from llm_interface import create_llm_interface, LlamaCppInterface
from agent_roles import Agent, Status, Priority

class VSCodeAgent:
    """
    A single agent specialized for integration with VS Code IDE,
    using Mistral through llama.cpp and Weaviate for memory.
    """
    
    def __init__(
        self,
        agent_id: str = "vscode_agent",
        api_url: Optional[str] = None,
        model_name: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ):
        """Initialize the VS Code agent.
        
        Args:
            agent_id: Unique identifier for this agent
            api_url: URL of the llama.cpp server API
            model_name: Name of the model to use
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate
        """
        # Create the base agent for memory management
        self.agent = Agent(agent_id, "vscode_assistant")
        
        # Initialize LLM interface
        self.llm = create_llm_interface(
            api_url=api_url,
            model_name=model_name,
            temperature=temperature,
            max_tokens=max_tokens
        )
        
        # Check if LLM is accessible
        self.llm_available = self.llm.is_available()
        if not self.llm_available:
            print(f"Warning: LLM is not available. Agent {agent_id} will operate with Weaviate memory only.")
            print(f"LLM features will return simulated responses for demonstration purposes.")
    
    def get_completion(
        self, 
        prompt: str, 
        system_prompt: Optional[str] = None,
        use_memory: bool = True,
        memory_query: Optional[str] = None,
        memory_limit: int = 5,
        **kwargs
    ) -> str:
        """Get a completion from the LLM with optional memory context.
        
        Args:
            prompt: The user's prompt/question
            system_prompt: Optional system prompt to guide model behavior
            use_memory: Whether to use memory context
            memory_query: Query to find relevant memories (defaults to prompt if None)
            memory_limit: Maximum number of memories to include
            **kwargs: Additional parameters to pass to the LLM
            
        Returns:
            The generated text as a string
        """
        if not self.llm_available:
            return f"[Simulated LLM response for: {prompt}] This is a demo response since LLM is not available."
        
        # Include memory context if requested
        memory_context = []
        if use_memory:
            query = memory_query or prompt
            memory_context = self.agent.search_memory(query, limit=memory_limit)
        
        # Construct enhanced prompt with memory context
        enhanced_prompt = prompt
        if memory_context:
            context_str = self._format_memories_as_context(memory_context)
            enhanced_prompt = f"Context from your memory:\n{context_str}\n\nUser Query: {prompt}"
        
        # Get completion from LLM
        response = self.llm.get_completion(enhanced_prompt, system_prompt, **kwargs)
        
        # Store the interaction in memory
        self.store_interaction(prompt, response, system_prompt)
        
        return response
    
    def _format_memories_as_context(self, memories: List[Dict[str, Any]]) -> str:
        """Format a list of memory objects as a context string for the LLM."""
        context_items = []
        
        for i, memory in enumerate(memories):
            # Format timestamp if present
            timestamp = memory.get("timestamp", "")
            if timestamp:
                try:
                    # Parse ISO format timestamp and format it nicely
                    dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
                    timestamp = dt.strftime("%Y-%m-%d %H:%M:%S")
                except (ValueError, TypeError):
                    pass
            
            # Format memory as a context item
            context_items.append(
                f"Memory #{i+1} [{timestamp}]:\n"
                f"Text: {memory.get('text', '')}\n"
                f"Tags: {', '.join(memory.get('tag', []))}"
            )
        
        return "\n\n".join(context_items)
    
    def store_interaction(
        self, 
        prompt: str, 
        response: str, 
        system_prompt: Optional[str] = None,
        tags: List[str] = ["vscode", "interaction"],
    ) -> str:
        """Store an interaction in memory.
        
        Args:
            prompt: The user's prompt
            response: The agent's response
            system_prompt: System prompt used (if any)
            tags: Tags to categorize this memory
            
        Returns:
            The memory UUID
        """
        memory_id, _ = self.agent.add_memory(
            text=f"User: {prompt}\nAgent: {response}",
            tag=tags,
            status=Status.COMPLETED,
            metadata=json.dumps({
                "prompt": prompt,
                "response": response,
                "system_prompt": system_prompt,
                "timestamp": datetime.now().isoformat()
            })
        )
        return memory_id
    
    def code_completion(
        self,
        code_context: str,
        file_type: str,
        request: str,
        **kwargs
    ) -> str:
        """Generate code completion based on context and request.
        
        Args:
            code_context: The surrounding code context
            file_type: The type of file (e.g., 'python', 'javascript')
            request: What the user is asking for
            **kwargs: Additional parameters for the LLM
            
        Returns:
            Generated code completion
        """
        system_prompt = (
            "You are an expert coding assistant specialized in providing precise and idiomatic "
            f"code in {file_type}. Complete or modify the code according to the user's request. "
            "Provide only the exact code without explanations or markdown formatting."
        )
        
        prompt = f"Given this code context:\n```{file_type}\n{code_context}\n```\n\nRequest: {request}"
        
        # Use memory to find similar coding patterns
        return self.get_completion(
            prompt=prompt,
            system_prompt=system_prompt,
            memory_query=f"{file_type} code {request}",
            **kwargs
        )
    
    def code_explanation(
        self,
        code: str,
        file_type: str,
        **kwargs
    ) -> str:
        """Explain a piece of code.
        
        Args:
            code: The code to explain
            file_type: The type of file
            **kwargs: Additional parameters for the LLM
            
        Returns:
            Explanation of the code
        """
        system_prompt = (
            "You are an expert code explainer. Break down the given code into understandable parts, "
            "explaining what each section does in plain language. Focus on the purpose, logic, and any "
            "important patterns or idioms used."
        )
        
        prompt = f"Please explain this {file_type} code:\n```{file_type}\n{code}\n```"
        
        return self.get_completion(
            prompt=prompt,
            system_prompt=system_prompt,
            **kwargs
        )
    
    def suggest_improvements(
        self,
        code: str,
        file_type: str,
        **kwargs
    ) -> str:
        """Suggest improvements for a piece of code.
        
        Args:
            code: The code to improve
            file_type: The type of file
            **kwargs: Additional parameters for the LLM
            
        Returns:
            Suggested improvements
        """
        system_prompt = (
            "You are an expert code reviewer and optimizer. Analyze the given code and suggest improvements "
            "for readability, performance, maintainability, and best practices. Provide specific, actionable "
            "suggestions with example code where appropriate."
        )
        
        prompt = f"Please suggest improvements for this {file_type} code:\n```{file_type}\n{code}\n```"
        
        return self.get_completion(
            prompt=prompt,
            system_prompt=system_prompt,
            **kwargs
        )
    
    def search_memory(
        self,
        query: str,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """Search the agent's memory for relevant items.
        
        Args:
            query: The search query
            limit: Maximum number of results to return
            
        Returns:
            A list of memory objects
        """
        return self.agent.search_memory(query, limit=limit)
    
    def clear_recent_memory(self, limit: int = 10) -> int:
        """Clear the most recent memories.
        
        Args:
            limit: Maximum number of memories to clear
            
        Returns:
            Number of memories cleared
        """
        recent_memories = self.agent.search_memory("", sort_by="created_at", limit=limit)
        count = 0
        
        for memory in recent_memories:
            memory_id = memory.get("id")
            if memory_id:
                self.agent.delete_memory(memory_id)
                count += 1
                
        return count 
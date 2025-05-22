import requests
import json
import os
from typing import Dict, List, Optional, Union, Any

class LlamaCppInterface:
    """Interface for communicating with llama.cpp server running Mistral or other models."""
    
    def __init__(
        self, 
        api_url: str = None, 
        model_name: str = None,
        temperature: float = 0.7,
        max_tokens: int = 512,
        top_p: float = 0.95,
    ):
        """Initialize the LlamaCpp interface.
        
        Args:
            api_url: The URL of the API.
            model_name: The name of the model to use.
            temperature: The temperature to use for sampling.
            max_tokens: The maximum number of tokens to generate.
            top_p: The top_p value to use for sampling.
        """
        # Use environment variables if provided, with suitable fallbacks
        api_url = api_url or os.environ.get("VSCODE_AGENT_LLM_URL", 
                 os.environ.get("LLAMA_CPP_API_URL", "http://localhost:8081/v1"))
        model_name = model_name or os.environ.get("LLAMA_CPP_MODEL", "openchat")
        
        self.api_url = api_url
        self.model_name = model_name
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.top_p = top_p
        
    def _build_prompt(self, system_prompt: Optional[str], user_prompt: str) -> List[Dict[str, str]]:
        """Build a prompt in the expected format for the API."""
        messages = []
        
        # Add system prompt if provided
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
            
        # Add user prompt
        messages.append({"role": "user", "content": user_prompt})
        
        return messages
    
    def call(
        self, 
        prompt: str, 
        system_prompt: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        top_p: Optional[float] = None,
        stop: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Call the LLM with the given prompt.
        
        Args:
            prompt: The user's prompt/question
            system_prompt: Optional system prompt to guide model behavior
            temperature: Override default temperature
            max_tokens: Override default max_tokens
            top_p: Override default top_p
            stop: Optional list of stop sequences
            
        Returns:
            Dictionary containing the model's response
        """
        # Use instance defaults unless overridden
        temperature = temperature if temperature is not None else self.temperature
        max_tokens = max_tokens if max_tokens is not None else self.max_tokens
        top_p = top_p if top_p is not None else self.top_p
        
        # Build request data
        request_data = {
            "model": self.model_name,
            "messages": self._build_prompt(system_prompt, prompt),
            "temperature": temperature,
            "max_tokens": max_tokens,
            "top_p": top_p,
        }
        
        # Add stop sequences if provided
        if stop:
            request_data["stop"] = stop
            
        try:
            # Make API request
            url = f"{self.api_url}/chat/completions"
            print(f"Calling LLM API: {url}")
            print(f"Request data: {json.dumps(request_data, indent=2)}")
            
            response = requests.post(url, json=request_data, timeout=60)
            response.raise_for_status()
            
            return response.json()
            
        except requests.RequestException as e:
            # Handle request errors
            error_msg = f"Error calling llama.cpp API: {str(e)}"
            print(f"ERROR: {error_msg}")
            return {
                "error": True,
                "message": error_msg,
                "details": str(e)
            }
    
    def get_completion(
        self, 
        prompt: str, 
        system_prompt: Optional[str] = None,
        **kwargs
    ) -> str:
        """Get just the completion text from the model.
        
        Args:
            prompt: The user's prompt/question
            system_prompt: Optional system prompt to guide model behavior
            **kwargs: Additional parameters to pass to the call method
            
        Returns:
            The generated text as a string
        """
        response = self.call(prompt, system_prompt, **kwargs)
        
        # Check for errors
        if "error" in response and response["error"]:
            return f"Error: {response.get('message', 'Unknown error')}"
            
        # Extract completion text
        try:
            return response.get("choices", [{}])[0].get("message", {}).get("content", "")
        except (KeyError, IndexError):
            return "Error: Unable to parse model response"
    
    def is_available(self) -> bool:
        """Check if the model is available."""
        try:
            # Try to get the list of models
            url = f"{self.api_url}/models"
            response = requests.get(url, timeout=5)
            return response.status_code == 200
        except requests.RequestException:
            return False

# Allow for different server configurations
def create_llm_interface(
    api_url: Optional[str] = None,
    model_name: Optional[str] = None,
    **kwargs
) -> LlamaCppInterface:
    """Create an LLM interface with environment variable overrides.
    
    Args:
        api_url: URL of the llama.cpp server API (can be overridden by LLAMA_CPP_API_URL env var)
        model_name: Name of the model to use (can be overridden by LLAMA_CPP_MODEL env var)
        **kwargs: Additional parameters to pass to LlamaCppInterface
        
    Returns:
        LlamaCppInterface instance
    """
    # Allow overriding configuration via environment variables
    api_url = api_url or os.environ.get("VSCODE_AGENT_LLM_URL", 
             os.environ.get("LLAMA_CPP_API_URL", "http://localhost:8081/v1"))
    model_name = model_name or os.environ.get("LLAMA_CPP_MODEL", "openchat")
    
    print(f"Creating LLM interface with API URL: {api_url}, model: {model_name}")
    return LlamaCppInterface(api_url=api_url, model_name=model_name, **kwargs)

# Default interface instance for easy import
default_llm = create_llm_interface() 
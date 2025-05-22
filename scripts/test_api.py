#!/usr/bin/env python3

"""
VS Code AI Dev Team - API Test Script
This script tests the backend API endpoints to ensure proper functionality
"""

import requests
import json
import time
import sys
import os
from datetime import datetime

# Configuration
API_BASE_URL = "http://localhost:5000"
LLM_API_URL = "http://localhost:8080"
TEST_RESULTS_DIR = "../test_results/api_tests"

# Create test results directory
os.makedirs(TEST_RESULTS_DIR, exist_ok=True)

# ANSI colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    ENDC = '\033[0m'
    
def print_color(text, color):
    """Print colored text to the terminal"""
    print(f"{color}{text}{Colors.ENDC}")

def log_test(test_name, passed, details=""):
    """Log test results to file and terminal"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    result = "PASS" if passed else "FAIL"
    
    # Print to terminal
    color = Colors.GREEN if passed else Colors.RED
    print_color(f"[{result}] {test_name}", color)
    if details:
        print(f"       {details}")
    
    # Log to file
    with open(f"{TEST_RESULTS_DIR}/api_test_log.txt", "a") as f:
        f.write(f"[{timestamp}] [{result}] {test_name}\n")
        if details:
            f.write(f"       {details}\n")
        f.write("\n")
    
    # Update summary
    with open(f"{TEST_RESULTS_DIR}/summary.txt", "a") as f:
        f.write(f"{result}: {test_name}\n")

def run_test(test_name, test_function, *args, **kwargs):
    """Run a test function and log results"""
    print(f"Running test: {test_name}...")
    try:
        result, details = test_function(*args, **kwargs)
        log_test(test_name, result, details)
        return result
    except Exception as e:
        log_test(test_name, False, f"Exception: {str(e)}")
        return False

def test_health_endpoint():
    """Test the health endpoint"""
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        if response.status_code == 200 and response.json().get("status") == "ok":
            return True, "Health endpoint responded with status 'ok'"
        else:
            return False, f"Health endpoint returned: {response.status_code} - {response.text}"
    except requests.exceptions.RequestException as e:
        return False, f"Failed to connect to health endpoint: {e}"

def test_llm_health():
    """Test the LLM server health"""
    try:
        response = requests.get(f"{LLM_API_URL}/v1/models", timeout=5)
        if response.status_code == 200:
            models = response.json()
            if models and len(models) > 0:
                return True, f"LLM server responded with {len(models)} model(s)"
            else:
                return False, "LLM server responded but no models found"
        else:
            return False, f"LLM server returned: {response.status_code} - {response.text}"
    except requests.exceptions.RequestException as e:
        return False, f"Failed to connect to LLM server: {e}"

def test_basic_query():
    """Test a basic query to the AI"""
    try:
        data = {
            "query": "What's your name?",
            "context": []
        }
        response = requests.post(f"{API_BASE_URL}/api/query", json=data, timeout=60)
        if response.status_code == 200 and "response" in response.json():
            return True, f"Query received response of length: {len(response.json()['response'])}"
        else:
            return False, f"Query failed with status {response.status_code}: {response.text}"
    except requests.exceptions.RequestException as e:
        return False, f"Failed to send query: {e}"

def test_code_explanation():
    """Test code explanation functionality"""
    try:
        code = """
def fibonacci(n):
    if n <= 1:
        return n
    else:
        return fibonacci(n-1) + fibonacci(n-2)
        """
        
        data = {
            "code": code,
            "language": "python"
        }
        response = requests.post(f"{API_BASE_URL}/api/explain", json=data, timeout=60)
        if response.status_code == 200 and "explanation" in response.json():
            return True, f"Code explanation received of length: {len(response.json()['explanation'])}"
        else:
            return False, f"Code explanation failed with status {response.status_code}: {response.text}"
    except requests.exceptions.RequestException as e:
        return False, f"Failed to send code explanation request: {e}"

def test_code_completion():
    """Test code completion functionality"""
    try:
        code_prompt = """
def calculate_area(radius):
    # Calculate the area of a circle
        """
        
        data = {
            "code_prompt": code_prompt,
            "language": "python"
        }
        response = requests.post(f"{API_BASE_URL}/api/complete", json=data, timeout=60)
        if response.status_code == 200 and "completion" in response.json():
            return True, f"Code completion received of length: {len(response.json()['completion'])}"
        else:
            return False, f"Code completion failed with status {response.status_code}: {response.text}"
    except requests.exceptions.RequestException as e:
        return False, f"Failed to send code completion request: {e}"

def test_code_improvement():
    """Test code improvement functionality"""
    try:
        code = """
def sort_list(lst):
    n = len(lst)
    for i in range(n):
        for j in range(0, n-i-1):
            if lst[j] > lst[j+1]:
                lst[j], lst[j+1] = lst[j+1], lst[j]
    return lst
        """
        
        data = {
            "code": code,
            "language": "python"
        }
        response = requests.post(f"{API_BASE_URL}/api/improve", json=data, timeout=60)
        if response.status_code == 200 and "improvement" in response.json():
            return True, f"Code improvement received of length: {len(response.json()['improvement'])}"
        else:
            return False, f"Code improvement failed with status {response.status_code}: {response.text}"
    except requests.exceptions.RequestException as e:
        return False, f"Failed to send code improvement request: {e}"

def main():
    """Main test function"""
    # Initialize test log
    os.makedirs(TEST_RESULTS_DIR, exist_ok=True)
    with open(f"{TEST_RESULTS_DIR}/api_test_log.txt", "w") as f:
        f.write(f"VS Code AI Dev Team API Tests - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("="*60 + "\n\n")
    
    with open(f"{TEST_RESULTS_DIR}/summary.txt", "w") as f:
        f.write(f"VS Code AI Dev Team API Test Summary - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("="*60 + "\n\n")
    
    print_color("VS Code AI Dev Team - API Tests", Colors.BLUE)
    print_color("="*50, Colors.BLUE)
    print("")
    
    # Basic connectivity tests
    run_test("Backend Health Check", test_health_endpoint)
    run_test("LLM Server Health Check", test_llm_health)
    
    # API functionality tests
    run_test("Basic Query Test", test_basic_query)
    run_test("Code Explanation Test", test_code_explanation)
    run_test("Code Completion Test", test_code_completion)
    run_test("Code Improvement Test", test_code_improvement)
    
    # Generate summary statistics
    with open(f"{TEST_RESULTS_DIR}/summary.txt", "r") as f:
        lines = f.readlines()
        passes = sum(1 for line in lines if line.startswith("PASS"))
        fails = sum(1 for line in lines if line.startswith("FAIL"))
    
    total = passes + fails
    success_rate = (passes / total) * 100 if total > 0 else 0
    
    # Append summary to file
    with open(f"{TEST_RESULTS_DIR}/summary.txt", "a") as f:
        f.write("\nTest Summary:\n")
        f.write("-"*30 + "\n")
        f.write(f"Total tests: {total}\n")
        f.write(f"Passed: {passes}\n")
        f.write(f"Failed: {fails}\n")
        f.write(f"Success rate: {success_rate:.2f}%\n")
    
    # Print summary
    print("")
    print_color("Test Summary:", Colors.BLUE)
    print_color("-"*30, Colors.BLUE)
    print(f"Total tests: {total}")
    print_color(f"Passed: {passes}", Colors.GREEN)
    print_color(f"Failed: {fails}", Colors.RED)
    print_color(f"Success rate: {success_rate:.2f}%", Colors.YELLOW)
    print("")
    print(f"Detailed logs saved to: {TEST_RESULTS_DIR}/api_test_log.txt")
    print(f"Summary saved to: {TEST_RESULTS_DIR}/summary.txt")
    print("")
    
    # Return exit code based on test results
    return 0 if fails == 0 else 1

if __name__ == "__main__":
    sys.exit(main()) 
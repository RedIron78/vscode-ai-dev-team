#!/bin/bash

# VS Code AI Dev Team - Test Automation Script
# This script automates parts of the testing process defined in TEST_PLAN.md

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display banner
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  VS Code AI Dev Team - Automated Testing             ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "config.yml" ] || [ ! -d "scripts" ]; then
    echo -e "${RED}Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Create test results directory
mkdir -p test_results

# Function to run a test and record result
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    echo "Test: $test_name" >> test_results/test_log.txt
    echo "Command: $test_command" >> test_results/test_log.txt
    echo "Expected: $expected_result" >> test_results/test_log.txt
    
    # Run the command and capture output
    eval "$test_command" > test_results/temp_output.txt 2>&1
    local exit_code=$?
    cat test_results/temp_output.txt >> test_results/test_log.txt
    
    # Check if exit code is as expected
    if [ "$exit_code" -eq 0 ]; then
        if grep -q "$expected_result" test_results/temp_output.txt; then
            echo -e "${GREEN}✅ Test passed: ${test_name}${NC}"
            echo "Result: PASS" >> test_results/test_log.txt
            echo "PASS: $test_name" >> test_results/summary.txt
        else
            echo -e "${RED}❌ Test failed: ${test_name} (Output did not match expected result)${NC}"
            echo "Result: FAIL - Output did not match expected result" >> test_results/test_log.txt
            echo "FAIL: $test_name - Output did not match expected result" >> test_results/summary.txt
        fi
    else
        echo -e "${RED}❌ Test failed: ${test_name} (Exit code: $exit_code)${NC}"
        echo "Result: FAIL - Exit code: $exit_code" >> test_results/test_log.txt
        echo "FAIL: $test_name - Exit code: $exit_code" >> test_results/summary.txt
    fi
    
    echo "" >> test_results/test_log.txt
    echo "-----------------------------------" >> test_results/test_log.txt
    echo "" >> test_results/test_log.txt
}

# Initialize test summary
echo "VS Code AI Dev Team - Test Results" > test_results/summary.txt
echo "Date: $(date)" >> test_results/summary.txt
echo "-----------------------------------" >> test_results/summary.txt
echo "" >> test_results/summary.txt

echo "Starting tests..." > test_results/test_log.txt
echo "Date: $(date)" >> test_results/test_log.txt
echo "-----------------------------------" >> test_results/test_log.txt
echo "" >> test_results/test_log.txt

# 1. Configuration Tests
echo -e "${BLUE}Running Configuration Tests...${NC}"

# 1.1 Test config.yml creation
if [ -f "config.yml" ]; then
    mv config.yml config.yml.bak
fi
run_test "Config Creation" "./start_all.sh" "Created default config.yml"
./stop_all.sh > /dev/null 2>&1
if [ -f "config.yml.bak" ]; then
    mv config.yml.bak config.yml
fi

# 2. Services Tests
echo -e "${BLUE}Running Services Tests...${NC}"

# 2.1 Test service startup
run_test "Services Startup" "./start_all.sh" "All services are now running"

# 2.2 Test service status
run_test "Services Status" "ps aux | grep -E 'llama|python'" "python"

# 2.3 Test port availability
run_test "Port Check - LLM" "curl -s http://localhost:8080/v1/models" "id"
run_test "Port Check - Backend" "curl -s http://localhost:5000/health" "status"

# Stop services after tests
./stop_all.sh > /dev/null 2>&1

# 3. LLM Tests
echo -e "${BLUE}Running LLM Tests...${NC}"

# 3.1 Start services for LLM testing
./start_all.sh > /dev/null 2>&1

# 3.2 Test basic LLM query
run_test "LLM Query" "curl -s -X POST http://localhost:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\":\"default\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hello\"}]}'" "hello"

# 3.3 Test code completion
run_test "Code Completion" "curl -s -X POST http://localhost:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\":\"default\",\"messages\":[{\"role\":\"user\",\"content\":\"Write a Python function to add two numbers\"}]}'" "def"

# Stop services after tests
./stop_all.sh > /dev/null 2>&1

# 4. Extension Tests (these would typically be done manually or with the VS Code extension testing framework)
echo -e "${YELLOW}Note: Extension tests need to be performed manually${NC}"
echo "Manual test required: Extension installation and commands" >> test_results/summary.txt

# Generate summary statistics
passes=$(grep -c "PASS:" test_results/summary.txt)
fails=$(grep -c "FAIL:" test_results/summary.txt)
total=$((passes + fails))

echo "" >> test_results/summary.txt
echo "Test Summary:" >> test_results/summary.txt
echo "-----------------------------------" >> test_results/summary.txt
echo "Total tests: $total" >> test_results/summary.txt
echo "Passed: $passes" >> test_results/summary.txt
echo "Failed: $fails" >> test_results/summary.txt
echo "Success rate: $(( (passes * 100) / total ))%" >> test_results/summary.txt

# Display summary
echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  Test Summary                                        ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""
echo -e "Total tests: $total"
echo -e "Passed: ${GREEN}$passes${NC}"
echo -e "Failed: ${RED}$fails${NC}"
echo -e "Success rate: ${YELLOW}$(( (passes * 100) / total ))%${NC}"
echo ""
echo -e "Detailed logs saved to: ${YELLOW}test_results/test_log.txt${NC}"
echo -e "Summary saved to: ${YELLOW}test_results/summary.txt${NC}"
echo ""
echo -e "${BLUE}======================================================${NC}"

exit 0 
#!/bin/bash

# VS Code AI Dev Team - Master Test Runner Script
# This script orchestrates the execution of all tests

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display banner
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  VS Code AI Dev Team - Master Test Runner            ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Create test results directory
mkdir -p test_results
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="test_results/run_${TIMESTAMP}"
mkdir -p "${REPORT_DIR}"

# Function to run a test suite and record result
run_test_suite() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}Running test suite: ${test_name}${NC}"
    echo "Test Suite: $test_name" >> "${REPORT_DIR}/master_log.txt"
    echo "Command: $test_command" >> "${REPORT_DIR}/master_log.txt"
    echo "Start Time: $(date)" >> "${REPORT_DIR}/master_log.txt"
    
    # Run the command and capture output
    eval "$test_command" > "${REPORT_DIR}/temp_output.txt" 2>&1
    local exit_code=$?
    cat "${REPORT_DIR}/temp_output.txt" >> "${REPORT_DIR}/master_log.txt"
    
    # Check if the test suite passed
    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✅ Test suite passed: ${test_name}${NC}"
        echo "Result: PASS" >> "${REPORT_DIR}/master_log.txt"
        echo "PASS: $test_name" >> "${REPORT_DIR}/summary.txt"
    else
        echo -e "${RED}❌ Test suite failed: ${test_name} (Exit code: $exit_code)${NC}"
        echo "Result: FAIL - Exit code: $exit_code" >> "${REPORT_DIR}/master_log.txt"
        echo "FAIL: $test_name - Exit code: $exit_code" >> "${REPORT_DIR}/summary.txt"
    fi
    
    echo "End Time: $(date)" >> "${REPORT_DIR}/master_log.txt"
    echo "" >> "${REPORT_DIR}/master_log.txt"
    echo "-----------------------------------" >> "${REPORT_DIR}/master_log.txt"
    echo "" >> "${REPORT_DIR}/master_log.txt"
    
    return $exit_code
}

# Initialize test summary
echo "VS Code AI Dev Team - Master Test Summary" > "${REPORT_DIR}/summary.txt"
echo "Date: $(date)" >> "${REPORT_DIR}/summary.txt"
echo "-----------------------------------" >> "${REPORT_DIR}/summary.txt"
echo "" >> "${REPORT_DIR}/summary.txt"

echo "Starting master test run..." > "${REPORT_DIR}/master_log.txt"
echo "Date: $(date)" >> "${REPORT_DIR}/master_log.txt"
echo "-----------------------------------" >> "${REPORT_DIR}/master_log.txt"
echo "" >> "${REPORT_DIR}/master_log.txt"

# Make sure all services are stopped before starting tests
echo -e "${YELLOW}Stopping any running services...${NC}"
./stop_all.sh > /dev/null 2>&1

# 1. Run the shell tests
echo -e "${BLUE}Running Shell Tests...${NC}"
chmod +x scripts/run_tests.sh
run_test_suite "Shell Tests" "./scripts/run_tests.sh"
SHELL_TESTS_RESULT=$?

# 2. Run Python API tests (if shell tests succeeded)
echo -e "${BLUE}Running Python API Tests...${NC}"
chmod +x scripts/test_api.py
run_test_suite "Python API Tests" "cd scripts && ./test_api.py"
API_TESTS_RESULT=$?

# 3. Run VS Code extension tests (requires more setup)
echo -e "${BLUE}Running VS Code Extension Tests...${NC}"
run_test_suite "VS Code Extension Tests" "cd extension && npm test"
EXTENSION_TESTS_RESULT=$?

# Generate summary statistics
passes=$(grep -c "PASS:" "${REPORT_DIR}/summary.txt")
fails=$(grep -c "FAIL:" "${REPORT_DIR}/summary.txt")
total=$((passes + fails))

echo "" >> "${REPORT_DIR}/summary.txt"
echo "Test Suite Summary:" >> "${REPORT_DIR}/summary.txt"
echo "-----------------------------------" >> "${REPORT_DIR}/summary.txt"
echo "Total test suites: $total" >> "${REPORT_DIR}/summary.txt"
echo "Passed: $passes" >> "${REPORT_DIR}/summary.txt"
echo "Failed: $fails" >> "${REPORT_DIR}/summary.txt"
echo "Success rate: $(( (passes * 100) / total ))%" >> "${REPORT_DIR}/summary.txt"

# Add individual test results
echo "" >> "${REPORT_DIR}/summary.txt"
echo "Individual Test Results:" >> "${REPORT_DIR}/summary.txt"
echo "-----------------------------------" >> "${REPORT_DIR}/summary.txt"

# Collect Shell test results
if [ -f "test_results/summary.txt" ]; then
    echo "Shell Tests:" >> "${REPORT_DIR}/summary.txt"
    cat test_results/summary.txt >> "${REPORT_DIR}/summary.txt"
    echo "" >> "${REPORT_DIR}/summary.txt"
fi

# Collect API test results
if [ -f "test_results/api_tests/summary.txt" ]; then
    echo "API Tests:" >> "${REPORT_DIR}/summary.txt"
    cat test_results/api_tests/summary.txt >> "${REPORT_DIR}/summary.txt"
    echo "" >> "${REPORT_DIR}/summary.txt"
fi

# Display summary
echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  Test Summary                                        ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""
echo -e "Total test suites: $total"
echo -e "Passed: ${GREEN}$passes${NC}"
echo -e "Failed: ${RED}$fails${NC}"
echo -e "Success rate: ${YELLOW}$(( (passes * 100) / total ))%${NC}"
echo ""
echo -e "Test results saved to: ${YELLOW}${REPORT_DIR}${NC}"
echo ""

# Display individual test suite results
echo -e "${BLUE}Individual Test Suite Results:${NC}"
if [ $SHELL_TESTS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Shell Tests: PASSED${NC}"
else
    echo -e "${RED}❌ Shell Tests: FAILED${NC}"
fi

if [ $API_TESTS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Python API Tests: PASSED${NC}"
else
    echo -e "${RED}❌ Python API Tests: FAILED${NC}"
fi

if [ $EXTENSION_TESTS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ VS Code Extension Tests: PASSED${NC}"
else
    echo -e "${RED}❌ VS Code Extension Tests: FAILED${NC}"
fi

echo ""
echo -e "${BLUE}======================================================${NC}"

# Create an HTML report
cat > "${REPORT_DIR}/report.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VS Code AI Dev Team - Test Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #333;
        }
        .pass {
            color: green;
        }
        .fail {
            color: red;
        }
        .summary {
            margin: 20px 0;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px 15px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>VS Code AI Dev Team - Test Report</h1>
    <p>Report generated on: $(date)</p>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p>Total test suites: $total</p>
        <p>Passed: <span class="pass">$passes</span></p>
        <p>Failed: <span class="fail">$fails</span></p>
        <p>Success rate: $(( (passes * 100) / total ))%</p>
    </div>
    
    <h2>Test Suite Results</h2>
    <table>
        <tr>
            <th>Test Suite</th>
            <th>Result</th>
        </tr>
        <tr>
            <td>Shell Tests</td>
            <td class="$([ $SHELL_TESTS_RESULT -eq 0 ] && echo 'pass' || echo 'fail')">
                $([ $SHELL_TESTS_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')
            </td>
        </tr>
        <tr>
            <td>Python API Tests</td>
            <td class="$([ $API_TESTS_RESULT -eq 0 ] && echo 'pass' || echo 'fail')">
                $([ $API_TESTS_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')
            </td>
        </tr>
        <tr>
            <td>VS Code Extension Tests</td>
            <td class="$([ $EXTENSION_TESTS_RESULT -eq 0 ] && echo 'pass' || echo 'fail')">
                $([ $EXTENSION_TESTS_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')
            </td>
        </tr>
    </table>
    
    <h2>Individual Test Results</h2>
    <pre>
$(cat "${REPORT_DIR}/summary.txt")
    </pre>
</body>
</html>
EOF

echo -e "${GREEN}HTML report generated: ${REPORT_DIR}/report.html${NC}"

# Return overall success/failure
if [ $fails -eq 0 ]; then
    exit 0
else
    exit 1
fi 
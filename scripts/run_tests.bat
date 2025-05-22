@echo off
REM VS Code AI Dev Team - Test Automation Script
REM This script automates parts of the testing process defined in TEST_PLAN.md
setlocal EnableDelayedExpansion

REM Display banner
echo ======================================================
echo  VS Code AI Dev Team - Automated Testing
echo ======================================================
echo.

REM Check if we're in the right directory
if not exist "config.yml" (
    if not exist "scripts" (
        echo Error: Please run this script from the project root directory
        exit /b 1
    )
)

REM Create test results directory
if not exist test_results mkdir test_results

REM Function to run a test and record result
:run_test
set "test_name=%~1"
set "test_command=%~2"
set "expected_result=%~3"

echo Running test: %test_name%
echo Test: %test_name% >> test_results\test_log.txt
echo Command: %test_command% >> test_results\test_log.txt
echo Expected: %expected_result% >> test_results\test_log.txt

REM Run the command and capture output
%test_command% > test_results\temp_output.txt 2>&1
set exit_code=%ERRORLEVEL%
type test_results\temp_output.txt >> test_results\test_log.txt

REM Check if exit code is as expected
if %exit_code% EQU 0 (
    findstr /c:"%expected_result%" test_results\temp_output.txt > nul
    if !ERRORLEVEL! EQU 0 (
        echo [92m✅ Test passed: %test_name%[0m
        echo Result: PASS >> test_results\test_log.txt
        echo PASS: %test_name% >> test_results\summary.txt
    ) else (
        echo [91m❌ Test failed: %test_name% (Output did not match expected result)[0m
        echo Result: FAIL - Output did not match expected result >> test_results\test_log.txt
        echo FAIL: %test_name% - Output did not match expected result >> test_results\summary.txt
    )
) else (
    echo [91m❌ Test failed: %test_name% (Exit code: %exit_code%)[0m
    echo Result: FAIL - Exit code: %exit_code% >> test_results\test_log.txt
    echo FAIL: %test_name% - Exit code: %exit_code% >> test_results\summary.txt
)

echo. >> test_results\test_log.txt
echo ----------------------------------- >> test_results\test_log.txt
echo. >> test_results\test_log.txt

exit /b 0

REM Initialize test summary
echo VS Code AI Dev Team - Test Results > test_results\summary.txt
echo Date: %date% %time% >> test_results\summary.txt
echo ----------------------------------- >> test_results\summary.txt
echo. >> test_results\summary.txt

echo Starting tests... > test_results\test_log.txt
echo Date: %date% %time% >> test_results\test_log.txt
echo ----------------------------------- >> test_results\test_log.txt
echo. >> test_results\test_log.txt

REM 1. Configuration Tests
echo [94mRunning Configuration Tests...[0m

REM 1.1 Test config.yml creation
if exist "config.yml" (
    move /y config.yml config.yml.bak > nul
)
call :run_test "Config Creation" "call start_all.bat" "Created default config.yml"
call stop_all.bat > nul 2>&1
if exist "config.yml.bak" (
    move /y config.yml.bak config.yml > nul
)

REM 2. Services Tests
echo [94mRunning Services Tests...[0m

REM 2.1 Test service startup
call :run_test "Services Startup" "call start_all.bat" "All services are now running"

REM 2.2 Test service status
call :run_test "Services Status" "tasklist | findstr python" "python"

REM 2.3 Test port availability
call :run_test "Port Check - LLM" "curl -s http://localhost:8081/v1/models" "id"
call :run_test "Port Check - Backend" "curl -s http://localhost:5000/health" "status"

REM Stop services after tests
call stop_all.bat > nul 2>&1

REM 3. LLM Tests
echo [94mRunning LLM Tests...[0m

REM 3.1 Start services for LLM testing
call start_all.bat > nul 2>&1

REM 3.2 Test basic LLM query
call :run_test "LLM Query" "curl -s -X POST http://localhost:8081/v1/chat/completions -H \"Content-Type: application/json\" -d {\"model\":\"default\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hello\"}]}" "hello"

REM 3.3 Test code completion
call :run_test "Code Completion" "curl -s -X POST http://localhost:8081/v1/chat/completions -H \"Content-Type: application/json\" -d {\"model\":\"default\",\"messages\":[{\"role\":\"user\",\"content\":\"Write a Python function to add two numbers\"}]}" "def"

REM Stop services after tests
call stop_all.bat > nul 2>&1

REM 4. Extension Tests (these would typically be done manually or with the VS Code extension testing framework)
echo [93mNote: Extension tests need to be performed manually[0m
echo Manual test required: Extension installation and commands >> test_results\summary.txt

REM Generate summary statistics
for /f %%i in ('findstr /c:"PASS:" test_results\summary.txt ^| find /c /v ""') do set passes=%%i
for /f %%i in ('findstr /c:"FAIL:" test_results\summary.txt ^| find /c /v ""') do set fails=%%i
set /a total=passes+fails
if %total% NEQ 0 (
    set /a success_rate=(passes*100)/total
) else (
    set success_rate=0
)

echo. >> test_results\summary.txt
echo Test Summary: >> test_results\summary.txt
echo ----------------------------------- >> test_results\summary.txt
echo Total tests: %total% >> test_results\summary.txt
echo Passed: %passes% >> test_results\summary.txt
echo Failed: %fails% >> test_results\summary.txt
echo Success rate: %success_rate%%% >> test_results\summary.txt

REM Display summary
echo.
echo ======================================================
echo  Test Summary
echo ======================================================
echo.
echo Total tests: %total%
echo Passed: [92m%passes%[0m
echo Failed: [91m%fails%[0m
echo Success rate: [93m%success_rate%%%[0m
echo.
echo Detailed logs saved to: [93mtest_results\test_log.txt[0m
echo Summary saved to: [93mtest_results\summary.txt[0m
echo.
echo ======================================================

exit /b 0 
@echo off
REM VS Code AI Dev Team - Master Test Runner Script
REM This script orchestrates the execution of all tests
setlocal EnableDelayedExpansion

REM Display banner
echo ======================================================
echo  VS Code AI Dev Team - Master Test Runner
echo ======================================================
echo.

REM Create test results directory
if not exist test_results mkdir test_results
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,8%_%dt:~8,6%"
set "REPORT_DIR=test_results\run_%TIMESTAMP%"
mkdir "%REPORT_DIR%"

REM Function to run a test suite and record result
:run_test_suite
set "test_name=%~1"
set "test_command=%~2"

echo Running test suite: %test_name%
echo Test Suite: %test_name% >> "%REPORT_DIR%\master_log.txt"
echo Command: %test_command% >> "%REPORT_DIR%\master_log.txt"
echo Start Time: %date% %time% >> "%REPORT_DIR%\master_log.txt"

REM Run the command and capture output
%test_command% > "%REPORT_DIR%\temp_output.txt" 2>&1
set exit_code=%ERRORLEVEL%
type "%REPORT_DIR%\temp_output.txt" >> "%REPORT_DIR%\master_log.txt"

REM Check if the test suite passed
if %exit_code% EQU 0 (
    echo [92m✅ Test suite passed: %test_name%[0m
    echo Result: PASS >> "%REPORT_DIR%\master_log.txt"
    echo PASS: %test_name% >> "%REPORT_DIR%\summary.txt"
) else (
    echo [91m❌ Test suite failed: %test_name% (Exit code: %exit_code%)[0m
    echo Result: FAIL - Exit code: %exit_code% >> "%REPORT_DIR%\master_log.txt"
    echo FAIL: %test_name% - Exit code: %exit_code% >> "%REPORT_DIR%\summary.txt"
)

echo End Time: %date% %time% >> "%REPORT_DIR%\master_log.txt"
echo. >> "%REPORT_DIR%\master_log.txt"
echo ----------------------------------- >> "%REPORT_DIR%\master_log.txt"
echo. >> "%REPORT_DIR%\master_log.txt"

exit /b %exit_code%

REM Initialize test summary
echo VS Code AI Dev Team - Master Test Summary > "%REPORT_DIR%\summary.txt"
echo Date: %date% %time% >> "%REPORT_DIR%\summary.txt"
echo ----------------------------------- >> "%REPORT_DIR%\summary.txt"
echo. >> "%REPORT_DIR%\summary.txt"

echo Starting master test run... > "%REPORT_DIR%\master_log.txt"
echo Date: %date% %time% >> "%REPORT_DIR%\master_log.txt"
echo ----------------------------------- >> "%REPORT_DIR%\master_log.txt"
echo. >> "%REPORT_DIR%\master_log.txt"

REM Make sure all services are stopped before starting tests
echo Stopping any running services...
call stop_all.bat > nul 2>&1

REM 1. Run the shell tests
echo [94mRunning Shell Tests...[0m
call :run_test_suite "Shell Tests" "scripts\run_tests.bat"
set SHELL_TESTS_RESULT=%ERRORLEVEL%

REM 2. Run Python API tests (if shell tests succeeded)
echo [94mRunning Python API Tests...[0m
call :run_test_suite "Python API Tests" "cd scripts && python test_api.py"
set API_TESTS_RESULT=%ERRORLEVEL%

REM 3. Run VS Code extension tests (requires more setup)
echo [94mRunning VS Code Extension Tests...[0m
call :run_test_suite "VS Code Extension Tests" "cd extension && npm test"
set EXTENSION_TESTS_RESULT=%ERRORLEVEL%

REM Generate summary statistics
for /f %%i in ('findstr /c:"PASS:" "%REPORT_DIR%\summary.txt" ^| find /c /v ""') do set passes=%%i
for /f %%i in ('findstr /c:"FAIL:" "%REPORT_DIR%\summary.txt" ^| find /c /v ""') do set fails=%%i
set /a total=passes+fails
set /a success_rate=(passes*100)/total

echo. >> "%REPORT_DIR%\summary.txt"
echo Test Suite Summary: >> "%REPORT_DIR%\summary.txt"
echo ----------------------------------- >> "%REPORT_DIR%\summary.txt"
echo Total test suites: %total% >> "%REPORT_DIR%\summary.txt"
echo Passed: %passes% >> "%REPORT_DIR%\summary.txt"
echo Failed: %fails% >> "%REPORT_DIR%\summary.txt"
echo Success rate: %success_rate%%% >> "%REPORT_DIR%\summary.txt"

REM Add individual test results
echo. >> "%REPORT_DIR%\summary.txt"
echo Individual Test Results: >> "%REPORT_DIR%\summary.txt"
echo ----------------------------------- >> "%REPORT_DIR%\summary.txt"

REM Collect Shell test results
if exist "test_results\summary.txt" (
    echo Shell Tests: >> "%REPORT_DIR%\summary.txt"
    type test_results\summary.txt >> "%REPORT_DIR%\summary.txt"
    echo. >> "%REPORT_DIR%\summary.txt"
)

REM Collect API test results
if exist "test_results\api_tests\summary.txt" (
    echo API Tests: >> "%REPORT_DIR%\summary.txt"
    type test_results\api_tests\summary.txt >> "%REPORT_DIR%\summary.txt"
    echo. >> "%REPORT_DIR%\summary.txt"
)

REM Display summary
echo.
echo ======================================================
echo  Test Summary
echo ======================================================
echo.
echo Total test suites: %total%
echo Passed: [92m%passes%[0m
echo Failed: [91m%fails%[0m
echo Success rate: [93m%success_rate%%[0m
echo.
echo Test results saved to: [93m%REPORT_DIR%[0m
echo.

REM Display individual test suite results
echo [94mIndividual Test Suite Results:[0m
if %SHELL_TESTS_RESULT% EQU 0 (
    echo [92m✅ Shell Tests: PASSED[0m
) else (
    echo [91m❌ Shell Tests: FAILED[0m
)

if %API_TESTS_RESULT% EQU 0 (
    echo [92m✅ Python API Tests: PASSED[0m
) else (
    echo [91m❌ Python API Tests: FAILED[0m
)

if %EXTENSION_TESTS_RESULT% EQU 0 (
    echo [92m✅ VS Code Extension Tests: PASSED[0m
) else (
    echo [91m❌ VS Code Extension Tests: FAILED[0m
)

echo.
echo ======================================================

REM Create an HTML report
echo ^<!DOCTYPE html^> > "%REPORT_DIR%\report.html"
echo ^<html lang="en"^> >> "%REPORT_DIR%\report.html"
echo ^<head^> >> "%REPORT_DIR%\report.html"
echo     ^<meta charset="UTF-8"^> >> "%REPORT_DIR%\report.html"
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^> >> "%REPORT_DIR%\report.html"
echo     ^<title^>VS Code AI Dev Team - Test Report^</title^> >> "%REPORT_DIR%\report.html"
echo     ^<style^> >> "%REPORT_DIR%\report.html"
echo         body { >> "%REPORT_DIR%\report.html"
echo             font-family: Arial, sans-serif; >> "%REPORT_DIR%\report.html"
echo             line-height: 1.6; >> "%REPORT_DIR%\report.html"
echo             max-width: 1200px; >> "%REPORT_DIR%\report.html"
echo             margin: 0 auto; >> "%REPORT_DIR%\report.html"
echo             padding: 20px; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         h1, h2, h3 { >> "%REPORT_DIR%\report.html"
echo             color: #333; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         .pass { >> "%REPORT_DIR%\report.html"
echo             color: green; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         .fail { >> "%REPORT_DIR%\report.html"
echo             color: red; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         .summary { >> "%REPORT_DIR%\report.html"
echo             margin: 20px 0; >> "%REPORT_DIR%\report.html"
echo             padding: 15px; >> "%REPORT_DIR%\report.html"
echo             background-color: #f8f9fa; >> "%REPORT_DIR%\report.html"
echo             border-radius: 5px; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         table { >> "%REPORT_DIR%\report.html"
echo             width: 100%%; >> "%REPORT_DIR%\report.html"
echo             border-collapse: collapse; >> "%REPORT_DIR%\report.html"
echo             margin: 20px 0; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         th, td { >> "%REPORT_DIR%\report.html"
echo             padding: 12px 15px; >> "%REPORT_DIR%\report.html"
echo             border: 1px solid #ddd; >> "%REPORT_DIR%\report.html"
echo             text-align: left; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         th { >> "%REPORT_DIR%\report.html"
echo             background-color: #4CAF50; >> "%REPORT_DIR%\report.html"
echo             color: white; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo         tr:nth-child(even) { >> "%REPORT_DIR%\report.html"
echo             background-color: #f2f2f2; >> "%REPORT_DIR%\report.html"
echo         } >> "%REPORT_DIR%\report.html"
echo     ^</style^> >> "%REPORT_DIR%\report.html"
echo ^</head^> >> "%REPORT_DIR%\report.html"
echo ^<body^> >> "%REPORT_DIR%\report.html"
echo     ^<h1^>VS Code AI Dev Team - Test Report^</h1^> >> "%REPORT_DIR%\report.html"
echo     ^<p^>Report generated on: %date% %time%^</p^> >> "%REPORT_DIR%\report.html"
echo     >> "%REPORT_DIR%\report.html"
echo     ^<div class="summary"^> >> "%REPORT_DIR%\report.html"
echo         ^<h2^>Test Summary^</h2^> >> "%REPORT_DIR%\report.html"
echo         ^<p^>Total test suites: %total%^</p^> >> "%REPORT_DIR%\report.html"
echo         ^<p^>Passed: ^<span class="pass"^>%passes%^</span^>^</p^> >> "%REPORT_DIR%\report.html"
echo         ^<p^>Failed: ^<span class="fail"^>%fails%^</span^>^</p^> >> "%REPORT_DIR%\report.html"
echo         ^<p^>Success rate: %success_rate%%%%^</p^> >> "%REPORT_DIR%\report.html"
echo     ^</div^> >> "%REPORT_DIR%\report.html"
echo     >> "%REPORT_DIR%\report.html"
echo     ^<h2^>Test Suite Results^</h2^> >> "%REPORT_DIR%\report.html"
echo     ^<table^> >> "%REPORT_DIR%\report.html"
echo         ^<tr^> >> "%REPORT_DIR%\report.html"
echo             ^<th^>Test Suite^</th^> >> "%REPORT_DIR%\report.html"
echo             ^<th^>Result^</th^> >> "%REPORT_DIR%\report.html"
echo         ^</tr^> >> "%REPORT_DIR%\report.html"
echo         ^<tr^> >> "%REPORT_DIR%\report.html"
echo             ^<td^>Shell Tests^</td^> >> "%REPORT_DIR%\report.html"
if %SHELL_TESTS_RESULT% EQU 0 (
    echo             ^<td class="pass"^>PASSED^</td^> >> "%REPORT_DIR%\report.html"
) else (
    echo             ^<td class="fail"^>FAILED^</td^> >> "%REPORT_DIR%\report.html"
)
echo         ^</tr^> >> "%REPORT_DIR%\report.html"
echo         ^<tr^> >> "%REPORT_DIR%\report.html"
echo             ^<td^>Python API Tests^</td^> >> "%REPORT_DIR%\report.html"
if %API_TESTS_RESULT% EQU 0 (
    echo             ^<td class="pass"^>PASSED^</td^> >> "%REPORT_DIR%\report.html"
) else (
    echo             ^<td class="fail"^>FAILED^</td^> >> "%REPORT_DIR%\report.html"
)
echo         ^</tr^> >> "%REPORT_DIR%\report.html"
echo         ^<tr^> >> "%REPORT_DIR%\report.html"
echo             ^<td^>VS Code Extension Tests^</td^> >> "%REPORT_DIR%\report.html"
if %EXTENSION_TESTS_RESULT% EQU 0 (
    echo             ^<td class="pass"^>PASSED^</td^> >> "%REPORT_DIR%\report.html"
) else (
    echo             ^<td class="fail"^>FAILED^</td^> >> "%REPORT_DIR%\report.html"
)
echo         ^</tr^> >> "%REPORT_DIR%\report.html"
echo     ^</table^> >> "%REPORT_DIR%\report.html"
echo     >> "%REPORT_DIR%\report.html"
echo     ^<h2^>Individual Test Results^</h2^> >> "%REPORT_DIR%\report.html"
echo     ^<pre^> >> "%REPORT_DIR%\report.html"
type "%REPORT_DIR%\summary.txt" >> "%REPORT_DIR%\report.html"
echo     ^</pre^> >> "%REPORT_DIR%\report.html"
echo ^</body^> >> "%REPORT_DIR%\report.html"
echo ^</html^> >> "%REPORT_DIR%\report.html"

echo HTML report generated: %REPORT_DIR%\report.html

exit /b 0 
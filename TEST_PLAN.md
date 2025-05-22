# VS Code AI Dev Team - Test Plan

## 1. Pre-Test Setup

- [ ] Clone repository into a clean directory
- [ ] Verify all required components are present:
  - [ ] VS Code extension
  - [ ] Python backend
  - [ ] llama.cpp integration
  - [ ] Docker and Weaviate setup
- [ ] Install and configure according to COMPLETE-GUIDE.md

## 2. Component Tests

### 2.1 Configuration System

- [ ] Test default configuration creation
  - [ ] Delete config.yml and verify it's auto-created on startup
  - [ ] Verify all default values are correctly set
- [ ] Test custom configuration
  - [ ] Modify key parameters (model, ports, memory settings)
  - [ ] Verify changes are applied correctly on restart

### 2.2 Services Startup

- [ ] Test start_all.sh script
  - [ ] Verify all services start correctly
  - [ ] Verify proper error handling for missing dependencies
  - [ ] Verify proper error handling for port conflicts
- [ ] Test individual service startup
  - [ ] Verify llama.cpp server starts in isolation
  - [ ] Verify Python backend starts in isolation
  - [ ] Verify Weaviate starts in isolation

### 2.3 LLM Integration

- [ ] Test model loading
  - [ ] Verify small model loads correctly
  - [ ] Verify medium model loads correctly
  - [ ] Verify large model loads correctly (if hardware supports)
- [ ] Test model inference
  - [ ] Verify response quality with different models
  - [ ] Verify context window limitations
  - [ ] Test GPU acceleration (if available)

### 2.4 Memory Integration

- [ ] Test Weaviate connection
  - [ ] Verify schema creation
  - [ ] Verify data persistence between sessions
- [ ] Test conversation history
  - [ ] Verify context is maintained between queries
  - [ ] Verify performance with large history

### 2.5 VS Code Extension

- [ ] Test installation
  - [ ] Verify VSIX package installs correctly
  - [ ] Verify extension activates properly
- [ ] Test commands
  - [ ] Ask AI command
  - [ ] Explain Code command
  - [ ] Complete Code command
  - [ ] Improve Code command

## 3. Integration Tests

- [ ] Test full workflow
  - [ ] Start from clean installation
  - [ ] Complete a programming task using all features
  - [ ] Verify responses are helpful and contextual

## 4. Performance Tests

- [ ] Test startup time
  - [ ] Measure time to start all services
  - [ ] Identify bottlenecks
- [ ] Test memory usage
  - [ ] Monitor RAM usage during operation
  - [ ] Test with different model sizes
- [ ] Test response times
  - [ ] Measure time for initial response
  - [ ] Measure time for subsequent responses

## 5. Edge Cases

- [ ] Test offline operation
  - [ ] Verify functionality without internet connection
- [ ] Test with minimal resources
  - [ ] Test with minimum RAM requirements
  - [ ] Test with CPU-only setup
- [ ] Test error recovery
  - [ ] Forcefully crash components and test recovery
  - [ ] Test service restart functionality

## 6. Cross-Platform Tests

- [ ] Test on Linux
  - [ ] Ubuntu (latest LTS)
  - [ ] Fedora (latest)
- [ ] Test on Windows
  - [ ] Windows 10
  - [ ] Windows 11
- [ ] Test on macOS
  - [ ] Intel Mac
  - [ ] Apple Silicon (M1/M2/M3)

## 7. Security Tests

- [ ] Verify no data leaves local environment
  - [ ] Monitor network traffic during operation
  - [ ] Verify no connections to external servers except for initial setup
- [ ] Verify Docker container isolation
  - [ ] Check container security settings
  - [ ] Verify no excessive permissions

## Test Execution Checklist

| Test Category | Status | Notes |
|--------------|--------|-------|
| Configuration |        |       |
| Services      |        |       |
| LLM           |        |       |
| Memory        |        |       |
| VS Code       |        |       |
| Integration   |        |       |
| Performance   |        |       |
| Edge Cases    |        |       |
| Cross-Platform|        |       |
| Security      |        |       |

## Test Automation

We should consider implementing automated tests for:

1. Backend API endpoints using pytest
2. Extension commands using VS Code's extension testing framework
3. Service startup scripts using bash/PowerShell test frameworks

## Test Reporting

After completing all tests, generate a comprehensive report including:

1. Test results summary
2. Identified issues with severity ratings
3. Performance benchmarks
4. Recommendations for improvements 
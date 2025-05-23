// Save this as a modified version of the file in:
// ~/.vscode/extensions/undefined_publisher.vscode-ai-dev-team-0.2.0/out/extension.js

// Find these lines (around line 469):
// headers: DEFAULT_HEADERS,
// timeout: 5000 // Add timeout to fail faster if service is not available

// Change them to:
// headers: DEFAULT_HEADERS,
// timeout: 60000 // Increased timeout for large models (from 5000ms to 60000ms)

// And find these lines (around line 493):
// headers: DEFAULT_HEADERS,
// timeout: 3000 // Shorter timeout for alternative ports

// Change them to:
// headers: DEFAULT_HEADERS,
// timeout: 30000 // Increased timeout for alternative ports (from 3000ms to 30000ms)

// Also verify these lines in backend/llm_interface.py:
// response = requests.post(url, json=request_data, timeout=60)  // This is good at 60 seconds
// response = requests.get(url, timeout=5)  // This should be increased 
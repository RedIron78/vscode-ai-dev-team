# AI Dev Team VS Code Extension

This VS Code extension integrates with the AI Dev Team infrastructure, providing AI-powered code assistance, explanations, and completions.

## Features

- **AI Chat**: Chat with the AI assistant directly in VS Code
- **Code Explanation**: Get explanations for selected code
- **Code Completion**: Generate code completions based on context
- **Code Improvement**: Get suggestions for improving your code
- **Service Management**: Start and stop AI services (Weaviate, LLM server, Agent server)

## Requirements

- VS Code 1.60.0 or higher
- Docker (for Weaviate)
- Python 3.8+ with virtual environment
- llama.cpp server

## Installation

### From VSIX

1. Download the latest `.vsix` file from the releases page
2. In VS Code, go to the Extensions view (Ctrl+Shift+X)
3. Click on the "..." menu and select "Install from VSIX..."
4. Select the downloaded `.vsix` file

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/vscode-ai-dev-team.git
   cd vscode-ai-dev-team
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Compile the extension:
   ```bash
   npm run compile
   ```

4. Package the extension:
   ```bash
   npm run package
   ```

5. Install the generated `.vsix` file in VS Code

## Usage

### Starting Services

1. Open the Command Palette (Ctrl+Shift+P)
2. Type "AI Dev Team: Start Services" and select it
3. Wait for all services to start

### Using the AI Chat

1. Click on the AI Dev Team icon in the Activity Bar
2. Type your message in the input field
3. Press Enter or click Send

### Code Explanation

1. Select the code you want to explain
2. Right-click and select "AI Dev Team: Explain Selected Code"
3. The explanation will appear in a new editor tab

### Code Completion

1. Place your cursor where you want to complete code
2. Press Ctrl+Shift+C (Cmd+Shift+C on macOS)
3. Describe what you want to generate
4. The completion will be inserted at the cursor position

### Code Improvement

1. Select the code you want to improve
2. Right-click and select "AI Dev Team: Improve Selected Code"
3. The improved code will appear in a new editor tab

## Configuration

The extension can be configured through VS Code settings:

- `aidevteam.agentApiUrl`: URL of the AI Dev Team agent API (default: http://localhost:5000/api/agent)
- `aidevteam.autoStartServices`: Automatically start AI services when extension is activated (default: false)
- `aidevteam.useMemory`: Use Weaviate memory to provide context to the AI (default: true)
- `aidevteam.llmModel`: The LLM model to use for AI capabilities (default: openchat)

## Development

### Project Structure

- `src/`: TypeScript source files
  - `extension.ts`: Main extension file
  - `agent-services.ts`: Service management functions
- `resources/`: Extension resources (icons, etc.)
- `out/`: Compiled JavaScript files

### Building

```bash
npm run compile
```

### Debugging

1. Open the project in VS Code
2. Press F5 to start debugging
3. A new VS Code window will open with the extension loaded

### Testing

```bash
npm run test
```

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request 
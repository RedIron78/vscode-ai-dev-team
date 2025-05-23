// VS Code AI Agent Extension
// TypeScript implementation converted from the JavaScript version

import * as vscode from 'vscode';
import axios from 'axios';
import * as path from 'path';
import { 
    startWeaviateService, 
    startLLMService, 
    startAgentService, 
    stopServices 
} from './agent-services';
import * as fs from 'fs';
import * as os from 'os';

// Configuration constants
// Use configuration rather than hardcoded ports
function getAgentApiUrl(): string {
  // First check if user has set a custom URL in settings
  const config = vscode.workspace.getConfiguration('aidevteam');
  const configuredUrl = config.get('agentApiUrl') as string;
  
  // Check if there's a port file we can read
  try {
    const portFilePath = path.join(os.tmpdir(), 'vscode_ai_agent_port.txt');
    if (fs.existsSync(portFilePath)) {
      const port = fs.readFileSync(portFilePath, 'utf8').trim();
      if (port && /^\d+$/.test(port)) {
        console.log(`Found port ${port} in ${portFilePath}`);
        return `http://localhost:${port}/api/agent`;
      }
    }
  } catch (error) {
    console.log('Could not read port file:', error);
  }
  
  return configuredUrl;
}
const DEFAULT_HEADERS = {
  'Content-Type': 'application/json'
};

// Track if services are running
let servicesRunning = false;

/**
 * @param {vscode.ExtensionContext} context
 */
export function activate(context: vscode.ExtensionContext) {
  console.log('AI Dev Team Agent Extension is now active');

  // Register command to check and start services
  const startServices = vscode.commands.registerCommand('aidevteam.startServices', async () => {
    if (!servicesRunning) {
      try {
        // Show progress while starting services
        await vscode.window.withProgress({
          location: vscode.ProgressLocation.Notification,
          title: "Starting AI services...",
          cancellable: false
        }, async (progress) => {
          progress.report({ message: "Starting Weaviate..." });
          await startWeaviateService();
          
          progress.report({ message: "Starting LLM server..." });
          await startLLMService();
          
          progress.report({ message: "Starting agent server..." });
          await startAgentService();
          
          servicesRunning = true;
          vscode.window.showInformationMessage('AI services started successfully!');
        });
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        vscode.window.showErrorMessage(`Failed to start AI services: ${errorMessage}`);
      }
    } else {
      vscode.window.showInformationMessage('AI services are already running');
    }
  });

  // Register AI Chat panel view
  const aiChatProvider = new AIChatViewProvider(context.extensionUri);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider('aidevteam.chatView', aiChatProvider)
  );

  // Register commands for AI interactions
  context.subscriptions.push(
    // Command to ask a general question to the AI
    vscode.commands.registerCommand('aidevteam.askAI', async () => {
      const question = await vscode.window.showInputBox({
        placeHolder: 'Ask the AI a question...',
        prompt: 'Your question to the AI'
      });
      
      if (question) {
        const response = await sendGeneralQuery(question);
        aiChatProvider.addMessage('user', question);
        aiChatProvider.addMessage('ai', response);
      }
    }),

    // Command to explain selected code
    vscode.commands.registerCommand('aidevteam.explainCode', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) {
        vscode.window.showWarningMessage('No active editor!');
        return;
      }

      const selection = editor.selection;
      const code = editor.document.getText(selection);
      
      if (!code) {
        vscode.window.showWarningMessage('No code selected!');
        return;
      }

      const fileType = editor.document.languageId;
      const response = await sendCodeExplanation(code, fileType);
      
      // Show explanation in a new editor tab
      const document = await vscode.workspace.openTextDocument({
        content: response,
        language: 'markdown'
      });
      vscode.window.showTextDocument(document);
    }),

    // Command to get code completion
    vscode.commands.registerCommand('aidevteam.completeCode', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;

      const position = editor.selection.active;
      const document = editor.document;
      const fileType = document.languageId;
      
      // Get context (50 lines before cursor or all if less than 50)
      const startLine = Math.max(0, position.line - 50);
      const range = new vscode.Range(
        new vscode.Position(startLine, 0),
        position
      );
      const codeContext = document.getText(range);
      
      // Ask for request
      const request = await vscode.window.showInputBox({
        placeHolder: 'What code would you like to complete?',
        prompt: 'Describe the code you want to generate'
      });
      
      if (!request) return;
      
      // Show progress indicator
      await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: "Generating code...",
        cancellable: true
      }, async (progress) => {
        const completion = await sendCodeCompletion(codeContext, fileType, request);
        
        // Insert the completion at cursor position
        editor.edit(editBuilder => {
          editBuilder.insert(position, completion);
        });
      });
    }),

    // Command to improve selected code
    vscode.commands.registerCommand('aidevteam.improveCode', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;

      const selection = editor.selection;
      const code = editor.document.getText(selection);
      
      if (!code) {
        vscode.window.showWarningMessage('No code selected!');
        return;
      }

      const fileType = editor.document.languageId;
      
      const improvements = await sendCodeImprovement(code, fileType);
      
      // Show diff editor with improvements
      const improvedDocument = await vscode.workspace.openTextDocument({
        content: improvements,
        language: editor.document.languageId
      });
      vscode.window.showTextDocument(improvedDocument, { viewColumn: vscode.ViewColumn.Beside });
    })
  );

  // Register the showAgentOptions command used by the status bar
  const showAgentOptions = vscode.commands.registerCommand('aidevteam.showAgentOptions', () => {
    const options = [
      { label: "Start AI Services", description: "Start all AI services", command: "aidevteam.startServices" },
      { label: "Ask AI", description: "Ask the AI a question", command: "aidevteam.askAI" },
      { label: "Explain Code", description: "Explain selected code", command: "aidevteam.explainCode" },
      { label: "Complete Code", description: "Complete the current code", command: "aidevteam.completeCode" },
      { label: "Improve Code", description: "Get suggestions to improve selected code", command: "aidevteam.improveCode" }
    ];
    
    vscode.window.showQuickPick(options, {
      placeHolder: "Select an AI action"
    }).then(selection => {
      if (selection) {
        vscode.commands.executeCommand(selection.command);
      }
    });
  });
  
  // Add to subscriptions
  context.subscriptions.push(startServices);
  context.subscriptions.push(showAgentOptions);
  
  // Add a status bar item
  const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBarItem.text = "$(robot) AI";
  statusBarItem.tooltip = "AI Dev Team Assistant";
  statusBarItem.command = "aidevteam.showAgentOptions";
  statusBarItem.show();
  context.subscriptions.push(statusBarItem);
  
  // Auto-start services if configured
  const config = vscode.workspace.getConfiguration('aidevteam');
  if (config.get('autoStartServices')) {
    vscode.commands.executeCommand('aidevteam.startServices');
  }
}

export function deactivate() {
  // Stop all services when the extension is deactivated
  try {
    stopServices();
  } catch (error) {
    console.error('Error stopping services:', error);
  }
  
  servicesRunning = false;
}

// AI Chat WebView Provider
class AIChatViewProvider implements vscode.WebviewViewProvider {
  private view: vscode.WebviewView | undefined;
  private messages: Array<{role: string, content: string}> = [];
  private extensionUri: vscode.Uri;

  constructor(extensionUri: vscode.Uri) {
    this.extensionUri = extensionUri;
  }

  resolveWebviewView(webviewView: vscode.WebviewView): void {
    this.view = webviewView;
    webviewView.webview.options = {
      enableScripts: true,
      localResourceRoots: [this.extensionUri]
    };
    
    this.updateView();
    
    // Handle messages from the webview
    webviewView.webview.onDidReceiveMessage(async (data) => {
      if (data.type === 'userMessage') {
        await this.handleUserMessage(data.value);
      }
    });
  }

  updateView(): void {
    if (this.view) {
      this.view.webview.html = this.getHtmlForWebview();
    }
  }

  addMessage(role: string, content: string): void {
    this.messages.push({ role, content });
    this.updateView();
  }

  async handleUserMessage(text: string): Promise<void> {
    this.addMessage('user', text);
    try {
      // Log request details for debugging
      console.log(`Sending request to API: ${text}`);
      
      const response = await sendGeneralQuery(text);
      this.addMessage('ai', response);
    } catch (error) {
      console.error('Error in handleUserMessage:', error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.addMessage('ai', `Sorry, I encountered an error: ${errorMessage}. Please try again later.`);
    }
  }

  getHtmlForWebview(): string {
    const messageHtml = this.messages.map(msg => {
      const className = msg.role === 'user' ? 'user-message' : 'ai-message';
      const avatar = msg.role === 'user' ? '👤' : '🤖';
      return `
        <div class="${className}">
          <div class="avatar">${avatar}</div>
          <div class="content">${this.formatMessageContent(msg.content)}</div>
        </div>
      `;
    }).join('');

    return `<!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>AI Chat</title>
      <style>
        body {
          font-family: var(--vscode-font-family);
          color: var(--vscode-editor-foreground);
          margin: 0;
          padding: 0;
        }
        .message-container {
          display: flex;
          flex-direction: column;
          padding: 10px;
          gap: 10px;
          max-height: 100vh;
          overflow-y: auto;
        }
        .user-message, .ai-message {
          display: flex;
          padding: 8px;
          border-radius: 5px;
          max-width: 100%;
        }
        .user-message {
          background-color: var(--vscode-editor-inactiveSelectionBackground);
          align-self: flex-end;
        }
        .ai-message {
          background-color: var(--vscode-editor-lineHighlightBackground);
          align-self: flex-start;
        }
        .avatar {
          margin-right: 8px;
          font-size: 1.2em;
        }
        .content {
          white-space: pre-wrap;
          word-break: break-word;
        }
        .input-area {
          display: flex;
          padding: 10px;
          position: sticky;
          bottom: 0;
          background-color: var(--vscode-editor-background);
          border-top: 1px solid var(--vscode-editor-lineHighlightBorder);
        }
        #userInput {
          flex: 1;
          padding: 8px;
          border-radius: 4px;
          border: 1px solid var(--vscode-input-border);
          background-color: var(--vscode-input-background);
          color: var(--vscode-input-foreground);
        }
        button {
          margin-left: 8px;
          background-color: var(--vscode-button-background);
          color: var(--vscode-button-foreground);
          border: none;
          padding: 8px 12px;
          border-radius: 4px;
          cursor: pointer;
        }
        button:hover {
          background-color: var(--vscode-button-hoverBackground);
        }
        code {
          font-family: var(--vscode-editor-font-family);
          background-color: var(--vscode-textCodeBlock-background);
          padding: 2px 4px;
          border-radius: 3px;
        }
        pre {
          background-color: var(--vscode-textCodeBlock-background);
          padding: 10px;
          border-radius: 5px;
          overflow-x: auto;
        }
      </style>
    </head>
    <body>
      <div class="message-container">
        ${messageHtml}
      </div>
      <div class="input-area">
        <input type="text" id="userInput" placeholder="Type your message...">
        <button id="sendButton">Send</button>
      </div>
      <script>
        const vscode = acquireVsCodeApi();
        
        document.getElementById('sendButton').addEventListener('click', sendMessage);
        document.getElementById('userInput').addEventListener('keypress', (e) => {
          if (e.key === 'Enter') {
            sendMessage();
          }
        });
        
        function sendMessage() {
          const input = document.getElementById('userInput');
          const text = input.value.trim();
          
          if (text) {
            vscode.postMessage({
              type: 'userMessage',
              value: text
            });
            
            input.value = '';
          }
        }
        
        // Scroll to bottom when messages change
        const messageContainer = document.querySelector('.message-container');
        messageContainer.scrollTop = messageContainer.scrollHeight;
      </script>
    </body>
    </html>`;
  }

  formatMessageContent(content: string): string {
    // Basic markdown-like formatting
    // Convert code blocks
    const codeBlockRegex = /```([a-zA-Z]*)\n([\s\S]*?)\n```/g;
    return content
      .replace(codeBlockRegex, (_, language, code) => {
        return `<pre><code class="language-${language}">${this.escapeHtml(code)}</code></pre>`;
      })
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\n/g, '<br>');
  }

  escapeHtml(unsafe: string): string {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
}

/**
 * Helper function to make API calls with automatic port discovery
 * @param endpoint API endpoint path (e.g., "/query", "/code_explanation")
 * @param data Request data to send
 * @returns Response data or error message
 */
async function makeApiCallWithPortDiscovery(endpoint: string, data: any): Promise<any> {
  // Ensure the data object exists
  if (!data) {
    data = {};
  }

  // Get primary URL from settings
  const primaryUrl = getAgentApiUrl();
  const fullUrl = `${primaryUrl}${endpoint}`;
  console.log(`Connecting to API endpoint: ${fullUrl}`);
  
  // Try with primary URL first
  try {
    const response = await axios.post(fullUrl, data, {
      headers: DEFAULT_HEADERS,
      timeout: 15000 // Increase timeout for model processing
    });
    
    return response.data;
  } catch (error: any) {
    console.log(`Primary URL ${primaryUrl} failed:`, error.message);
    
    // If primary URL fails with connection error, try alternative ports
    if (axios.isAxiosError(error) && !error.response) {
      // Extract the hostname from the primary URL
      const url = new URL(primaryUrl);
      const hostname = url.hostname;
      const basePath = url.pathname.split('/api/agent')[0];
      
      // Try common alternative ports
      const alternativePorts = [5002, 5000, 5001, 5003, 5004, 5005];
      for (const port of alternativePorts) {
        const alternativeBaseUrl = `http://${hostname}:${port}${basePath}/api/agent`;
        const alternativeFullUrl = `${alternativeBaseUrl}${endpoint}`;
        console.log(`Trying alternative port: ${alternativeFullUrl}`);
        
        try {
          const response = await axios.post(alternativeFullUrl, data, {
            headers: DEFAULT_HEADERS,
            timeout: 5000 // Shorter timeout for alternative ports
          });
          
          // If successful, update config for future requests
          const config = vscode.workspace.getConfiguration('aidevteam');
          config.update('agentApiUrl', alternativeBaseUrl, vscode.ConfigurationTarget.Global);
          console.log(`Updated configuration to use successful port: ${alternativeBaseUrl}`);
          
          return response.data;
        } catch (portError: any) {
          console.log(`Alternative URL ${alternativeFullUrl} failed:`, portError.message);
          // Continue to next port
        }
      }
    }
    
    // If all attempts fail, throw the error to be handled by the caller
    throw error;
  }
}

// Update sendGeneralQuery to use the helper function and add the required type field
async function sendGeneralQuery(query: string, useMemory: boolean = true): Promise<string> {
  try {
    const response = await makeApiCallWithPortDiscovery('', {
      type: "general_query",  // Add this required field
      query,
      use_memory: useMemory
    });
    
    if (response.status === "success") {
      return response.response || "No response from the AI.";
    } else {
      return `Error: ${response.message || "Unknown error"}`;
    }
  } catch (error: any) {
    console.error('Error sending query to agent:', error);
    if (axios.isAxiosError(error) && error.response?.status === 404) {
      return 'AI services are not running. Please start the services first with the "AI Dev Team: Start Services" command.';
    }
    return `Error connecting to AI services: ${error.message}. Please make sure the services are running.`;
  }
}

// Update sendCodeExplanation to use the helper function
async function sendCodeExplanation(code: string, fileType: string): Promise<string> {
  try {
    const response = await makeApiCallWithPortDiscovery('', {
      type: "code_explanation",  // Add this required field
      code,
      file_type: fileType
    });
    
    if (response.status === "success") {
      return response.explanation || "No explanation provided.";
    } else {
      return `Error: ${response.message || "Unknown error"}`;
    }
  } catch (error: any) {
    console.error('Error sending code explanation request:', error);
    return `Error connecting to AI services: ${error.message}. Please make sure the services are running.`;
  }
}

// Update sendCodeCompletion to use the helper function
async function sendCodeCompletion(codeContext: string, fileType: string, request: string): Promise<string> {
  try {
    const response = await makeApiCallWithPortDiscovery('', {
      type: "code_completion",  // Add this required field
      code_context: codeContext,
      file_type: fileType,
      request
    });
    
    if (response.status === "success") {
      return response.completion || "";
    } else {
      console.error('Code completion error:', response.message);
      return `// Error: ${response.message || "Unknown error"}`;
    }
  } catch (error: any) {
    console.error('Error sending code completion request:', error);
    return `// Error connecting to AI services: ${error.message}`;
  }
}

// Update sendCodeImprovement to use the helper function
async function sendCodeImprovement(code: string, fileType: string): Promise<string> {
  try {
    const response = await makeApiCallWithPortDiscovery('', {
      type: "code_improvement",  // Add this required field
      code,
      file_type: fileType
    });
    
    if (response.status === "success") {
      return response.improvements || code;
    } else {
      console.error('Code improvement error:', response.message);
      return code; // Return original code on error
    }
  } catch (error: any) {
    console.error('Error sending code improvement request:', error);
    return code; // Return original code on error
  }
}

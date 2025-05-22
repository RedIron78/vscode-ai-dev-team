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

// Configuration constants
const AGENT_API_URL = 'http://localhost:5000/api/agent';
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

  // Register status bar item to show agent status
  const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBarItem.text = "$(rocket) AI Agent";
  statusBarItem.tooltip = "Click to open AI Agent options";
  statusBarItem.command = 'aidevteam.showAgentOptions';
  statusBarItem.show();
  
  context.subscriptions.push(statusBarItem);
  context.subscriptions.push(startServices);
}

// This method is called when your extension is deactivated
export function deactivate() {
  // Shut down services gracefully if we started them
  if (servicesRunning) {
    stopServices();
  }
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

async function sendGeneralQuery(query: string, useMemory: boolean = true): Promise<string> {
  try {
    const apiUrl = vscode.workspace.getConfiguration('aidevteam').get('agentApiUrl', AGENT_API_URL);
    console.log(`Sending request to ${apiUrl} with type="general_query" and query="${query}"`);
    
    const requestData = {
      type: "general_query",
      query,
      use_memory: useMemory
    };
    console.log('Request data:', JSON.stringify(requestData));
    
    const response = await axios.post(apiUrl, requestData, { 
      headers: DEFAULT_HEADERS 
    });
    
    console.log('Response:', JSON.stringify(response.data));
    return response.data.response;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error:', error.message);
      console.error('Request config:', JSON.stringify(error.config));
      if (error.response) {
        console.error('Response data:', JSON.stringify(error.response.data));
        console.error('Response status:', error.response.status);
      }
    } else {
      console.error('Error sending query:', error);
    }
    return 'Sorry, I encountered an error processing your request.';
  }
}

async function sendCodeExplanation(code: string, fileType: string): Promise<string> {
  try {
    const apiUrl = vscode.workspace.getConfiguration('aidevteam').get('agentApiUrl', AGENT_API_URL);
    const response = await axios.post(apiUrl, {
      type: "code_explanation",
      code,
      file_type: fileType
    }, { 
      headers: DEFAULT_HEADERS 
    });
    
    return response.data.response || response.data.explanation;
  } catch (error) {
    console.error('Error explaining code:', error);
    return 'Sorry, I encountered an error explaining this code.';
  }
}

async function sendCodeCompletion(codeContext: string, fileType: string, request: string): Promise<string> {
  try {
    const apiUrl = vscode.workspace.getConfiguration('aidevteam').get('agentApiUrl', AGENT_API_URL);
    const response = await axios.post(apiUrl, {
      type: "code_completion",
      code_context: codeContext,
      file_type: fileType,
      request
    }, { 
      headers: DEFAULT_HEADERS 
    });
    
    return response.data.response || response.data.completion;
  } catch (error) {
    console.error('Error completing code:', error);
    return '// Error generating code completion';
  }
}

async function sendCodeImprovement(code: string, fileType: string): Promise<string> {
  try {
    const apiUrl = vscode.workspace.getConfiguration('aidevteam').get('agentApiUrl', AGENT_API_URL);
    const response = await axios.post(apiUrl, {
      type: "code_improvement",
      code,
      file_type: fileType
    }, { 
      headers: DEFAULT_HEADERS 
    });
    
    return response.data.response || response.data.improved_code;
  } catch (error) {
    console.error('Error improving code:', error);
    return code + '\n\n// Error: Could not generate improvements';
  }
}

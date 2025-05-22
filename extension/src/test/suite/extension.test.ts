import * as assert from 'assert';
import * as vscode from 'vscode';
import axios from 'axios';

suite('VS Code AI Dev Team Extension Test Suite', () => {
	vscode.window.showInformationMessage('Starting VS Code AI Dev Team extension tests');

	// Helper function to wait for a specific duration
	function sleep(ms: number): Promise<void> {
		return new Promise(resolve => setTimeout(resolve, ms));
	}

	// Helper function to execute a VS Code command and wait for its completion
	async function executeCommand(command: string): Promise<any> {
		try {
			const result = await vscode.commands.executeCommand(command);
			// Give some time for the command to complete its work
			await sleep(500);
			return result;
		} catch (error) {
			console.error(`Error executing command ${command}:`, error);
			throw error;
		}
	}

	// Test extension activation
	test('Extension should be active after activation', async () => {
		const extension = vscode.extensions.getExtension('YOUR-PUBLISHER.vscode-ai-dev-team');
		assert.ok(extension);
		
		if (!extension.isActive) {
			await extension.activate();
		}
		
		assert.strictEqual(extension.isActive, true);
	});

	// Test that all commands are registered
	test('All commands should be registered', async () => {
		const allCommands = await vscode.commands.getCommands(true);
		
		const requiredCommands = [
			'vscode-ai-dev-team.askAI',
			'vscode-ai-dev-team.explainCode',
			'vscode-ai-dev-team.completeCode',
			'vscode-ai-dev-team.improveCode',
			'vscode-ai-dev-team.startServices',
			'vscode-ai-dev-team.stopServices'
		];
		
		for (const cmd of requiredCommands) {
			assert.ok(
				allCommands.includes(cmd),
				`Command ${cmd} is not registered`
			);
		}
	});

	// Test Ask AI command
	test('Ask AI command should open input box', async function() {
		this.timeout(10000); // Increase timeout for this test
		
		// Mock the showInputBox function to detect if it was called
		let inputDetected = false;
		const originalShowInputBox = vscode.window.showInputBox;
		vscode.window.showInputBox = async () => {
			inputDetected = true;
			return '';
		};
		
		try {
			// Execute the Ask AI command
			await executeCommand('vscode-ai-dev-team.askAI');
			
			// Wait a bit for the input box to appear
			await sleep(2000);
			
			assert.strictEqual(inputDetected, true, 'Input box was not shown');
		} finally {
			// Restore the original function
			vscode.window.showInputBox = originalShowInputBox;
		}
	});

	// Test that API is accessible
	test('Backend API should be accessible', async function() {
		this.timeout(10000);
		
		// This test requires that the backend service is running
		try {
			const response = await axios.get('http://localhost:5000/health');
			const data = response.data;
			
			assert.strictEqual(response.status, 200);
			assert.strictEqual(data.status, 'ok');
		} catch (error) {
			assert.fail(`Backend API is not accessible: ${error}`);
		}
	});

	// Test code explanation with a sample snippet
	test('Explain Code command should work with selected code', async function() {
		this.timeout(30000); // This could take some time
		
		// Create a document with some code
		const document = await vscode.workspace.openTextDocument({
			content: 'function add(a, b) {\n  return a + b;\n}',
			language: 'javascript'
		});
		
		const editor = await vscode.window.showTextDocument(document);
		
		// Select all text in the document
		const lastLineLength = document.lineAt(document.lineCount - 1).text.length;
		editor.selection = new vscode.Selection(
			new vscode.Position(0, 0),
			new vscode.Position(document.lineCount - 1, lastLineLength)
		);
		
		// Use withProgress to detect if progress notification was shown
		let progressShown = false;
		const mockProgress = {
			report: () => {}
		};
		
		// Create a mock cancellation token
		const mockCancellationToken: vscode.CancellationToken = {
			isCancellationRequested: false,
			onCancellationRequested: () => ({ dispose: () => {} }) as vscode.Disposable
		};
		
		// Mock the withProgress function
		const originalWithProgress = vscode.window.withProgress;
		vscode.window.withProgress = async (options, task) => {
			progressShown = true;
			return task(mockProgress, mockCancellationToken);
		};
		
		try {
			// Execute the Explain Code command
			await executeCommand('vscode-ai-dev-team.explainCode');
			
			// Wait for the response (this may take time)
			await sleep(5000);
			
			// We can only check if the progress was shown
			assert.ok(progressShown, 'No indication that the explanation was being generated');
		} finally {
			// Restore the original function
			vscode.window.withProgress = originalWithProgress;
			await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
		}
	});

	// Test starting services
	test('Start Services command should work', async function() {
		this.timeout(10000);
		
		// Execute the Start Services command
		await executeCommand('vscode-ai-dev-team.startServices');
		
		// Check if we can access the API after starting services
		try {
			await sleep(5000); // Wait for services to start
			const response = await axios.get('http://localhost:5000/health');
			const data = response.data;
			
			assert.strictEqual(response.status, 200);
			assert.strictEqual(data.status, 'ok');
		} catch (error) {
			assert.fail(`Backend API is not accessible after starting services: ${error}`);
		}
	});
}); 
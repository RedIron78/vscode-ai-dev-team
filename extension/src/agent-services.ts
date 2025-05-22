import * as vscode from 'vscode';
import { spawn, ChildProcess } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

// Track process instances
let weaviateProcess: ChildProcess | null = null;
let llamaServerProcess: ChildProcess | null = null;
let agentServerProcess: ChildProcess | null = null;

/**
 * Start the Weaviate service using Docker if it's not already running
 */
export async function startWeaviateService(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
        try {
            // Check if Weaviate is already running
            const checkProcess = spawn('docker', ['ps', '--filter', 'name=weaviate', '--format', '{{.Names}}']);
            
            let output = '';
            checkProcess.stdout.on('data', (data) => {
                output += data.toString();
            });
            
            checkProcess.on('close', (code) => {
                if (code === 0 && output.includes('weaviate')) {
                    console.log('Weaviate is already running');
                    resolve();
                    return;
                }
                
                // Start Weaviate using docker-compose
                const workspaceRoot = vscode.workspace.workspaceFolders?.[0].uri.fsPath || '';
                const dockerComposeFile = path.join(workspaceRoot, 'docker-compose.yml');
                
                if (!fs.existsSync(dockerComposeFile)) {
                    reject(new Error('docker-compose.yml not found in the workspace root'));
                    return;
                }
                
                weaviateProcess = spawn('docker-compose', ['up', '-d'], { cwd: workspaceRoot });
                
                weaviateProcess.stdout?.on('data', (data) => {
                    console.log(`Weaviate stdout: ${data}`);
                });
                
                weaviateProcess.stderr?.on('data', (data) => {
                    console.error(`Weaviate stderr: ${data}`);
                });
                
                weaviateProcess.on('close', (code) => {
                    if (code === 0) {
                        console.log('Weaviate started successfully');
                        resolve();
                    } else {
                        reject(new Error(`Weaviate failed to start with code ${code}`));
                    }
                });
            });
        } catch (error) {
            reject(error);
        }
    });
}

/**
 * Start the LLM server (llama.cpp server)
 */
export async function startLLMService(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
        try {
            const workspaceRoot = vscode.workspace.workspaceFolders?.[0].uri.fsPath || '';
            const scriptPath = path.join(workspaceRoot, 'run_llama_server.sh');
            
            if (!fs.existsSync(scriptPath)) {
                reject(new Error('run_llama_server.sh not found in the workspace root'));
                return;
            }
            
            // Make the script executable
            fs.chmodSync(scriptPath, '755');
            
            llamaServerProcess = spawn(scriptPath, [], { 
                cwd: workspaceRoot,
                detached: true,
                stdio: ['ignore', 'pipe', 'pipe']
            });
            
            llamaServerProcess.stdout?.on('data', (data) => {
                console.log(`LLM server stdout: ${data}`);
                
                // Check if server is ready
                if (data.toString().includes('server listening')) {
                    resolve();
                }
            });
            
            llamaServerProcess.stderr?.on('data', (data) => {
                console.error(`LLM server stderr: ${data}`);
            });
            
            llamaServerProcess.on('error', (error) => {
                reject(error);
            });
            
            // Set a timeout for server startup
            setTimeout(() => {
                resolve(); // Resolve anyway after timeout
            }, 10000);
        } catch (error) {
            reject(error);
        }
    });
}

/**
 * Start the agent server
 */
export async function startAgentService(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
        try {
            const workspaceRoot = vscode.workspace.workspaceFolders?.[0].uri.fsPath || '';
            const pythonPath = path.join(workspaceRoot, 'venv', 'bin', 'python');
            const scriptPath = path.join(workspaceRoot, 'vscode_integration.py');
            
            if (!fs.existsSync(scriptPath)) {
                reject(new Error('vscode_integration.py not found in the workspace root'));
                return;
            }
            
            agentServerProcess = spawn(pythonPath, [scriptPath], { 
                cwd: workspaceRoot,
                detached: true,
                stdio: ['ignore', 'pipe', 'pipe']
            });
            
            agentServerProcess.stdout?.on('data', (data) => {
                console.log(`Agent server stdout: ${data}`);
                
                // Check if server is ready
                if (data.toString().includes('Starting VS Code integration server')) {
                    resolve();
                }
            });
            
            agentServerProcess.stderr?.on('data', (data) => {
                console.error(`Agent server stderr: ${data}`);
            });
            
            agentServerProcess.on('error', (error) => {
                reject(error);
            });
            
            // Set a timeout for server startup
            setTimeout(() => {
                resolve(); // Resolve anyway after timeout
            }, 10000);
        } catch (error) {
            reject(error);
        }
    });
}

/**
 * Stop all services
 */
export async function stopServices(): Promise<void> {
    return new Promise<void>((resolve) => {
        // Stop agent server
        if (agentServerProcess) {
            try {
                process.kill(-agentServerProcess.pid!, 'SIGTERM');
            } catch (error) {
                console.error('Error stopping agent server:', error);
            }
            agentServerProcess = null;
        }
        
        // Stop LLM server
        if (llamaServerProcess) {
            try {
                process.kill(-llamaServerProcess.pid!, 'SIGTERM');
            } catch (error) {
                console.error('Error stopping LLM server:', error);
            }
            llamaServerProcess = null;
        }
        
        // Stop Weaviate
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0].uri.fsPath || '';
        const dockerComposeProcess = spawn('docker-compose', ['down'], { cwd: workspaceRoot });
        
        dockerComposeProcess.on('close', () => {
            console.log('Weaviate stopped');
            weaviateProcess = null;
            resolve();
        });
        
        dockerComposeProcess.on('error', () => {
            console.error('Error stopping Weaviate');
            weaviateProcess = null;
            resolve();
        });
    });
} 
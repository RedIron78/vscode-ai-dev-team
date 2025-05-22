import * as vscode from 'vscode';
import { spawn, ChildProcess } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

// Track process instances
let weaviateProcess: ChildProcess | null = null;
let llamaServerProcess: ChildProcess | null = null;
let agentServerProcess: ChildProcess | null = null;

// Helper function to determine script extension based on platform
function getScriptExt(): string {
    return os.platform() === 'win32' ? '.bat' : '.sh';
}

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
            const scriptExt = getScriptExt();
            const scriptPath = path.join(workspaceRoot, 'scripts', `run_llama_server${scriptExt}`);
            
            if (!fs.existsSync(scriptPath)) {
                reject(new Error(`run_llama_server${scriptExt} not found in the scripts directory`));
                return;
            }
            
            // Make the script executable on Linux/macOS
            if (os.platform() !== 'win32') {
                fs.chmodSync(scriptPath, '755');
            }
            
            // On Windows use cmd /c to run the batch file
            if (os.platform() === 'win32') {
                llamaServerProcess = spawn('cmd', ['/c', scriptPath], { 
                    cwd: workspaceRoot,
                    detached: true,
                    stdio: ['ignore', 'pipe', 'pipe']
                });
            } else {
                llamaServerProcess = spawn(scriptPath, [], { 
                    cwd: workspaceRoot,
                    detached: true,
                    stdio: ['ignore', 'pipe', 'pipe']
                });
            }
            
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
            const scriptExt = getScriptExt();
            const scriptPath = path.join(workspaceRoot, 'scripts', `start_vscode_agent${scriptExt}`);
            
            if (!fs.existsSync(scriptPath)) {
                reject(new Error(`start_vscode_agent${scriptExt} not found in the scripts directory`));
                return;
            }
            
            // Make the script executable on Linux/macOS
            if (os.platform() !== 'win32') {
                fs.chmodSync(scriptPath, '755');
            }
            
            // On Windows use cmd /c to run the batch file
            if (os.platform() === 'win32') {
                agentServerProcess = spawn('cmd', ['/c', scriptPath], { 
                    cwd: workspaceRoot,
                    detached: true,
                    stdio: ['ignore', 'pipe', 'pipe']
                });
            } else {
                agentServerProcess = spawn(scriptPath, [], { 
                    cwd: workspaceRoot,
                    detached: true,
                    stdio: ['ignore', 'pipe', 'pipe']
                });
            }
            
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
            
            // Set a timeout for server startup - increased to account for slower startup
            setTimeout(() => {
                resolve(); // Resolve anyway after timeout
            }, 15000);
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
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0].uri.fsPath || '';
        const scriptExt = getScriptExt();
        const stopScript = path.join(workspaceRoot, `stop_all${scriptExt}`);
        
        // If stop_all script exists, use it
        if (fs.existsSync(stopScript)) {
            try {
                console.log('Stopping services using stop_all script');
                
                // Make the script executable on Linux/macOS
                if (os.platform() !== 'win32') {
                    fs.chmodSync(stopScript, '755');
                }
                
                // Execute the appropriate stop script based on platform
                const stopProcess = os.platform() === 'win32' ? 
                    spawn('cmd', ['/c', stopScript], { cwd: workspaceRoot }) :
                    spawn(stopScript, [], { cwd: workspaceRoot });
                
                stopProcess.on('close', () => {
                    console.log('All services stopped via script');
                    llamaServerProcess = null;
                    agentServerProcess = null;
                    weaviateProcess = null;
                    resolve();
                });
                
                return;
            } catch (error) {
                console.error('Error stopping services with script:', error);
                // Continue with manual shutdown if script fails
            }
        }
        
        // Manual shutdown as fallback
        console.log('Manual shutdown of services');
        
        // Stop agent server
        if (agentServerProcess) {
            try {
                if (os.platform() === 'win32') {
                    // On Windows, terminate process tree
                    spawn('taskkill', ['/pid', agentServerProcess.pid!.toString(), '/f', '/t']);
                } else {
                    // On Unix, kill process group
                    process.kill(-agentServerProcess.pid!, 'SIGTERM');
                }
            } catch (error) {
                console.error('Error stopping agent server:', error);
            }
            agentServerProcess = null;
        }
        
        // Stop LLM server
        if (llamaServerProcess) {
            try {
                if (os.platform() === 'win32') {
                    // On Windows, terminate process tree
                    spawn('taskkill', ['/pid', llamaServerProcess.pid!.toString(), '/f', '/t']);
                } else {
                    // On Unix, kill process group
                    process.kill(-llamaServerProcess.pid!, 'SIGTERM');
                }
            } catch (error) {
                console.error('Error stopping LLM server:', error);
            }
            llamaServerProcess = null;
        }
        
        // Stop Weaviate
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
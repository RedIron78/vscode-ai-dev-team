import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';

suite('Extension Test Suite', () => {
  vscode.window.showInformationMessage('Start all tests.');

  test('Extension should be present', () => {
    assert.ok(vscode.extensions.getExtension('vscode-ai-dev-team'));
  });

  test('Should activate', async () => {
    const ext = vscode.extensions.getExtension('vscode-ai-dev-team');
    await ext?.activate();
    assert.strictEqual(ext?.isActive, true);
  });

  test('Should register commands', async () => {
    const commands = await vscode.commands.getCommands();
    assert.ok(commands.includes('aidevteam.startServices'));
    assert.ok(commands.includes('aidevteam.askAI'));
    assert.ok(commands.includes('aidevteam.explainCode'));
    assert.ok(commands.includes('aidevteam.completeCode'));
    assert.ok(commands.includes('aidevteam.improveCode'));
  });

  test('Should register views', async () => {
    const views = await vscode.workspace.getConfiguration('views').get('aidevteam');
    assert.ok(views);
  });
}); 
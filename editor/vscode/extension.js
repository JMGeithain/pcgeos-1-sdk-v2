'use strict';
// Original dependency-free client for the SDK's small stdio language server.
// Compilers and the GEOS runtime remain separate from editor diagnostics.
const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const IDS = ['geos-esp', 'geos-nasm', 'geos-ui', 'geos-gp', 'geos-goc', 'c', 'cpp'];
const position = p => new vscode.Position(p.line, p.character);
const range = r => new vscode.Range(position(r.start), position(r.end));
function markdown(value) {
    const text = typeof value === 'string' ? value : (value && value.value) || '';
    const result = new vscode.MarkdownString(text);
    result.isTrusted = false;
    result.supportHtml = false;
    return result;
}

class Rpc {
    constructor(child, output, diagnostics) {
        this.child = child;
        this.output = output;
        this.diagnostics = diagnostics;
        this.buffer = Buffer.alloc(0);
        this.pending = new Map();
        this.next = 1;
        this.closed = false;
        this.stopping = undefined;
        this.killTimer = undefined;
        child.stdout.on('data', chunk => this.read(chunk));
        child.stderr.on('data', chunk => output.append(chunk.toString()));
        child.stdin.on('error', error => this.fail(error));
        child.on('error', error => this.fail(error));
        child.on('exit', () => {
            clearTimeout(this.killTimer);
            this.fail(new Error('Language server stopped'), false);
        });
    }
    send(message) {
        if (this.closed) { return; }
        const data = Buffer.from(JSON.stringify({ jsonrpc: '2.0', ...message }), 'utf8');
        this.child.stdin.write(Buffer.concat([Buffer.from(`Content-Length: ${data.length}\r\n\r\n`), data]));
    }
    notify(method, params) { this.send({ method, params }); }
    request(method, params) {
        if (this.closed) { return Promise.reject(new Error('Language server is closed')); }
        const id = this.next++;
        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                this.pending.delete(id);
                reject(new Error(`Language server timeout: ${method}`));
            }, 10000);
            this.pending.set(id, { resolve, reject, timer });
            this.send({ id, method, params });
        });
    }
    read(chunk) {
        if (this.closed) { return; }
        this.buffer = Buffer.concat([this.buffer, chunk]);
        while (true) {
            const end = this.buffer.indexOf('\r\n\r\n');
            if (end < 0) {
                if (this.buffer.length > 8192) { this.fail(new Error('Invalid server header')); }
                return;
            }
            const match = /(?:^|\r\n)Content-Length:\s*(\d+)\s*(?:\r\n|$)/i.exec(this.buffer.subarray(0, end).toString('ascii'));
            const length = match && Number(match[1]);
            if (!match || length > 16 * 1024 * 1024) { this.fail(new Error('Invalid server frame')); return; }
            if (this.buffer.length < end + 4 + length) { return; }
            const data = this.buffer.subarray(end + 4, end + 4 + length);
            this.buffer = this.buffer.subarray(end + 4 + length);
            let message;
            try { message = JSON.parse(data.toString('utf8')); }
            catch (error) { this.fail(error); return; }
            if (!message || typeof message !== 'object') { this.fail(new Error('Invalid server response')); return; }
            if (message.id !== undefined && this.pending.has(message.id)) {
                const item = this.pending.get(message.id);
                clearTimeout(item.timer);
                this.pending.delete(message.id);
                if (message.error) { item.reject(new Error(message.error.message)); }
                else { item.resolve(message.result); }
            } else if (message.method === 'textDocument/publishDiagnostics') {
                const params = message.params;
                if (!params || !Array.isArray(params.diagnostics)) { continue; }
                const items = params.diagnostics.map(d => {
                    const item = new vscode.Diagnostic(range(d.range), d.message, (d.severity || 2) - 1);
                    item.source = d.source || 'PC/GEOS SDK';
                    item.code = d.code;
                    return item;
                });
                this.diagnostics.set(vscode.Uri.parse(params.uri), items);
            }
        }
    }
    terminate() {
        if (this.child.exitCode !== null || this.child.signalCode !== null) { return; }
        this.child.kill();
        if (!this.killTimer) {
            this.killTimer = setTimeout(() => {
                if (this.child.exitCode === null && this.child.signalCode === null) { this.child.kill('SIGKILL'); }
            }, 1000);
            this.killTimer.unref();
        }
    }
    fail(error, terminate = true) {
        if (terminate) { this.terminate(); }
        if (this.closed) { return; }
        this.closed = true;
        this.output.appendLine(error.message);
        for (const item of this.pending.values()) { clearTimeout(item.timer); item.reject(error); }
        this.pending.clear();
        this.diagnostics.clear();
    }
    dispose() {
        if (this.stopping) { return this.stopping; }
        if (this.closed) { this.terminate(); return Promise.resolve(); }
        // LSP requires a shutdown request before exit. Keep a bounded fallback
        // even if a broken child never replies, and retain the child while
        // initialize is pending so extension disposal cannot orphan it.
        let finish;
        const stopped = new Promise(resolve => { finish = resolve; });
        this.child.once('close', finish);
        const deadline = setTimeout(() => {
            this.fail(new Error('Language server shutdown timed out'));
        }, 2000);
        deadline.unref();
        this.stopping = stopped.finally(() => {
            clearTimeout(deadline);
            this.fail(new Error('Language server disconnected'), false);
        });
        this.request('shutdown', null).then(() => {
            if (!this.closed) { this.notify('exit'); this.child.stdin.end(); }
        }).catch(error => this.fail(error));
        return this.stopping;
    }
}

function sdkRoot() {
    const configured = vscode.workspace.getConfiguration('pcgeos1').get('sdkRoot', '');
    const candidates = configured ? [configured] : (vscode.workspace.workspaceFolders || []).map(x => x.uri.fsPath);
    return candidates.map(x => path.resolve(x)).find(x => fs.existsSync(path.join(x, 'tools', 'lsp', 'server.pl')));
}

async function activate(context) {
    const output = vscode.window.createOutputChannel('PC/GEOS SDK');
    const diagnostics = vscode.languages.createDiagnosticCollection('pcgeos1');
    context.subscriptions.push(output, diagnostics);
    let rpc;
    let starting;
    let initializingClient;
    let disposed = false;
    const opened = new Map();
    const selector = IDS.map(language => ({ language, scheme: 'file' }));
    const relevant = doc => IDS.includes(doc.languageId) && doc.uri.scheme === 'file';
    const sync = doc => {
        if (!rpc || rpc.closed || !relevant(doc)) { return; }
        const uri = doc.uri.toString();
        if (opened.get(uri) === doc.version) { return; }
        if (!opened.has(uri)) {
            rpc.notify('textDocument/didOpen', { textDocument: { uri, languageId: doc.languageId, version: doc.version, text: doc.getText() } });
        } else {
            rpc.notify('textDocument/didChange', { textDocument: { uri, version: doc.version }, contentChanges: [{ text: doc.getText() }] });
        }
        opened.set(uri, doc.version);
    };
    async function start() {
        if (disposed) { return undefined; }
        if (rpc && !rpc.closed) { return rpc; }
        if (starting) { return starting; }
        if (!vscode.workspace.isTrusted || !vscode.workspace.getConfiguration('pcgeos1').get('enableLanguageServer', true)) { return undefined; }
        const root = sdkRoot();
        if (!root) { return undefined; }
        starting = (async () => {
            const perl = vscode.workspace.getConfiguration('pcgeos1').get('perlExecutable', 'perl');
            const child = spawn(perl, [path.join(root, 'tools', 'lsp', 'server.pl'), '--sdk-root', root], { cwd: root, stdio: ['pipe', 'pipe', 'pipe'], shell: false });
            const client = new Rpc(child, output, diagnostics);
            initializingClient = client;
            try {
                await client.request('initialize', {
                    processId: process.pid,
                    rootUri: vscode.Uri.file(root).toString(),
                    capabilities: { textDocument: { completion: { completionItem: { snippetSupport: true, documentationFormat: ['markdown', 'plaintext'] } }, hover: { contentFormat: ['markdown', 'plaintext'] } } }
                });
                if (disposed) { client.dispose(); return undefined; }
                rpc = client;
                opened.clear();
                client.notify('initialized', {});
                for (const doc of vscode.workspace.textDocuments) { sync(doc); }
                output.appendLine('Connected to the SDK language server. Diagnostics are bounded source checks; run the native compiler for a build.');
                return client;
            } catch (error) { client.dispose(); output.appendLine(error.message); return undefined; }
            finally {
                if (initializingClient === client) { initializingClient = undefined; }
                starting = undefined;
            }
        })();
        return starting;
    }
    async function query(method, doc, pos) {
        const client = await start();
        if (!client) { return undefined; }
        sync(doc);
        try { return await client.request(method, { textDocument: { uri: doc.uri.toString() }, ...(pos ? { position: { line: pos.line, character: pos.character } } : {}) }); }
        catch (error) { output.appendLine(error.message); return undefined; }
    }
    context.subscriptions.push(
        { dispose: () => {
            disposed = true;
            if (rpc) { rpc.dispose(); }
            if (initializingClient && initializingClient !== rpc) { initializingClient.dispose(); }
        } },
        vscode.workspace.onDidOpenTextDocument(doc => { start().then(() => sync(doc)); }),
        vscode.workspace.onDidChangeTextDocument(event => sync(event.document)),
        vscode.workspace.onDidCloseTextDocument(doc => {
            const uri = doc.uri.toString();
            if (rpc && opened.delete(uri)) { rpc.notify('textDocument/didClose', { textDocument: { uri } }); }
            diagnostics.delete(doc.uri);
        }),
        vscode.workspace.onDidGrantWorkspaceTrust(() => start()),
        vscode.commands.registerCommand('pcgeos1.restartLanguageServer', async () => {
            if (rpc) { await rpc.dispose(); rpc = undefined; }
            if (initializingClient) { await initializingClient.dispose(); }
            if (starting) { await starting; }
            opened.clear();
            if (!await start()) { vscode.window.showInformationMessage('Set PC/GEOS: SDK Root to this SDK checkout and choose a Perl 5.26+ executable in a trusted workspace.'); }
        }),
        vscode.commands.registerCommand('pcgeos1.openApiReference', async () => {
            const root = sdkRoot();
            if (root) { await vscode.commands.executeCommand('markdown.showPreview', vscode.Uri.file(path.join(root, 'include', 'ensemble12', 'README.md'))); }
        }),
        vscode.languages.registerCompletionItemProvider(selector, {
            async provideCompletionItems(doc, pos) {
                const result = await query('textDocument/completion', doc, pos);
                const items = Array.isArray(result) ? result : (result && result.items) || [];
                return items.map(x => {
                    const item = new vscode.CompletionItem(x.label, x.kind ? x.kind - 1 : vscode.CompletionItemKind.Text);
                    item.detail = x.detail;
                    if (x.documentation) { item.documentation = markdown(x.documentation); }
                    const insert = x.textEdit ? x.textEdit.newText : x.insertText;
                    if (insert !== undefined) { item.insertText = x.insertTextFormat === 2 ? new vscode.SnippetString(insert) : insert; }
                    if (x.textEdit) { item.range = range(x.textEdit.range); }
                    item.sortText = x.sortText;
                    item.filterText = x.filterText;
                    return item;
                });
            }
        }, '.', '%', '@'),
        vscode.languages.registerHoverProvider(selector, {
            async provideHover(doc, pos) {
                const result = await query('textDocument/hover', doc, pos);
                if (!result || !result.contents) { return undefined; }
                const values = Array.isArray(result.contents) ? result.contents : [result.contents];
                return new vscode.Hover(values.map(markdown), result.range ? range(result.range) : undefined);
            }
        }),
        vscode.languages.registerSignatureHelpProvider(selector, {
            async provideSignatureHelp(doc, pos) {
                const result = await query('textDocument/signatureHelp', doc, pos);
                if (!result || !Array.isArray(result.signatures) || !result.signatures.length) { return undefined; }
                const help = new vscode.SignatureHelp();
                help.signatures = result.signatures.map(x => {
                    const signature = new vscode.SignatureInformation(x.label,
                        x.documentation ? markdown(x.documentation) : undefined);
                    signature.parameters = (x.parameters || []).map(p => new vscode.ParameterInformation(
                        p.label, p.documentation ? markdown(p.documentation) : undefined));
                    if (x.activeParameter !== undefined) { signature.activeParameter = x.activeParameter; }
                    return signature;
                });
                help.activeSignature = result.activeSignature || 0;
                help.activeParameter = result.activeParameter || 0;
                return help;
            }
        }, ' ', ',', '('),
        vscode.languages.registerDefinitionProvider(selector, {
            async provideDefinition(doc, pos) {
                const result = await query('textDocument/definition', doc, pos);
                if (!result) { return undefined; }
                return (Array.isArray(result) ? result : [result]).filter(x => x.uri && vscode.Uri.parse(x.uri).scheme === 'file').map(x => new vscode.Location(vscode.Uri.parse(x.uri), range(x.range)));
            }
        }),
        vscode.languages.registerDocumentSymbolProvider(selector, {
            async provideDocumentSymbols(doc) {
                const result = await query('textDocument/documentSymbol', doc);
                function convert(x) {
                    const item = new vscode.DocumentSymbol(x.name, x.detail || '', Math.max(0, (x.kind || 13) - 1), range(x.range), range(x.selectionRange || x.range));
                    item.children = (x.children || []).map(convert);
                    return item;
                }
                return (result || []).map(convert);
            }
        })
    );
    await start();
}

exports.activate = activate;

#!/usr/bin/env node
'use strict';
// Original headless client/server integration test. VS Code API is mocked;
// the extension code and Perl stdio language server are executed unchanged.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { pathToFileURL, fileURLToPath } = require('node:url');
const childProcess = require('node:child_process');
const ROOT = path.resolve(__dirname, '../..');
const PERL = process.env.PCGEOS1_TEST_PERL || process.env.PERL || 'perl';
const children = [];
const checks = [];
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(predicate, description, timeout=5000) {
    const deadline = Date.now()+timeout;
    while (!predicate()) {
        if (Date.now() > deadline) { throw new Error('Timed out: '+description); }
        await delay(10);
    }
}
class Position { constructor(line, character) { this.line=line; this.character=character; } }
class Range { constructor(start, end) { this.start=start; this.end=end; } }
class Uri {
    constructor(value) { this.value=value; this.scheme=new URL(value).protocol.slice(0,-1); }
    get fsPath() { return fileURLToPath(this.value); }
    toString() { return this.value; }
    static file(value) { return new Uri(pathToFileURL(value).toString()); }
    static parse(value) { return new Uri(value); }
}
class MarkdownString { constructor(value) { this.value=value; } }
class Diagnostic { constructor(range, message, severity) { Object.assign(this,{range,message,severity}); } }
class CompletionItem { constructor(label,kind) { Object.assign(this,{label,kind}); } }
class Hover { constructor(contents, range) { Object.assign(this,{contents,range}); } }
class SignatureHelp {}
class SignatureInformation { constructor(label,documentation) { Object.assign(this,{label,documentation}); } }
class ParameterInformation { constructor(label,documentation) { Object.assign(this,{label,documentation}); } }
class Location { constructor(uri, range) { Object.assign(this,{uri,range}); } }
class DocumentSymbol { constructor(name,detail,kind,range,selectionRange) { Object.assign(this,{name,detail,kind,range,selectionRange}); } }
class SnippetString { constructor(value) { this.value=value; } }
function document(name, languageId, text) {
    return {uri:Uri.file(path.join(ROOT,'build','editor-smoke',name)),languageId,version:1,text,
        getText() { return this.text; }};
}
function mockVscode(documents, trusted=true) {
    const callbacks={}, providers={}, commands={}, diagnostics=new Map(), output=[];
    const disposable=()=>({dispose(){}});
    const event=name => callback => { callbacks[name]=callback; return disposable(); };
    const register=name => (selector,provider) => { providers[name]=provider; return disposable(); };
    const collection={set(uri,value){diagnostics.set(uri.toString(),value);},
        delete(uri){diagnostics.delete(uri.toString());},clear(){diagnostics.clear();},dispose(){diagnostics.clear();}};
    const vscode={Position,Range,Uri,MarkdownString,Diagnostic,CompletionItem,Hover,SignatureHelp,SignatureInformation,ParameterInformation,Location,DocumentSymbol,SnippetString,
        CompletionItemKind:{Text:0},
        workspace:{isTrusted:trusted,textDocuments:documents,workspaceFolders:[{uri:Uri.file(ROOT)}],
            getConfiguration(){return{get(key,fallback){return({sdkRoot:ROOT,perlExecutable:PERL,enableLanguageServer:true})[key]??fallback;}};},
            onDidOpenTextDocument:event('open'),onDidChangeTextDocument:event('change'),
            onDidCloseTextDocument:event('close'),onDidGrantWorkspaceTrust:event('trust')},
        window:{createOutputChannel(){return{append(x){output.push(x);},appendLine(x){output.push(x);},dispose(){}};},
            showInformationMessage(message){output.push(message);}},
        languages:{createDiagnosticCollection(){return collection;},
            registerCompletionItemProvider:register('completion'),registerHoverProvider:register('hover'),
            registerSignatureHelpProvider:register('signature'),
            registerDefinitionProvider:register('definition'),registerDocumentSymbolProvider:register('symbols')},
        commands:{registerCommand(name,handler){commands[name]=handler;return disposable();},
            async executeCommand(name,...args){return{name,args};}}};
    return {vscode,callbacks,providers,commands,diagnostics,output};
}
function loadClient(mock, {fragment=false, corrupt=false, responseDelay=0}={}) {
    const exports={};
    const instrumented={...childProcess,spawn(...args){
        const child=childProcess.spawn(...args);
        const record={child,pid:child.pid,sent:[],spawnArgs:args};children.push(record);
        const originalWrite=child.stdin.write.bind(child.stdin);
        child.stdin.write=(data,...rest)=>{
            const bytes=Buffer.isBuffer(data)?data:Buffer.from(data);
            const end=bytes.indexOf('\r\n\r\n');
            if(end>=0){record.sent.push(JSON.parse(bytes.subarray(end+4).toString('utf8')));}
            return originalWrite(data,...rest);
        };
        const originalOn=child.stdout.on.bind(child.stdout);
        let first=true;
        child.stdout.on=(event,listener)=>{
            if(event!=='data'){return originalOn(event,listener);}
            return originalOn('data',chunk=>{
                const deliver=()=>{
                    if(corrupt&&first){first=false;listener(Buffer.from('Content-Length: invalid\r\n\r\n'));return;}
                    first=false;
                    if(!fragment){listener(chunk);return;}
                    // Split headers and UTF-8 multibyte payloads across reads.
                    const steps=[1,2,7,3,11];let at=0,i=0;
                    while(at<chunk.length){const n=steps[i++%steps.length];listener(chunk.subarray(at,at+n));at+=n;}
                };
                if(responseDelay){setTimeout(deliver,responseDelay);}else{deliver();}
            });
        };
        return child;
    }};
    const source=fs.readFileSync(path.join(ROOT,'editor/vscode/extension.js'),'utf8');
    vm.runInNewContext(source,{exports,require(name){return name==='vscode'?mock.vscode:name==='child_process'?instrumented:require(name);},
        Buffer,process,setTimeout,clearTimeout,console},{filename:'extension.js'});
    return exports;
}
function dispose(context){for(const value of context.subscriptions){value.dispose();}}
function isStopped(record){return record.child.exitCode!==null||record.child.signalCode!==null;}
async function stopContext(context,records){dispose(context);await until(()=>records.every(isStopped),'language server exits');}
async function run(){
    // Workspace trust gates every process launch, including provider queries.
    const untrusted=mockVscode([],false),uc={subscriptions:[]};let start=children.length;
    await loadClient(untrusted).activate(uc);
    await untrusted.providers.completion.provideCompletionItems(document('never.nasm','geos-nasm','mov'),new Position(0,3));
    assert.equal(children.length,start);dispose(uc);checks.push('untrusted workspace launches no process');

    const assembly=document('sample.nasm','geos-nasm','CPU 8086\nmain:\n KCALL E12_K_GrD\n pusha\n mov eax,1\n push 7\n shl ax,2\n ; pusha eax\n db "eax pusha"\n jmp main\n');
    const cdoc=document('unicode.c','c','/* 😀 */ E12_K_MemAlloc\nvoid demo(void) {\n E12_K_GrDrawText;\n /* 😀 */ E12_K_Typo;\n}\n');
    const mock=mockVscode([assembly,cdoc]),context={subscriptions:[]};start=children.length;
    await loadClient(mock,{fragment:true}).activate(context);
    const first=children[start];assert.ok(first.pid);
    assert.equal(first.spawnArgs[2].shell,false);
    assert.ok(first.sent.some(x=>x.method==='initialize'));
    const completions=await mock.providers.completion.provideCompletionItems(assembly,new Position(2,16));
    const labels=Array.from(completions,x=>x.label);
    assert.ok(labels.includes('E12_K_GrDrawText'));assert.ok(labels.includes('E12_K_GrDrawRect'));
    assert.ok(completions.find(x=>x.label==='E12_K_GrDrawText').documentation.value.includes('Native register ABI'));
    checks.push('completion crosses real stdio server with fragmented frames');

    const hoverColumn=cdoc.text.split('\n')[0].indexOf('E12_K_')+8;
    const hover=await mock.providers.hover.provideHover(cdoc,new Position(0,hoverColumn));
    assert.ok(hover.contents[0].value.includes('AX=bytes'));
    assert.equal(hover.range.start.character,cdoc.text.split('\n')[0].indexOf('E12_K_'));
    assert.equal(hover.contents[0].isTrusted,false);assert.equal(hover.contents[0].supportHtml,false);
    checks.push('hover preserves UTF-16 positions and untrusted Markdown');

    const signature=await mock.providers.signature.provideSignatureHelp(cdoc,new Position(0,hoverColumn));
    assert.ok(signature instanceof SignatureHelp);assert.equal(signature.signatures.length,1);
    assert.equal(signature.signatures[0].label,'KCALL E12_K_MemAlloc');
    assert.ok(signature.signatures[0].documentation.value.includes('AX=bytes'));
    assert.ok(signature.signatures[0].documentation.value.includes('Native register ABI'));
    assert.equal(signature.signatures[0].documentation.isTrusted,false);
    assert.equal(signature.activeSignature,0);assert.equal(signature.activeParameter,0);
    assert.equal(signature.signatures[0].parameters.length,0);
    checks.push('signature help converts the real server register contract without C wrappers');

    const definitions=await mock.providers.definition.provideDefinition(cdoc,new Position(0,hoverColumn));
    assert.equal(definitions.length,1);assert.equal(definitions[0].uri.fsPath,path.join(ROOT,'include/ensemble12/abi.h'));
    const definedLine=fs.readFileSync(definitions[0].uri.fsPath,'utf8').split('\n')[definitions[0].range.start.line];
    assert.ok(definedLine.includes('E12_K_MemAlloc'));
    const local=await mock.providers.definition.provideDefinition(assembly,new Position(9,7));
    assert.equal(local[0].uri.toString(),assembly.uri.toString());assert.equal(local[0].range.start.line,1);
    const symbols=await mock.providers.symbols.provideDocumentSymbols(assembly);
    assert.ok(symbols.some(x=>x.name==='main'&&x.selectionRange.start.line===1));
    checks.push('API and local definitions resolve actual files; symbols convert');

    await until(()=>mock.diagnostics.has(assembly.uri.toString())&&mock.diagnostics.has(cdoc.uri.toString()),'initial diagnostics');
    const asmDiagnostics=mock.diagnostics.get(assembly.uri.toString());
    for(const code of ['cpu-instruction','cpu-register','cpu-push-immediate','cpu-shift-immediate']){assert.ok(asmDiagnostics.some(x=>x.code===code),code);}
    assert.ok(!asmDiagnostics.some(x=>[7,8].includes(x.range.start.line)));
    const typo=mock.diagnostics.get(cdoc.uri.toString()).find(x=>x.code==='unknown-profile-name');
    assert.ok(typo);assert.equal(typo.severity,1);assert.equal(typo.range.start.character,cdoc.text.split('\n')[3].indexOf('E12_K_Typo'));
    checks.push('bounded diagnostics map severities and UTF-16 ranges; ignore comments/strings');

    assembly.text='CPU 8086\nmain:\n xor ax,ax\n retf\n';assembly.version++;
    mock.callbacks.change({document:assembly});
    await until(()=>mock.diagnostics.get(assembly.uri.toString())?.length===0,'didChange clears issues');
    assert.ok(first.sent.some(x=>x.method==='textDocument/didChange'&&x.params.contentChanges[0].text===assembly.text));
    mock.callbacks.close(cdoc);mock.vscode.workspace.textDocuments=[assembly];
    await until(()=>first.sent.some(x=>x.method==='textDocument/didClose'),'didClose forwarded');
    checks.push('full-text changes and document closure synchronize');

    await mock.commands['pcgeos1.restartLanguageServer']();
    assert.ok(isStopped(first));assert.equal(first.child.exitCode,0);
    assert.ok(first.sent.findIndex(x=>x.method==='shutdown')<first.sent.findIndex(x=>x.method==='exit'));
    assert.equal(children.length,start+2);
    await mock.providers.completion.provideCompletionItems(assembly,new Position(2,4));
    await stopContext(context,children.slice(start));
    assert.equal(children[start+1].child.exitCode,0);
    checks.push('restart and disposal perform shutdown/exit with no child leaks');

    // Bad framing must stop the actual child, not merely reject pending queries.
    start=children.length;const broken=mockVscode([]),bc={subscriptions:[]};
    await loadClient(broken,{corrupt:true}).activate(bc);
    await stopContext(bc,children.slice(start));
    assert.ok(broken.output.some(x=>x.includes('Invalid server frame')));
    checks.push('malformed response terminates actual Perl child');

    // Dispose while initialization is outstanding; no later didOpen is allowed.
    start=children.length;const slow=mockVscode([assembly]),sc={subscriptions:[]};
    const activation=loadClient(slow,{responseDelay:100}).activate(sc);
    await until(()=>children.length>start,'initializing process spawned');dispose(sc);
    await activation;await until(()=>children.slice(start).every(isStopped),'initializing child exits');
    assert.ok(!children[start].sent.some(x=>x.method==='textDocument/didOpen'));
    checks.push('disposal during initialize leaves no process or document notifications');

    const report={schema:'pcgeos1-editor-client-headless-smoke-v1',passed:true,node_version:process.version,
        perl:PERL,actual_perl_lsp_subprocess:true,vscode_api_mocked:true,vscode_gui_tested:false,
        subprocesses_started:children.length,all_children_stopped:children.every(isStopped),checks};
    const output=process.argv[2];if(output){fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');}
    console.log(JSON.stringify(report,null,2));
}
run().catch(error=>{console.error(error.stack||String(error));process.exitCode=1;}).finally(()=>{
    for(const {child} of children){if(child.exitCode===null&&child.signalCode===null){child.kill('SIGKILL');}}
});

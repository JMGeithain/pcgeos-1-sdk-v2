# Shared editor language server

[Deutsch](README.de.md)

Perl 5.26 or later is sufficient; no CPAN packages are required. Configure an
IDE's standard LSP client to launch this process over stdin/stdout:

```sh
perl /absolute/path/pcgeos1-sdk/tools/lsp/server.pl --sdk-root /absolute/path/pcgeos1-sdk
```

The absolute script/root arguments work independently of the IDE's working
directory. From the SDK root, `perl tools/lsp/server.pl` is equivalent. stdout contains
only `Content-Length` framed JSON-RPC; operational errors go to stderr. No build
tool, application or user source is executed by the server.

See the [multi-IDE guide](../../docs/en/ide-integration.md) for editor-specific setup.
The server is shared by the VS Code extension and other clients. A client must
support the LSP operations it wants to expose; highlighting remains the editor's
language grammar or syntax definition.

## Services

| Service | Scope |
| --- | --- |
| Completion | 8086 mnemonics/registers; dialect-specific directives; current-document symbols; curated Ensemble 1.2 numeric constants |
| Hover | Observed target value, register contract, evidence scope and local API-reference link |
| Definition | Matching symbols in open documents, or the supplied `.h`, `.inc` or `.def` constant definition |
| Document symbols | Simple assembler labels/procedures/resources, C function definitions and UI/GP declarations |
| Signature help | `KCALL E12_K_name` with the native register contract; no invented C prototype |
| Diagnostics | Bounded lexical CPU checks and unknown `E12_K_` constant names |

Supported language IDs are `geos-esp`, `geos-nasm`, `geos-ui`, `geos-gp`,
`geos-goc`, `c`, `cpp`; aliases `esp`, `nasm`, `asm`, `ui`, `uic`, `gp`, `goc`
are accepted. Extension/content inference handles clients with generic IDs.
ESPIRE/UIC uses plain `start`, `object`, `visMoniker` and semicolon statements;
the distinct GOC dialect uses `@` directives. Comments and quoted text are
masked before lexical checks, including Esp `COMMENT` blocks and NASM backticks.

API data comes from `targetprofiles/ensemble12-abi.json`, with references under
`include/ensemble12/`. It describes the supplied Ensemble 1.2 target, kernel
622.3/UI 693.0, rather than every GEOS 1.x release. Completion of a bare native
API name inserts its actual `E12_K_`, `E12_UI_` or `E12_MSG_` constant. These are
numeric facts, not callable C wrappers. A C application needs an audited assembler
bridge and the correct target calling convention.

## Batch checks for external tools

Use the same checker without an LSP client:

```sh
perl tools/lsp/server.pl --check examples/hello-asm/hello.nasm
perl tools/lsp/server.pl --check examples/math-c/checksum.c --format json
perl tools/lsp/server.pl --check source.inc --language geos-nasm
```

Text output is `path:line:column: severity: message [code]`, with one-based line
and UTF-16 column. JSON preserves LSP zero-based ranges. Exit codes are 0 for no
errors (warnings may exist), 1 for lexical errors, and 2 for setup/read failures.
Multiple paths may follow `--check`.

The assembler checks flag later CPU/mode directives, later registers, a bounded
set of later instructions such as `PUSHA`, numeric immediate `PUSH`, and literal
shift/rotate counts greater than one. They do not parse macro expansions, symbolic
expressions, operand types or every instruction. Unknown `E12_K_` names produce
a warning about the curated subset; absence is not proof that an API does not
exist. Bare private aliases are not rejected. C identifiers are not interpreted
as assembler instructions.

This is not a compiler, complete syntax/type checker, UIC replacement, general
project indexer, linker, CPU emulator or API compatibility validator. Use the
real SDK build, object/geode inspectors and target runtime tests as well. No
diagnostics does not mean a source file builds or runs on an 8086.

## Protocol and verification

The implementation provides initialize/serverInfo, shutdown/exit, document
open/change/close, completion, hover, definition, documentSymbol, signatureHelp
and publishDiagnostics. It advertises full-text synchronization and also accepts
well-formed incremental changes. Positions and ranges use UTF-16 code units,
including astral Unicode characters. Closed-document diagnostics are cleared.

```sh
prove -v tests/lsp/test_lsp.t
```

Tests drive a real framed subprocess for C, NASM and Esp, plus batch checks,
UTF-16 edits, comment/string masking and UI/GOC separation. IDE setup examples
do not imply every supported IDE was installed and tested in this workspace.

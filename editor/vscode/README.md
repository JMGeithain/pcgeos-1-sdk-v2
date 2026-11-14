# PC/GEOS Language Tools for Visual Studio Code

[Deutsch](README-DE.md)

This extension adds TextMate syntax highlighting, comments, folding,
bracket pairs and structural snippets for these source formats. Its optional
local client connects to the SDK's Perl language server for completion,
API hovers, definitions and bounded source diagnostics.

| Language mode | Files | Comment syntax |
|---|---|---|
| PC/GEOS ESP | `.asm`, `.esp`, `.gasm`, `.def` | `;` and ESP `COMMENT` blocks |
| PC/GEOS NASM | `.nasm` | `;` |
| PC/GEOS ESPIRE/UIC | `.ui`, `.uih` | `/* ... */`, `//` |
| PC/GEOS Glue parameters | `.gp` | `#` |
| PC/GEOS GOC | `.goc`, `.goh` | C comments; C and inline assembly highlighting |

In particular, a semicolon **terminates a statement in ESPIRE**; it is not a UI
comment. In ESP and NASM, a semicolon starts a comment. The flat native GUI
example uses NASM's `BITS 16` and `CPU 8086`; Esp library sources use `.8086`
and Esp segment/procedure syntax. These assembler dialects are not interchangeable.

Highlighting is lexical support, **not an API or binary-compatibility check**.
GOC keywords and later x86 register names are highlighted so that developers can
inspect existing sources. This does not make those APIs, GOC object definitions,
instructions or later SDK headers valid on PC/GEOS 1.x. Use the SDK's selected
target profile and compiler checks. Structural snippets are incomplete templates,
not verified applications. The local language server does not replace a compiler,
GEOS debugger or emulator. Its API inventory covers the documented Ensemble 1.2
subset; it does not claim complete historical API or type checking.

## Install

Build the local VSIX from the SDK repository root with Perl 5.26 or newer:

```sh
perl editor/vscode/pack_vsix.pl
```

On Windows, `perl editor/vscode/pack_vsix.pl` is also suitable. The output is
`editor/dist/pcgeos1-language-support-0.2.0.vsix`. Install it through **Extensions: Install from
VSIX...** in the Command Palette, or use the VS Code CLI:

```sh
code --install-extension editor/dist/pcgeos1-language-support-0.2.0.vsix
```

Reload VS Code if prompted. No separate Node.js installation, npm download or
Marketplace account is needed to build/install this package. VS Code runs the
included JavaScript client; Perl 5.26+ runs the SDK language server. The build
is deterministic; package tests verify ZIP metadata and contributed files.
A real VS Code installation check is separate from the structural/client tests.

For extension development, open `editor/vscode` and use **Developer: Reload
Window** after editing an installed copy, or launch a separate extension-host
window with `code --extensionDevelopmentPath=editor/vscode` from the repository
root. This tests editor contributions, not GEOS execution.

## Configure the SDK workspace

Open the **SDK repository root** as the workspace. Copy the JSON files from
`editor/vscode/templates/` into `.vscode/`, merging with existing files rather
than overwriting your preferences. Change `pcgeos1.perlExecutable` to your
Perl 5.26+ executable:

| Host | Typical value |
|---|---|
| Linux | `perl`, or an absolute interpreter path |
| macOS | `perl`, or an absolute interpreter path |
| Windows | `perl`, or the full path to `perl.exe` |

Use one executable path as this setting, without arguments such as `-w`. Use a `perl.exe` path, or edit the task's command and argument
list explicitly. Paths containing spaces are handled as process arguments.

The optional tasks call `sdk.pl doctor`, `sdk.pl check`, `sdk.pl test`, and
`sdk.pl build --project <project>` from the workspace root. Set
`pcgeos1.project` to a real SDK project, then run **Tasks: Run Task**. The task
templates are examples; the SDK CLI remains authoritative if its options change.
No task runs automatically. Tasks require an appropriate trusted workspace.

## API completion and source checks

1. Open the SDK checkout as a trusted workspace, or set **PC/GEOS: SDK Root**
   (`pcgeos1.sdkRoot`) to its absolute path when editing a separate project.
2. Set `pcgeos1.perlExecutable` to a Perl 5.26+ executable in the same host
   environment. In WSL/Remote SSH, this is the remote Linux interpreter.
3. Open an Esp, NASM, UI, GP, GOC or C source file. Leave
   `pcgeos1.enableLanguageServer` enabled and run **PC/GEOS: Restart Language
   Server** if the settings changed.
4. Use **Trigger Suggest**, hover a documented API, **Go to Definition** for
   local/reference symbols, and the **Problems** panel for supported checks.
   **PC/GEOS: Open Ensemble 1.2 API Reference** opens the readable reference.

The client starts `tools/lsp/server.pl` from your SDK with Perl; it sends
source text to that local process. It uses no network service and starts no
compiler. Restricted Mode retains highlighting but does not launch Perl.
The **PC/GEOS SDK** output channel records startup errors.

Diagnostics cover the server's documented lexical and CPU checks. They do not
establish API availability beyond the catalog, memory safety, object-layout
validity or successful GEOS execution. Run `sdk.pl build` and native tests for
those separate stages. Other IDE clients use the same server; see the
[multi-IDE guide](../../docs/en/ide-integration.md).

The `.asm`/`.def`/`.gp` suffixes are also used by other toolchains. Use **Change
Language Mode** if a file is not GEOS source. Workspace `files.associations`
overrides let you scope the choice. Ordinary `.c` and `.h` files retain VS Code's
C mode; optional C/C++ extensions may improve navigation, but their host-sized
types do not establish 16-bit GEOS ABI correctness.

## Snippets and inspection

Use **Insert Snippet** or type `geos-proc`, `geos-method`, `geos-class`,
`geos-ui-resource`, `geos-ui-object`, `geos-gp-name`, `geos-gp-resource`,
`geos-goc-method` or `geos-goc-resource`. Fill in target-specific definitions and
document every assembly register/stack contract.

The NASM mode also supplies `g1-nasm-routine` and `g1-nasm-macro`. For a NASM
include using `.inc`, select the NASM mode manually or add a scoped file association.

Use **Developer: Inspect Editor Tokens and Scopes** to inspect tokens. This
extension uses standard TextMate scope families so existing color themes decide
the colors. It does not alter your theme.

## Publishing this extension

The local publisher name is `pcgeos1-community`; it is a package identity, not a
claim to own a Marketplace account. Before publishing to a Marketplace, choose a
publisher you control and review that service's current publishing requirements.
Local VSIX distribution through GitHub Releases needs no Marketplace publishing.
The original grammar, snippets, configuration, packaging code and this document
are MIT-licensed; no Microsoft fonts, proprietary SDK binaries or borrowed
extension grammar are included.

## Primary references

- [VS Code extension manifest](https://code.visualstudio.com/api/references/extension-manifest)
- [VS Code syntax highlighting](https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide)
- [VS Code contribution points](https://code.visualstudio.com/api/references/contribution-points)
- [VS Code snippets](https://code.visualstudio.com/api/language-extensions/snippet-guide)
- [Official GEOS Hello UI source](https://github.com/bluewaysw/pcgeos/blob/master/Appl/SDK_Asm/Hello/hello.ui), a later source reference for ESPIRE syntax, not proof of 1.x API availability

# IDE integration, completion and API help

[Handbook](README.md) · [Deutsch](../de/ide-integration.md)

The SDK supplies reusable syntax grammars and one small Perl language server.
Editors can show colors, suggest names, display the observed Ensemble 1.2
register contracts and underline selected source problems. The server uses
Perl's core modules and does not run a compiler, emulator or application.

## What each integration provides

| IDE | Highlighting asset | Completion, hover and live checks | Setup route |
|---|---|---|---|
| Visual Studio Code | Installable VSIX, TextMate grammars and snippets | Bundled client starts the SDK server in a trusted workspace | Install VSIX; select SDK and Perl paths |
| IntelliJ IDEA / other compatible JetBrains IDEs | Data-only TextMate bundle | Red Hat LSP4IJ user-defined server | Import bundle; add filename mappings |
| Eclipse | Existing JSON grammars through TM4E | LSP4E with a stdio launch configuration | Bind the same text content type to grammar and server |
| Apache NetBeans | JSON grammar through its custom-language settings | Generic LSP client | Register one language per grammar/dialect |
| Kate | Five KSyntaxHighlighting XML files | Kate LSP Client | Install XML files and adjust supplied JSON |
| KDevelop with Kate LSP support | Same KDE XML files | Kate LSP Client integration, where packaged | Install/enable Kate's plugin; use the same JSON |
| Older KDevelop or an IDE without a generic LSP client | Compatible grammar, where supported | Word completion plus external batch checks | Use the check/build commands below |

The protocol, reference catalog and assets have automated checks. Configuration
instructions for the other IDEs are grounded in their official documentation;
this release does not claim that every graphical IDE/version was installed and
tested interactively. A feature listed by an LSP client is available only when
the SDK server actually implements it.

## Languages and file associations

| Dialect | LSP language ID | Usual files | JSON grammar in `editor/vscode/syntaxes/` |
|---|---|---|---|
| Esp object assembly | `geos-esp` | `.esp`, `.gasm`, `.def`, `.asm` | `esp.tmLanguage.json` |
| NASM flat resource code | `geos-nasm` | `.nasm`; some projects use `.asm` | `nasm.tmLanguage.json` |
| Glue parameters | `geos-gp` | `.gp` | `gp.tmLanguage.json` |
| ESPIRE/UIC declarations | `geos-ui` | `.ui`, `.uih` | `uic.tmLanguage.json` |
| GOC declarations | `geos-goc` | `.goc`, `.goh` | `goc.tmLanguage.json` |
| Freestanding C | `c` | `.c`, `.h` | Use the editor's normal C colors |

`.asm` does not identify a dialect. Assign Esp library sources to ESP and flat
GUI resource sources to NASM. When the IDE only accepts extension associations,
choose one default and use `.nasm` for the other dialect where the project
recipe permits it. Do not register two competing automatic owners for `.asm`.

Highlighting GOC/UIC does not install their historical translators or make
later declarations work on 1.x. C++ file recognition is an editor convenience;
the delivered target examples are C, assembly and their reviewed combination.

For C files, keep the editor's C highlighting and add a `c` mapping to the SDK
server where the client permits it. The supplied KDE JSON covers the five
custom dialects; it does not replace an existing C server configuration.
KDevelop's native C support can also navigate the original
[`abi.h`](../../include/ensemble12/abi.h) constants, while the Markdown reference
supplies register contracts. A modern C parser may need configuration for
Watcom extensions and cannot certify 16-bit pointer sizes or target linkage.

## The shared language server

Every client starts the same process, using local absolute paths:

```sh
/absolute/perl /absolute/sdk/tools/lsp/server.pl --sdk-root /absolute/sdk
```

It communicates through standard input/output. A terminal that appears to wait
after this command is normal: the client must send framed LSP messages. Do not
add `echo` output or a shell banner to its standard output.

Portable wrappers are supplied as
[`pcgeos-lsp.sh`](../../editor/launchers/pcgeos-lsp.sh) and
[`pcgeos-lsp.cmd`](../../editor/launchers/pcgeos-lsp.cmd).
The optional `PCGEOS_PERL` environment variable selects one interpreter
executable, without arguments. Use Perl 5.26 or newer. On POSIX systems run
`chmod +x editor/launchers/pcgeos-lsp.sh` if archive extraction removed its mode.

Keep the IDE and server in an environment that sees the same file paths. For
Windows IDEs, native Windows Perl can run this server while a separate WSL
terminal handles builds. VS Code Remote WSL can instead run both editor
services and Perl in WSL. A naive cross-environment command does not translate
Windows document URIs into Linux paths.

### References and checks supplied

The catalog is [`targetprofiles/ensemble12-abi.json`](../../targetprofiles/ensemble12-abi.json).
It describes a bounded observed target: kernel 622.3 and UI 693.0. The readable
references are [English](../../include/ensemble12/API-EN.md) and
[German](../../include/ensemble12/API-DE.md). These are explicit numeric and
register facts, not a complete callable C API.

Completion includes the curated `E12_K_...` kernel constants, UI class/message
names, 8086 mnemonics/registers, dialect directives and simple local symbols.
Hover links to the local reference. Definition/outline support is deliberately
small and document based. Signature help describes recorded register
contracts; it does not infer all preserved registers or rewrite a C call into
the native GEOS calling convention.

Live checks flag selected later-CPU constructs, obvious unsupported operand
forms and references outside the curated constant subset. An unknown
`E12_K_...` name means the catalog lacks that entry, not that the real kernel
has no such function. This is a lexical aid rather than a full assembler,
macro expander, C type checker or proof of 8086/runtime correctness. Build and
test the program with the actual target tools.

## Visual Studio Code

Install the VSIX in [`editor/dist/`](../../editor/dist/) with **Extensions →
Install from VSIX**, or use `code --install-extension <the-vsix-path>`. Open
the SDK or your project, trust the workspace when appropriate and select the
right language mode. Settings are:

```json
{
  "pcgeos1.sdkRoot": "/absolute/sdk",
  "pcgeos1.perlExecutable": "/absolute/perl",
  "pcgeos1.enableLanguageServer": true
}
```

An empty `sdkRoot` searches open workspace folders for `tools/lsp/server.pl`.
The Perl value is an executable path, not a command containing arguments.
Use **PC/GEOS: Restart Language Server** after changing it and **PC/GEOS: Open
API Reference** for the reference browser. The client runs only in a trusted
workspace. The extension requires no npm dependency installation. See its
[README](../../editor/vscode/README.md) for tasks and extension details.

## IntelliJ IDEA and compatible JetBrains IDEs

Enable **TextMate Bundles** and import
[`editor/textmate/PCGEOS.tmbundle`](../../editor/textmate/README.md) under
**Settings → Editor → TextMate Bundles**. This gives syntax colors independently
of LSP. JetBrains also accepts compatible VS Code grammar directories.

Install Red Hat's **LSP4IJ** plugin. In its language-server settings, add a
user-defined server named `PC/GEOS`, use the shared Perl command above and
select stdio transport. In **Mappings**, add filename patterns and the language
IDs from the table. Prefer filename mappings over creating custom file types,
which can take coloring away from TextMate. Associate `.asm` with the dialect
used by that project. Leave installer/debug/socket fields unused: this SDK
server is already present and is a source assistant.

References: [JetBrains TextMate setup](https://www.jetbrains.com/help/idea/textmate.html),
[LSP4IJ user-defined servers](https://github.com/redhat-developer/lsp4ij/blob/main/docs/UserDefinedLanguageServer.md).

## Eclipse

Install **TM4E** and **LSP4E** if the distribution does not include them. Under
**Preferences → TextMate → Grammar**, import the appropriate JSON grammar and
bind it to a text content type with the desired filename associations. The
same content type must be used for LSP.

Create an external-program launch configuration: Perl is the executable;
arguments are `/absolute/sdk/tools/lsp/server.pl --sdk-root /absolute/sdk`.
Under **Preferences → Language Servers**, associate that configuration with
the content type. Open the file with **Open With → Generic Editor**. Apply
the same procedure for additional dialects. TM4E's Language Configuration
page can import the corresponding `language-configuration-*.json` editing rules.

This is LSP4E's documented user-configuration route, not an installed Eclipse
product plugin. See [LSP4E configuration](https://github.com/eclipse-lsp4e/lsp4e/blob/main/documentation/using-language-server-via-configuration-no-code.md)
and [TM4E's guide](https://github.com/eclipse-tm4e/tm4e/blob/main/docs/user-guide.md).

## Apache NetBeans

Use **Tools → Options → Editor → Language Servers → Add** in a distribution
with the generic LSP client. The custom-language dialog already exists in the
NetBeans 25 source; newer versions may expose extra fields.

Set a name, space-separated extensions **without** leading dots, the JSON
grammar path, and the shared server command. If the dialog offers **Language
Identifier**, use the table's ID; otherwise the server can infer the dialect
from filename/content. For example, NASM uses `nasm` as its extension and
`nasm.tmLanguage.json` as its grammar. Repeat for the other dialects.

The reviewed client stores its command by splitting on spaces. For paths with
spaces, point its Language Server field to a single launcher path without
spaces, and let that launcher quote the Perl/SDK paths. Keep **Enable
Breakpoints** disabled: this language server does not debug GEOS programs.

Primary references: [custom-language dialog source](https://github.com/apache/netbeans/blob/25/ide/lsp.client/src/org/netbeans/modules/lsp/client/options/LanguageDescriptionPanel.java),
[current storage/command handling](https://github.com/apache/netbeans/blob/master/ide/lsp.client/src/org/netbeans/modules/lsp/client/options/LanguageStorage.java),
[Apache LSP overview](https://cwiki.apache.org/confluence/spaces/NETBEANS/pages/263425900/Using+Language+Server+Protocol+LSP).

## Kate and KDevelop

Install the five XML files in [`editor/kate/`](../../editor/kate/README.md),
restart the editor and select `PC/GEOS ESP`, `PC/GEOS NASM`, `PC/GEOS GP`,
`PC/GEOS UI` or `PC/GEOS GOC`. The usual Linux user directory is
`~/.local/share/org.kde.syntax-highlighting/syntax/`; sandboxed packages and
other operating systems use the paths in the official KDE documentation.

Enable **LSP Client**. Replace every `/absolute/perl` and `/absolute/sdk`
placeholder in `lsp-servers.json`, then paste that configuration into **User
Server Settings**. New plugins use a nested `servers` object for each language;
older versions use the direct `command` entries supplied in
`lsp-servers-legacy.json`. Match the format shown in the installed plugin's
default configuration, and use one variant.

KDevelop gained Kate LSP integration with KDE Gear 25.04, initially requiring
Kate to be installed. Availability depends on the distribution's plugin
packaging. If its LSP settings are absent, use the syntax files plus external
checks, or use Kate alongside KDevelop. Existing Clang C/C++ support is not a
Watcom/GEOS ABI validator.

References: [KDE syntax locations](https://docs.kde.org/stable_kf6/en/kate/katepart/highlight.html),
[Kate LSP configuration](https://docs.kde.org/stable_kf6/en/kate/kate/kate-application-plugin-lspclient.html),
[KDevelop integration announcement](https://blogs.kde.org/2025/03/09/this-week-in-kde-apps/),
[KDevelop external scripts](https://dot.kde.org/2010/10/26/kdevelop-41-brings-git-integration/).

## Batch checks and build tasks in any IDE

The same source diagnostics can run as an external tool:

```sh
perl tools/lsp/server.pl --sdk-root . --check path/to/source.nasm --format text
perl tools/lsp/server.pl --sdk-root . --check path/to/source.asm --language geos-nasm --format json
perl sdk.pl check
perl sdk.pl build --project examples/math-asm
```

Text output uses `file:line:column: severity: message`, with one-based display
positions. JSON retains the LSP ranges. Error diagnostics return exit status 1;
warnings alone return 0; an input/setup failure returns 2. Save source files
before invoking batch checks or builds. Add these commands to External Tools,
External Scripts or a project build target, with the SDK root as working
directory. The live server checks unsaved buffers; the build reads disk files.

Test integration by completing `E12_K_Mem`, hovering `E12_K_MemAlloc` and adding
`pusha` to an assembly scratch file. The later-CPU diagnostic should appear;
delete the test instruction afterward. If nothing happens, verify the language
mode, Perl path, API catalog location and the client's server log first.

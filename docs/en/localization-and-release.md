# Localization, packaging and GitHub releases

[Handbook](README.md) · [Deutsch](../de/localization-and-release.md)

A useful SDK release is understandable, reproducible and honest about its supported target. The German documentation should describe the same commands and validation limits as the English documentation, not a different product.

## Keep language and program identity separate

Put user-facing strings, mnemonics and translatable resources in a deliberate localization layer. Keep internal module names, export identities, protocol values, message identifiers and file-format signatures stable unless the technical interface changes.

English and German builds should read the same application documents when the data format is language-independent. Do not translate serialized enumeration values or protocol tokens by accident.

The later [localization manual](https://bluewaysw.github.io/pcgeos/Concepts/clocal.html) describes resource-oriented localization. Use the target's actual tools, string representation and character set; a modern UTF-8 source editor does not make a 1.x native resource UTF-8.

## German UI checks

Test umlauts, `ß`, punctuation, keyboard accelerators and long compound labels. Measure text using the actual installed target font. Let supported geometry adapt rather than squeezing German text into an English-sized fixed rectangle.

A translated caption should not change a control's action or owner. Check whether ellipses are added by the native UI before appending them to a source label; otherwise the final text can contain repeated dots. Use consistent terminology across menus, dialogs, help and documentation.

Documentation can be UTF-8 Markdown even when target resources use a different encoding. Describe that conversion explicitly. Validate the source and compiled resource, rather than trusting how the editor displays a byte sequence.

## Repository contents

Keep original project source, build scripts, selected configuration examples, tests, documentation, license and notices under version control. Keep generated output and local machine paths out unless a release deliberately includes a verified generated artifact.

Do not commit a whole commercial runtime, compiler installation or SDK archive. Create a manifest that tells users where to obtain required inputs and how to verify them. If a third-party component is redistributable, retain its license/notice and record its source revision and build method.

The current FreeGEOS repository's license does not automatically license a different historical SDK, a proprietary compiler, Windows fonts or a user-supplied runtime. Apply licenses by provenance, not by filename or age.

## Before uploading to GitHub

1. Check that the clean repository contains no credentials, personal documents or developer-specific runtime state.
2. Run `perl sdk.pl check` and `perl sdk.pl test`.
3. Bootstrap the selected tools from documented inputs in a fresh directory.
4. Build each advertised example and preserve its build record.
5. Verify the native tests required for the release's compatibility labels.
6. Check every relative documentation link in both languages.
7. Install and test the VS Code extension from its packaged artifact, not only its source directory.
8. Check licenses/notices and identify separately required proprietary assets.
9. Tag the source revision, create the archive and record its SHA-256.
10. Test extraction and rebuilding from the actual release archive.

Creating a GitHub-ready archive and publishing it are separate steps. Create an empty repository in the intended account, inspect the source tree and ignored local assets, then use your actual repository URL:

```sh
git init
git add .
git status
git diff --cached
git commit -m "Initial PC/GEOS 1.x community SDK"
git branch -M main
git remote add origin https://github.com/OWNER/REPOSITORY.git
git push -u origin main
```

Replace `OWNER/REPOSITORY`; do not paste that placeholder literally. Review the staged files before committing. If the directory is already a Git checkout, keep its existing history and remote configuration rather than reinitializing or replacing them. Attach verified release archives to a tagged release; source commits and generated release artifacts have different roles.

## Release notes

State what changed, the supported build routes and important behavior. Include a small compatibility table listing target release/language, CPU, driver, memory configuration, build status and native test status.

Avoid calling a release a complete historical SDK if it supplies only an API subset or only import-free libraries. That smaller scope can still be useful when clearly described. A blocked GUI application profile should be listed as blocked, with the missing prerequisites and the path to establish them.

For a binary-derived transformation, identify the exact compiled template and clarify that the package does not contain its original full source. Keep rejected prototypes out of the release build plan and out of the advertised test results.

## Reproducible archives

A release should have one explicit source selection. Do not let a wildcard choose whichever experimental manifest happens to have the newest timestamp. Record exact tool revisions, patches and selected flags.

A byte-identical rebuild is strong evidence of source/output identity. It does not replace native behavior tests. Conversely, a screenshot without an output hash does not identify the binary that produced it.

If archive tools drop executable permission bits, document a safe restoration for bundled host executables or have the bootstrap validate and set them. Keep the source route usable without requiring a preinstalled copy of the developer's private tool tree.

## Installation and recovery instructions

Tell users which output is an application and which is a library, where it belongs for the selected target, and how to remove it. Back up a module before replacing it. Prefer distinct module names for experimental replacements so the original remains available.

Do not distribute an installer that rewrites a user's entire `GEOS.INI`. Document the small required change and preserve unrelated settings. Use the target's correct text format and line endings. Include a clear return-to-DOS and recovery route for system-facing modules.

# Original native GUI example

This application opens a native Ensemble 1.2 window and draws original vector
rectangles and small pixel glyphs. The process, application, primary and view
resources are freshly generated. No commercial program's serialized UI, icon
or code is a build input.

```sh
perl sdk.pl toolchain install
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
```

Run those commands from the SDK root. The target directory must match the
documented profile; it is checked but not copied into the output. The program
is `build/g1hello/g1hello.geo`, permanent name `g1hello.app`, display name
`GEOS 1 SDK Hello`. After exiting GEOS cleanly, copy that file into a test
installation's `WORLD` directory, restart and launch it from GeoManager.

Expected contents: a blue header with `HELLO GEOS`, a cyan/green stack of
rectangles, and `SDK1`/`8086` captions. Test expose/uncover, minimize/restore,
resize, task switching and normal close. The fixed-size illustration does
not scale to fill a larger view. Read the root validation report for the
actual tested target and CPU settings; NASM's `CPU 8086` directive alone does
not establish that every OS/driver instruction is8086-compatible.

The source is `hello.nasm`; the NASM suffix distinguishes it from ESP source in
the editor extension. Start with [the backend contract](../../tools/ensemble12/README.md)
before adding native calls. C/GOC system wrappers and arbitrary 1.x targets are
outside this bounded example's API.

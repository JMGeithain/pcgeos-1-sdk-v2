# Native library integration probe

This GUI extends the original [hello example](../hello-asm/README.md) and
imports the assembly, C and mixed libraries through their own documented ABIs.
It displays `PASS` only if all five comparisons in `library_probe.inc` pass;
otherwise it displays `FAIL`. It exercises real loader imports, far calls, C
argument cleanup and the mixed resource boundary. It is a non-document probe.

From the SDK root, bind the library header requirements to your matching native
UI reference, then build the application against the exact target profile:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /path/to/owned/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-c --kernel-reference /path/to/owned/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-mixed --kernel-reference /path/to/owned/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/hello-libraries --target-root /path/to/owned/GWSVGA
```

Exit GEOS cleanly. In a disposable test installation, copy the three library
outputs (`build/g1math/g1math.geo`, `build/g1mathc/g1mathc.geo` and
`build/g1mixed/g1mixed.geo`) to `SYSTEM`, and `build/g1probe/g1probe.geo` to `WORLD`.
Restart GEOS and launch `GEOS 1 Library Probe`. Do not double-click the library
files; they are dependencies. The app permanently identifies as `g1probe.app`.

Kernel is implicit, UI occupies import index 0, and the three example libraries
occupy indices1..3. The native imported-call relocation is14h, not a guessed
kernel-style far-pointer relocation. All library protocols are1.0. Read each
library's README for register, segment and stack contracts. Neither the C
export nor this probe supplies a general C system API.

The root validation record identifies actual runtime test results. A build
success or format report alone does not establish that the probe ran or passed.

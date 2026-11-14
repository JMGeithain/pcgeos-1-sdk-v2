# Original prebuilt samples

[Deutsch](README.de.md) · [Validation](../../../VALIDATION.md)

These five files were built from the SDK's original sources and used in the recorded Ensemble 1.2 / 8086 / 640 KB tests. They contain no historical application template or runtime resources. Their identities are listed in `samples.json`.

Verify your separately obtained target with `perl sdk.pl verify-target /path/to/GWSVGA`. Exit GEOS cleanly and back up a disposable installation. Copy the contents of `WORLD` to its `WORLD`, and the three `SYSTEM` libraries to its `SYSTEM`. Do not replace existing unrelated files. Start GEOS and launch **GEOS 1 SDK Hello** or **GEOS 1 Library Probe**. The libraries are dependencies, not launchable applications.

The library probe should display **PASS**. Read the source and [native walkthrough](../../../docs/en/native-applications.md) before changing it. These samples are tied to the recorded target profile; they do not certify other Ensemble releases, system translations or drivers.

The original code is covered by the repository's MIT license. A GEOS runtime, compiler and emulator are not included here.

@echo off
rem SPDX-License-Identifier: MIT
setlocal
if not defined PCGEOS_PERL set "PCGEOS_PERL=perl"
"%PCGEOS_PERL%" "%~dp0..\..\tools\lsp\server.pl" --sdk-root "%~dp0..\.." %*

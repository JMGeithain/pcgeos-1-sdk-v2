#!/bin/sh
# SPDX-License-Identifier: MIT
# Keep stdout exclusively for the language-server protocol.
set -eu
pcgeos_sdk_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
exec "${PCGEOS_PERL:-perl}" "$pcgeos_sdk_root/tools/lsp/server.pl" --sdk-root "$pcgeos_sdk_root" "$@"

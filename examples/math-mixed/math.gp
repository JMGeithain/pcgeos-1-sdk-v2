# SPDX-License-Identifier: MIT
name g1mixed.lib
type library, single
longname "GEOS 1.x Mixed Example"
tokenchars "G1MX"
tokenid 0

# No initializer and no imported system library.
resource ALGORITHM fixed code shared read-only
resource BridgeCode fixed code shared read-only
export ChecksumStep
export SaturatingAdd

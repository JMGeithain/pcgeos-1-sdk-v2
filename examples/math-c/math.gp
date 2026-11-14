# SPDX-License-Identifier: MIT
name g1mathc.lib
type library, single
longname "GEOS 1.x Scalar C Example"
tokenchars "G1MC"
tokenid 0

# No entry routine: this module has no initialization or C runtime.
# The exported interface is OUR explicitly documented far __cdecl ABI.
# Do not add the later c-api geode attribute merely because the source is C.
resource ALGORITHM fixed code shared read-only
export _ChecksumStepC

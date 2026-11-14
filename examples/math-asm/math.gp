# SPDX-License-Identifier: MIT
name g1math.lib
type library, single
longname "GEOS 1.x Assembly Math"
tokenchars "G1MA"
tokenid 0
entry LibraryEntry

# There are no imported libraries and no calls into the GEOS API.
# Fixed code keeps this tiny example's call/return contract uncomplicated.
resource MathCode fixed code shared read-only
export AddWords

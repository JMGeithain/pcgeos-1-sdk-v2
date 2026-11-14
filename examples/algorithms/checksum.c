/* SPDX-License-Identifier: MIT */
#include "checksum.h"

G1U16 G1_ALGORITHM_CALL
geos1_checksum_step(G1U16 state, G1U16 byte_value)
{
    G1U16 rotated;
    rotated = (G1U16)((state << 5) | (state >> 11));
    return (G1U16)(rotated ^ (byte_value & 255u));
}

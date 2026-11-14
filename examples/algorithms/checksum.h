/* SPDX-License-Identifier: MIT
 * Original scalar-only example. This header does not define a GEOS API.
 */
#ifndef GEOS1_EXAMPLE_CHECKSUM_H
#define GEOS1_EXAMPLE_CHECKSUM_H

typedef unsigned short G1U16;
typedef char g1_requires_16_bit_short[(sizeof(G1U16) == 2) ? 1 : -1];

#if defined(__WATCOMC__)
# define G1_ALGORITHM_CALL __near __cdecl
#else
# define G1_ALGORITHM_CALL
#endif

/* Rotate the 16-bit state left five bits, then XOR one low-eight-bit value.
 * No pointers, globals, runtime services, or floating point are used.
 */
G1U16 G1_ALGORITHM_CALL geos1_checksum_step(G1U16 state, G1U16 byte_value);

#endif

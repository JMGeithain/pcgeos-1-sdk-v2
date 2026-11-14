/* SPDX-License-Identifier: MIT
 * A complete freestanding C algorithm module, not a GEOS system-C wrapper.
 * Its public interface is explicitly far __cdecl and uses only word scalars.
 */
typedef unsigned short Word;
typedef char word_must_be_16_bits[(sizeof(Word) == 2) ? 1 : -1];

#if defined(__WATCOMC__)
# define LIBRARY_C_ABI __far __cdecl
#else
# define LIBRARY_C_ABI
#endif

Word LIBRARY_C_ABI ChecksumStepC(Word state, Word byte_value)
{
    Word rotated;
    rotated = (Word)((state << 5) | (state >> 11));
    return (Word)(rotated ^ (byte_value & 255u));
}

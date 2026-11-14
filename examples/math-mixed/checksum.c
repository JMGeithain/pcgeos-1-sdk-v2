/* SPDX-License-Identifier: MIT
 * Internal far-C core. The assembly veneer provides the public register ABI.
 */
typedef unsigned short Word;
typedef char word_must_be_16_bits[(sizeof(Word) == 2) ? 1 : -1];

Word __far __cdecl ChecksumFar(Word state, Word byte_value)
{
    Word rotated;
    rotated = (Word)((state << 5) | (state >> 11));
    return (Word)(rotated ^ (byte_value & 255u));
}

/**
 * Reads width/height directly from PNG/JPEG file bytes without any image
 * library — both formats store their dimensions in a small, well-known
 * header that's cheap to parse by hand. Returns null for anything else
 * (or if parsing fails), which callers should treat as "unknown/portrait".
 */
export function getImageDimensions(buffer: Buffer): { width: number; height: number } | null {
  try {
    // PNG: signature (8 bytes) + IHDR chunk starts at byte 8, width/height
    // are the first two 4-byte big-endian integers inside it.
    if (buffer.length > 24 && buffer.readUInt32BE(0) === 0x89504e47) {
      const width = buffer.readUInt32BE(16);
      const height = buffer.readUInt32BE(20);
      return { width, height };
    }

    // JPEG: walk the marker segments looking for an SOFn (Start Of Frame)
    // marker, which holds the actual pixel dimensions.
    if (buffer.length > 4 && buffer[0] === 0xff && buffer[1] === 0xd8) {
      let offset = 2;
      while (offset < buffer.length - 8) {
        if (buffer[offset] !== 0xff) {
          offset++;
          continue;
        }
        const marker = buffer[offset + 1];
        const isSOF =
          marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc;

        if (isSOF) {
          const height = buffer.readUInt16BE(offset + 5);
          const width = buffer.readUInt16BE(offset + 7);
          return { width, height };
        }

        const segmentLength = buffer.readUInt16BE(offset + 2);
        offset += 2 + segmentLength;
      }
    }

    return null;
  } catch {
    return null;
  }
}

export function isLandscape(buffer: Buffer): boolean {
  const dimensions = getImageDimensions(buffer);
  return dimensions !== null && dimensions.width > dimensions.height;
}

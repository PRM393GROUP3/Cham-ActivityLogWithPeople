export type ImageFormat = { ext: string; contentType: string };

const startsWith = (bytes: Uint8Array, signature: number[], offset = 0) =>
  signature.every((b, i) => bytes[offset + i] === b);

const ascii = (s: string) => [...s].map((c) => c.charCodeAt(0));

/**
 * Detects JPEG / PNG / WebP from the file's magic bytes. The client's Content-Type is never
 * trusted, so a stored "image" can't turn out to be HTML or script.
 */
export const detectImageFormat = (bytes: Uint8Array): ImageFormat | null => {
  if (startsWith(bytes, [0xff, 0xd8, 0xff])) return { ext: "jpg", contentType: "image/jpeg" };
  if (startsWith(bytes, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) return { ext: "png", contentType: "image/png" };
  if (startsWith(bytes, ascii("RIFF")) && startsWith(bytes, ascii("WEBP"), 8)) return { ext: "webp", contentType: "image/webp" };
  return null;
};

const toHex = (bytes: ArrayBuffer) =>
  Array.from(new Uint8Array(bytes), (b) => b.toString(16).padStart(2, "0")).join("");

const toBase64Url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

/** 256-bit random bearer token. Only its hash is stored, so a DB leak doesn't leak sessions. */
export const generateToken = () => toBase64Url(crypto.getRandomValues(new Uint8Array(32)));

export const hashToken = async (token: string) =>
  toHex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token)));

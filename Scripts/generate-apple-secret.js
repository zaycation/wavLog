#!/usr/bin/env node
// Generates the Apple Sign In JWT client secret required by Supabase.
// Run: node Scripts/generate-apple-secret.js
//
// Fill in the four constants below before running.

const crypto = require("crypto");
const fs = require("fs");

// ─── Fill these in ────────────────────────────────────────────────────────────
const TEAM_ID = "U3F9NUVPW6"; // 10-char Team ID from developer.apple.com → Membership
const CLIENT_ID = "com.isaiahthomas.wavlog"; // Native iOS: use bundle ID, not Services ID
const KEY_ID = "24XG8CG868"; // 10-char Key ID from developer.apple.com → Keys
const P8_KEY_PATH = "../../Downloads/AuthKey_24XG8CG868.p8"; // Path to the .p8 file you downloaded
// ─────────────────────────────────────────────────────────────────────────────

if (
  TEAM_ID.startsWith("X") ||
  KEY_ID.startsWith("X") ||
  P8_KEY_PATH.includes("XXXXXXXXXX")
) {
  console.error("❌  Fill in TEAM_ID, KEY_ID, and P8_KEY_PATH before running.");
  process.exit(1);
}

const privateKey = fs.readFileSync(P8_KEY_PATH, "utf8");

const now = Math.floor(Date.now() / 1000);
const exp = now + 15_552_000; // 180 days (Apple's max is 6 months)

const header = Buffer.from(
  JSON.stringify({ alg: "ES256", kid: KEY_ID }),
).toString("base64url");
const payload = Buffer.from(
  JSON.stringify({
    iss: TEAM_ID,
    iat: now,
    exp: exp,
    aud: "https://appleid.apple.com",
    sub: CLIENT_ID,
  }),
).toString("base64url");

const signingInput = `${header}.${payload}`;

const sign = crypto.createSign("SHA256");
sign.update(signingInput);
// Apple's .p8 keys use IEEE P1363 encoding (raw r||s), not DER
const signature = sign.sign(
  { key: privateKey, dsaEncoding: "ieee-p1363" },
  "base64url",
);

const jwt = `${signingInput}.${signature}`;

console.log("\n✅  Apple Client Secret JWT (paste this into Supabase):\n");
console.log(jwt);
console.log(
  `\n⏰  Expires: ${new Date(exp * 1000).toDateString()} — regenerate before then.\n`,
);

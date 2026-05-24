# Security plan

## Where we are today

This codebase is a UI prototype. There is no real auth, no real backend,
and no real cryptography. Every "encrypted" indicator in the UI is
decorative. **Do not ship this to real users in its current form.**

## Where we're going

The product positions itself as "AI-native, privacy-first." To honor the
second half of that claim we need end-to-end encryption (E2EE), which
means the server cannot read message contents — only the sender and
recipient(s) can.

### Why we are not forking Signal

It is tempting to fork `signalapp/Signal-iOS`, `Signal-Desktop`, or
`Signal-Server`. We are not doing that for two reasons:

1. **AGPL-3.0 licensing**. All of those projects (and `libsignal`,
   which is GPL-3.0) are copyleft. Substantive use forces our entire
   client and server source to be made available to every user. That is
   incompatible with a closed commercial offering, and Apple App Store
   policies have historically had friction with strict AGPL apps.
2. **The Signal Protocol is not Signal's code.** "Signal-level security"
   means using the *protocol* — X3DH + Double Ratchet, or its successor
   MLS — not the same source.

### What we will use instead

**MLS (RFC 9420)** via [OpenMLS](https://github.com/openmls/openmls) is
the recommended path:

- Apache 2.0 / MIT licensed (permissive, ships with closed apps)
- Designed for **groups** out of the gate (Signal Protocol was bolted on
  for groups; MLS makes group key agreement first-class)
- Stronger forward secrecy than Double Ratchet in group settings
- Active IETF standard, used by Wire, Matrix Element X, Discord (video)
- Rust core can be wrapped for iOS (via FFI) and Web (via WASM)

Backup options if MLS proves too heavy:

- [`vodozemac`](https://github.com/matrix-org/vodozemac) — Matrix's
  Olm/Megolm in Rust, Apache 2.0
- Raw [libsodium](https://doc.libsodium.org/) primitives + a hand-rolled
  Double Ratchet (more work; do not recommend unless you have a
  cryptographer on the team)

## Implementation phases

E2EE is not a v1 feature. Plan to ship in this order:

### Phase 1 — Transport security only

- TLS 1.3 between client ↔ server
- Auth with magic-link email (Supabase or Clerk)
- Server has read access to all messages — this is OK for an MVP
- The UI keeps its lock icons; copy says "encrypted in transit"

### Phase 2 — Device identity + key storage

- Per-device long-lived signing key (Ed25519)
- Key generated on first install, stored in:
  - **iOS**: Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
  - **Web**: IndexedDB with non-extractable WebCrypto keys
- Public keys uploaded to server, signed by user account
- Begin showing real device-verification UI in the encryption sheet

### Phase 3 — Pairwise E2EE (1:1 chats)

- Integrate `libsignal-client` or OpenMLS for 1:1 sessions
- Server stores ciphertext only; cannot decrypt
- Add a "verify with QR" flow in the encryption sheet
- Push notifications carry only a tiny encrypted envelope; client
  decrypts before showing the message body

### Phase 4 — Group E2EE (group chats + spaces)

- MLS group key agreement
- Add/remove member triggers a key rotation; old members can't read new
  messages
- AI ("Pulse") becomes an explicit group member with its own keypair,
  and the user must add it on purpose. This makes the "AI sees your
  messages" decision visible and revocable.

### Phase 5 — Forward secrecy + recovery

- Periodic key rotation
- Recovery key (one-time download, store offline) for re-onboarding a
  new device when all current devices are lost

## What we do *not* do, ever

- We do not log message contents on the server
- We do not back up plaintext to S3 / Postgres
- We do not train models on user messages
- We do not retain message metadata beyond what is needed for delivery
- We do not allow admin "break-glass" access to any user's conversation

## Open work

- Threat model document (who are we defending against?)
- Cryptography review (external auditor — Trail of Bits, NCC Group)
- Bug bounty program before public launch
- Annual penetration test

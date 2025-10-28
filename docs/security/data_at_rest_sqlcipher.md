# Data at rest: SQLCipher configuration

This document explains how data-at-rest encryption is configured and what parameters are used.

## Summary

- Provider: SQLCipher (via `sqlcipher_flutter_libs` with `sqflite_common_ffi`)
- Key material: 256-bit random secret stored in platform secure storage
- Page size: 4096
- KDF iterations: 64,000
- HMAC algorithm: HMAC-SHA512
- KDF algorithm: PBKDF2-HMAC-SHA512

Code reference:
- `lib/db/database_helper.dart` (DB open/configuration)
- `lib/services/encryption_key_service.dart` (key generation and storage)

## Key generation and storage

- A 256-bit random key is generated on first run using `Random.secure()` and stored in `FlutterSecureStorage`.
- The stored value is base64url-encoded; the raw bytes are used as the SQLCipher key via `PRAGMA key` when opening the database.

## PRAGMA configuration

On `onConfigure`, the following PRAGMAs are executed before any other DB operation:
- `PRAGMA key = '<secret>';`
- `PRAGMA cipher_page_size = 4096;`
- `PRAGMA kdf_iter = 64000;`
- `PRAGMA cipher_hmac_algorithm = HMAC_SHA512;`
- `PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;`
- `PRAGMA foreign_keys = ON;`

These settings enforce AES-256 with SHA-512 based KDF/HMAC and a higher KDF cost for better brute-force resistance.

## Directory and path safety

- On Windows, the app prefers the local `Documents` folder over OneDrive to reduce sync-related issues.
- The resolved DB path is validated to ensure it stays within the intended directory (basic path traversal prevention).

## Assets and dev-mode sync

- If an asset DB exists, it may be copied on first run for development convenience.
- A debug-only helper (`syncToAssets`) can sync the runtime DB back to `assets/db/` to persist new seed data; auto-push is disabled by default and guarded with warnings.

## Operational notes

- Backups: encrypted DB files can be backed up, but ensure the key in secure storage is also backed up securely if you need disaster recovery.
- Rotation: rotating the DB key requires rekeying (e.g., `PRAGMA rekey = '<newkey>'`) after opening with the old key; not implemented by default.
- Lockdown mode: if `clearKeys()` is called in `EncryptionKeyService`, the DB becomes inaccessible until reinitialized with a new key.

## Future hardening (optional)

- Consider adding `cipher_memory_security` options if available in your SQLCipher build.
- Add a key rotation utility that performs `PRAGMA rekey` safely during maintenance windows.
- Integrate integrity checks (e.g., `PRAGMA cipher_integrity_check;`) on startup in debug or periodically in production.

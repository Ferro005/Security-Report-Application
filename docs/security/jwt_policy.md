# JWT Session Policy

This document describes how JSON Web Tokens (JWT) are used in this app and the recommended operational practices.

## Summary

- Algorithm: HS256 (symmetric, secret stored in secure storage)
- Access token lifetime: 30 minutes
- Auto-refresh: if near expiry (<5 minutes), issue a new token
- Refresh window: up to 24 hours from issuance (token contains `rte` claim)
- Device binding: tokens include `deviceId` and are only valid on the device that issued them
- Storage: tokens are held in memory during app runtime; the signing key and device id are stored in platform secure storage
- Revocation: rotate the signing secret to invalidate all outstanding tokens

Code reference:
- `lib/services/session_service.dart`

## Token structure and claims

The token payload includes:
- userId: integer user identifier
- email: user email
- role: user role (e.g., admin/usuario)
- iat: issued-at (seconds since epoch)
- exp: expiration (seconds since epoch)
- rte: refresh-until (seconds since epoch)
- deviceId: local device identifier

Signing: HS256 using a 256-bit secret generated on first run and persisted via `FlutterSecureStorage`.

## Lifetimes and refresh

- Access token lifetime is 30 minutes.
- If the remaining time is less than 5 minutes (or expired), the app refreshes the token automatically by issuing a new token with a fresh `exp`.
- A refresh is only allowed if current time is before `rte` (24 hours from issuance).
- There is no separate refresh token concept; the app uses short-lived access tokens with opportunistic refresh within a bounded window.

Trade-offs:
- Simpler client logic for a local/desktop-focused app.
- If stronger revocation granularity is required, add a refresh token store and a server-side denylist.

## Secret management and rotation

- The JWT signing secret is generated randomly (256-bit) on first use and stored via `FlutterSecureStorage` under the key `jwt_secret_key`.
- To invalidate all tokens, rotate the secret by deleting/replacing the stored key (e.g., on logout all or security incident).
- Consider periodic rotation (e.g., quarterly) combined with forced re-authentication.

## Storage guidance

- Do not persist tokens to disk unless strictly necessary.
- Avoid logging tokens; logs should mask or omit sensitive data (the app’s `SecureLogger` already masks sensitive fields where feasible).

## Revocation strategies

Depending on needs:
- Global revocation: rotate the secret key (all tokens immediately invalid).
- Per-user revocation: add a `tokenVersion` field in DB and include it in the JWT; increment on password reset or manual revoke.
- Session denylist: maintain a short TTL denylist for known-bad tokens.

## Hardening checklist

- [x] HS256 with random 256-bit key stored in secure storage
- [x] 30m validity with early refresh at <5m and max refresh window 24h (`rte`)
- [x] Device binding via `deviceId`
- [x] Minimal claims
- [x] Errors logged without leaking secrets
- [ ] Optional: implement per-user tokenVersion to support selective revocation
- [ ] Optional: add CSRF countermeasures if embedding in a webview or browser context
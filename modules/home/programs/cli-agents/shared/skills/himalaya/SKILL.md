---
name: himalaya
description: Configure and use Himalaya CLI email client with Protonmail Bridge. Use when setting up himalaya, debugging IMAP/SMTP connection issues, or managing email from the terminal. Covers config format for v1.2.0, Protonmail Bridge quirks, and common commands.
---

# Himalaya CLI Email

Rust-based CLI email client. Connects to Protonmail via Bridge's local IMAP/SMTP.

## Config Location

`~/.config/himalaya/config.toml`

## Protonmail Bridge Setup

Bridge exposes local IMAP/SMTP — credentials come from Bridge, not your Proton account.

Get credentials: `protonmail-bridge --cli` → `login` → `info`

- IMAP: `127.0.0.1:1143`
- SMTP: `127.0.0.1:1025`
- Login: your Proton email address
- Password: Bridge-generated token (NOT your account password)

## Config Template (v1.2.0)

```toml
[accounts.proton]
default = true
email = "your@proton.me"
display-name = "Your Name"
downloads-dir = "~/Downloads"

backend.type = "imap"
backend.host = "127.0.0.1"
backend.port = 1143
backend.encryption.type = "none"
backend.login = "your@proton.me"
backend.auth.type = "password"
backend.auth.cmd = "pass show proton/bridge"

message.send.backend.type = "smtp"
message.send.backend.host = "127.0.0.1"
message.send.backend.port = 1025
message.send.backend.encryption.type = "none"
message.send.backend.login = "your@proton.me"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show proton/bridge"
```

## Critical Config Gotchas

1. **Encryption MUST be `"none"`** — Bridge uses a self-signed cert that causes `CaUsedAsEndEntity` TLS errors with rustls. Localhost-only so no security risk.
2. **Password key is `auth.cmd`** for shell commands, `auth.raw` for inline, `auth.keyring` for system keyring. NOT `auth.command` — that's an invalid key.
3. **Login is your full email** even though Bridge generates a separate password.

## Common Commands

```bash
himalaya envelope list              # List inbox
himalaya envelope list -f Sent      # List sent
himalaya message read <ID>          # Read message
himalaya message write              # Compose (opens $EDITOR)
himalaya message reply <ID>         # Reply
himalaya message forward <ID>       # Forward
himalaya attachment download <ID>   # Download attachments
himalaya folder list                # List folders
```

## Debugging

```bash
himalaya envelope list --debug      # Debug logs
himalaya envelope list --trace      # Verbose trace + backtrace
```

Common errors:
- **`CaUsedAsEndEntity`** → Set `encryption.type = "none"` for both IMAP and SMTP
- **`cannot parse configuration`** → Check for invalid keys (e.g., `auth.command` instead of `auth.cmd`)
- **`authentication failed`** → Use Bridge password, not Proton account password
- **IMAP warning about continuation request** → Harmless Bridge quirk, can ignore

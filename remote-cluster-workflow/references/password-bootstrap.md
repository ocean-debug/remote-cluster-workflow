# Password Bootstrap

Use this flow when the user can already log in through MobaXterm with a username and password, but Codex cannot yet authenticate through local OpenSSH.

## Goal

Convert the server to key-based access for this machine without changing the user's normal workflow. The easiest path is to reuse the user's already-open MobaXterm terminal once, then let Codex use `%USERPROFILE%\\.ssh\id_ed25519`.

## Steps

1. Read the local public key from `%USERPROFILE%\\.ssh\id_ed25519.pub`.
2. Ask the user to paste one command into their existing remote shell:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && printf '%s\n' 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
```

3. After the user confirms, test:

```powershell
ssh -o BatchMode=yes user@host "hostname"
```

4. Only after the test succeeds, continue with remote task execution.

## Why This Is Preferred

- Avoids handling or storing the user's password in Codex workflows
- Works with standard OpenSSH already present on Windows
- Makes future remote tasks fully non-interactive
- Keeps the skill simple and robust


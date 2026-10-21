---
name: "source-command-add-secret"
description: "Walk the user through encrypting a new (or rotated) secret into the chezmoi source."
---

# source-command-add-secret

Use this skill when the user asks to run the migrated source command `add-secret`. The user supplies the path to a plaintext file in `$HOME`.

## Command Template

The user wants to add or rotate a secret at the path they gave.

Steps:

1. Confirm the path exists in `$HOME` and is readable. If not, ask for the correct path.
2. **Read** the file just enough to confirm it looks like a secrets file (e.g., `.zshrc.local`, AWS config, an env file). Do not print its contents back to the user. If it doesn't look like secrets, ask whether they really want to encrypt it.
3. Tell the user the exact command to run **themselves** in their terminal:

   ```bash
   chezmoi add --encrypt <path>
   ```

   Do not run it yourself, even though `.codex/hooks/guard-destructive.sh` lets `chezmoi add --encrypt` through. Encryption-bearing operations are user-gated in this repo; under Claude Code, `settings.json` denies `chezmoi add` outright, and Codex has no equivalent deny.

4. After they run it, walk them through verification:
   - `chezmoi diff` — should show only the encrypted blob change.
   - `git status` — confirm the new/updated `encrypted_*.age` file appears.
   - `git diff --stat` — confirm no plaintext file was staged.

5. If `git status` or `git diff` shows a plaintext credential anywhere, **stop immediately** and instruct the user to `git restore --staged <file>` and clean up before committing.

Hard rules: never print the plaintext content of any file matching `*.local`, `*.env`, `*credential*`, or `*key*`. Never `cat` such files.

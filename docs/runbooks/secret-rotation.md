# Runbook: rotate a secret or the age key

Two distinct scenarios. Pick the right one.

## Rotate a single secret (e.g. AWS key, GitHub PAT)

The plaintext secret lives in a file in `$HOME` (typically `~/.zshrc.local`). The repo only ever holds the encrypted blob.

```bash
# 1. Edit the plaintext file in $HOME.
$EDITOR ~/.zshrc.local

# 2. Re-encrypt and update the source state.
chezmoi add --encrypt ~/.zshrc.local

# 3. Confirm only the encrypted blob changed.
chezmoi diff
git -C ~/.local/share/chezmoi status

# 4. Confirm no plaintext landed in git.
git -C ~/.local/share/chezmoi diff --stat

# 5. Commit.
chezmoi cd
git add encrypted_private_dot_zshrc.local.age
git commit -m "chore(secrets): rotate AWS key"
```

If `git diff --stat` shows any non-`.age` file containing a credential, **stop**. Run `git restore --staged <file>` and figure out where the plaintext came from before continuing.

## Rotate the age key itself

This is a much bigger operation. The age key decrypts every `.age` file in the repo, so rotating it requires re-encrypting all of them.

### 1. Generate a new key on a trusted machine

```bash
age-keygen -o ~/.config/chezmoi/key.txt.new
```

Note the new public recipient (it's printed to stdout, also commented at the top of the new key file).

### 2. Decrypt every existing blob with the **old** key

```bash
chezmoi cd
for f in $(find . -name '*.age'); do
    age -d -i ~/.config/chezmoi/key.txt "$f" > "${f%.age}.plain"
done
```

### 3. Update `.chezmoi.toml.tmpl` with the new recipient

Replace the `recipient = "age1..."` line with the new public key.

### 4. Re-encrypt every blob with the **new** key

```bash
new_recipient="age1...your-new-recipient..."
for f in $(find . -name '*.age'); do
    plain="${f%.age}.plain"
    age -r "$new_recipient" -o "$f" "$plain"
    rm -f "$plain"
done
```

### 5. Swap keys and verify

```bash
mv ~/.config/chezmoi/key.txt ~/.config/chezmoi/key.txt.old
mv ~/.config/chezmoi/key.txt.new ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
chezmoi diff   # should be silent — re-encrypted blobs decrypt to the same plaintext
chezmoi verify
```

### 6. Distribute the new key

Transfer `~/.config/chezmoi/key.txt` to every machine that needs it (AirDrop, USB, password manager). See [Back up the age key](#back-up-the-age-key) below for the canonical backup procedure.

After every machine has the new key, delete the old one: `rm ~/.config/chezmoi/key.txt.old`. On macOS APFS, plain `rm` is genuinely unrecoverable — TRIM on the SSD does what `shred` used to do on spinning disks. Also delete any copies of the old key from your password manager / backups.

### 7. Commit

```bash
git add .chezmoi.toml.tmpl encrypted_private_dot_zshrc.local.age dot_aws/encrypted_private_config.age
git commit -m "chore(secrets): rotate age recipient key"
```

The old recipient is now public history — that's fine. Only the new private key matters for decryption.

## Back up the age key

The age private key at `~/.config/chezmoi/key.txt` is a one-of-one failure mode: if it's only on this Mac and the disk dies, you lose decryption access to every `*.age` blob in the repo. The underlying secrets (AWS keys, PATs) are mostly *re-issuable* upstream, but bootstrap day is annoying. Back the key up after first-time generation, and again after every rotation.

### What to back up

The complete contents of `~/.config/chezmoi/key.txt` — all three lines (`# created: …`, `# public key: …`, `AGE-SECRET-KEY-1…`). Save the public recipient string alongside (it's the `# public key:` line and matches what's in `.chezmoi.toml.tmpl`). The recipient is public-by-design but having it next to the private key makes recovery verification cheap.

### Strategies (pick one — multiple is better)

1. **Password manager (recommended)** — 1Password / Dashlane / Bitwarden / iCloud Keychain all support free-form secure notes. Create one titled `chezmoi age private key (Mac primary)`, paste in the file contents, tag it `infrastructure`. Trust boundary: your password-manager master credential.
2. **Passphrase-encrypted blob in any cloud** — `age -p ~/.config/chezmoi/key.txt > ~/iCloud\ Drive/chezmoi-key.txt.age` prompts for a passphrase; the resulting blob is decryptable only with that passphrase, so the cloud provider sees only ciphertext. Two-factor: cloud account + passphrase. Higher friction than a password manager; smaller single-point-of-failure surface.
3. **Hardware USB stored physically** — copy `key.txt` to an encrypted USB stick (e.g. APFS-encrypted), put it somewhere durable. No online dependency. Friction: needs physical access on recovery.
4. **Paper print** — the key file is under 200 bytes; one printed page in a fireproof safe is a real, audit-friendly fallback. Combines well with a hardware token guarding the password manager.

### Recovery on a new (or wiped) Mac

```bash
mkdir -p ~/.config/chezmoi
chmod 700 ~/.config/chezmoi
$EDITOR ~/.config/chezmoi/key.txt          # paste contents from your backup
chmod 600 ~/.config/chezmoi/key.txt

# Sanity check: derive the public key from the file and compare to the
# recipient in .chezmoi.toml.tmpl. They must match.
age-keygen -y ~/.config/chezmoi/key.txt

# Bootstrap chezmoi against the public repo and apply.
chezmoi init --apply edjchapman/dotfiles
```

If `age-keygen -y` outputs a recipient that doesn't match the one in `.chezmoi.toml.tmpl`, you've restored an old key from before the last rotation. Pull the current key from backup instead — chezmoi will report `age: no identity matched any of the recipients` if you proceed with a mismatched key.

### What NOT to back up the key to

- The dotfiles git repo itself (in any form, encrypted or not) — circular dependency: you'd need the key to decrypt the key.
- Any sync target that also mirrors `~/.config/chezmoi/` to a shared cloud account someone else can access (e.g. a family iCloud, a work Google Drive that admins can subpoena).
- A non-encrypted USB stick.
- Email or chat with cleartext attachments.

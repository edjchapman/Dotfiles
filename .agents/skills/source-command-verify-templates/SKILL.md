---
name: "source-command-verify-templates"
description: "Validate that every chezmoi `.tmpl` in this repo renders for all machine_type × arch combos."
---

# source-command-verify-templates

Use this skill when the user asks to run the migrated source command `verify-templates`.

## Command Template

Run `make verify-templates`. If the user passed file paths as arguments, scope the validation to just those files instead.

If anything fails, hand the failure list to the `chezmoi-template-validator` subagent for a structured matrix report. Otherwise, confirm "all templates render cleanly across personal/work × arm64/amd64".

Do not modify any files. Do not run `chezmoi apply`.

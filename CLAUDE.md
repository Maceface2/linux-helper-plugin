# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **plugin marketplace** containing one plugin, `nobara-linux-helper`,
that specializes Claude Code as a Linux assistant for this specific machine
(Nobara Linux 43 / KDE Wayland / dual-GPU / btrfs). See `README.md` for the
user-facing description and install steps.

There is no application to build or compile — the "code" is plugin component
files (JSON manifests, Markdown skills/commands, and bash scripts).

## Layout

```
.claude-plugin/marketplace.json              marketplace catalog
plugins/nobara-linux-helper/
  .claude-plugin/plugin.json                 plugin manifest
  skills/<name>/SKILL.md                     model-invokable skills
  commands/<name>.md                         user-triggered slash commands
  hooks/hooks.json                           PreToolUse guardrail declaration
  scripts/pretooluse-guard.sh                guardrail: classifies Bash commands
  scripts/snapshot.sh                        Timeshift wrapper (create / list)
  output-styles/linux-learning.md            teaching output style
  reference/                                 machine facts + permission allowlist
```

## Architecture

**The guardrail is the core of the design.** `hooks/hooks.json` registers a
`PreToolUse` hook on the `Bash` tool that runs `scripts/pretooluse-guard.sh`.
That script reads the hook event JSON from stdin, extracts
`.tool_input.command`, and classifies it in this priority order:

1. **Windows/NTFS write** → `deny` (hard stop — the machine dual-boots Windows).
2. **System-modifying** (package install/remove, `systemctl enable/start`,
   `/etc` writes, driver/kernel changes) → invoke `scripts/snapshot.sh` to
   create a Timeshift snapshot, then `ask`.
3. **Read-only diagnostic** (anchored prefix match, no command chaining) →
   `allow`.
4. **Other `sudo`** → `ask`.
5. **Everything else** → silent (exit 0); normal permission flow applies.

The guard **fails open**: any internal error (no `jq`, parse failure, snapshot
failure) ends without a blocking decision, so Claude Code's normal prompt still
applies. It must never fail closed and wedge the machine.

`snapshot.sh` wraps Timeshift (`timeshift --create` / `--list`). It honors
`SNAPSHOT_NONINTERACTIVE=1` (set by the guard) to use `sudo -n`, so a missing
sudoers rule fails fast instead of hanging on a password prompt.

Snapshots cover `/` only — the btrfs `@` subvolume. `/home` (`@home`) is
intentionally not snapshotted.

**Skills vs commands:** `skills/` are model-invokable (Claude loads them by
their `description`); `commands/` are user-triggered (`disable-model-invocation:
true`). Both end up namespaced `nobara-linux-helper:<name>`. Skills carry an
`allowed-tools` list limited to read-only diagnostics — that is how the plugin
pre-approves commands, since a plugin's `settings.json` cannot ship a
`permissions` allowlist.

Machine facts live in `reference/nobara-system.md` (skills also carry a compact
inline "Machine context" so they do not depend on path resolution).

## Conventions for editing this plugin

- **The guard's classification regexes are safety-critical.** When editing
  `pretooluse-guard.sh`: over-matching "system-modifying" only costs an extra
  snapshot + prompt (safe); under-matching the read-only allowlist only costs a
  prompt (safe); but wrongly putting something in the read-only `allow` bucket
  runs it unprompted (unsafe). Keep the `allow` path strict and anchored.
- After changing classification logic, re-run the test harness pattern: feed
  `{"tool_name":"Bash","tool_input":{"command":"..."}}` to the script and check
  the `permissionDecision`.
- Scripts must `set -euo pipefail` (or `-uo` for the guard, which must not abort
  on a failed match), quote all paths, and never touch `/dev/sda*` or
  `nvme0n1p5`.
- Bump `version` in `plugin.json` for changes to take effect via the
  marketplace, or use `claude --plugin-dir` during development to bypass it.

## Validate / test

```bash
# Validate the plugin manifest and components
claude plugin validate plugins/nobara-linux-helper --strict

# Iterate without reinstalling (then /reload-plugins after edits)
claude --plugin-dir plugins/nobara-linux-helper

# Smoke-test the guardrail classifier directly
printf '{"tool_name":"Bash","tool_input":{"command":"sudo dnf install htop"}}' \
  | plugins/nobara-linux-helper/scripts/pretooluse-guard.sh
```

Scripts must be executable: `chmod +x plugins/nobara-linux-helper/scripts/*.sh`.

## Machine context

The target machine: Nobara Linux 43 (Fedora 43 derivative), KDE Plasma /
Wayland, Ryzen 7 9800X3D, 32 GB RAM, dual GPU (NVIDIA RTX 4070 primary + AMD
integrated), btrfs root (`@`) and home (`@home`) on `nvme0n1p3`, dual-boots
Windows on NTFS disks that must never be written to. Full details:
`plugins/nobara-linux-helper/reference/nobara-system.md`.

# claude-linux-agent

A personal Claude Code plugin that turns Claude Code into a **Linux-specialized
assistant** for this machine — a Nobara Linux 43 / KDE Wayland desktop. It helps
you learn, use, and configure the system, with a safety guardrail that snapshots
before any system-modifying change.

This repo is a **plugin marketplace** containing one plugin:
`nobara-linux-helper`.

## What it gives you

**Skills** (Claude loads these automatically when relevant)
- `system-health` — diagnose failed services, slow boot, disk/memory pressure
- `package-manager` — safe dnf5 / Flatpak install, remove, update
- `gpu-display-doctor` — dual-GPU / NVIDIA / Wayland troubleshooting
- `snapshots` — Timeshift snapshot and rollback knowledge
- `nobara-research` — wiki-first lookup for Nobara-specific procedures

**Slash commands** (you trigger these)
- `/diagnose [area]` — full read-only health sweep
- `/explain-cmd <command>` — explain a command and flag its risks; never runs it
- `/snapshot [label]` — create a Timeshift snapshot now
- `/list-snapshots` — list snapshots and disk usage
- `/rollback <name>` — guided restore (explains, never auto-runs)
- `/nobara <topic>` — Nobara-correct, wiki-first answer

**Guardrail hook** — before any system-modifying Bash command (package
install/removal, `systemctl enable/start`, edits under `/etc`, driver/kernel
changes), a `PreToolUse` hook creates a **Timeshift snapshot of `/`** and routes
the command to a confirmation prompt. Writes to the Windows/NTFS disks are
hard-denied.

**Learning mode** — an optional "Linux Learning" output style that explains
concepts while it works.

## Install

From any directory, start Claude Code and run:

```
/plugin marketplace add /home/masono/Documents/claude-linux-agent
/plugin install nobara-linux-helper@mason-linux-tools
```

This enables the plugin in your user settings, so it is available from **every**
directory.

### Develop / iterate without reinstalling

```bash
claude --plugin-dir /home/masono/Documents/claude-linux-agent/plugins/nobara-linux-helper
```

Run `/reload-plugins` after editing plugin files.

## One-time pre-flight (do this once, with eyes open)

The guardrail snapshots with Timeshift, which needs root. A hook cannot answer a
password prompt, so the snapshot either runs via a scoped `sudo` rule or fails
gracefully and just asks you to snapshot manually.

1. **Confirm Timeshift is in BTRFS mode** (Nobara's default). Check
   `/etc/timeshift/timeshift.json` has `"btrfs_mode" : "true"`, or run
   `sudo timeshift --list` — it should not complain about rsync setup.

2. **Install the scoped sudoers rule** so the guardrail can snapshot silently.
   Run `/explain-cmd` on this first if you want it broken down. It is installed
   safely — validated in a temp file before activation:

   ```bash
   TMP=$(mktemp)
   echo 'masono ALL=(root) NOPASSWD: /usr/bin/timeshift --create *, /usr/bin/timeshift --list' > "$TMP"
   sudo visudo -cf "$TMP" && sudo install -m 0440 -o root -g root "$TMP" /etc/sudoers.d/claude-snapshots
   rm -f "$TMP"
   ```

   This grants passwordless `sudo` for **only** `timeshift --create` and
   `timeshift --list` — nothing else. Skip this step if you would rather type
   your password each time; the guardrail then asks Claude to run the snapshot
   as a visible command instead.

3. **(Optional) Add the read-only permission allowlist** so diagnostics never
   prompt anywhere. The block is in
   `plugins/nobara-linux-helper/reference/allowlist.md`; add it with the
   `/permissions` command.

## Turn on Learning mode (optional)

`/config` → Output style → **Linux Learning**. It explains concepts as it works.
The change takes effect in a new session or after `/clear`.

## How the guardrail decides

| Command kind | What happens |
|---|---|
| Read-only diagnostics (`systemctl status`, `journalctl`, `nvidia-smi`, `dnf list`, …) | Allowed, no prompt |
| System-modifying (`dnf install`, `systemctl enable`, `/etc` writes, driver/kernel changes) | Timeshift snapshot created, then you confirm |
| Writes to the Windows/NTFS disks (`/dev/sda`, `nvme0n1p5`) | Hard-denied |
| Other `sudo` use | You confirm before it runs |
| Everything else | Normal Claude Code permission flow |

The guardrail **fails open**: if a snapshot can't be taken it still asks you to
confirm (with a warning) rather than blocking the machine.

## Layout

```
.claude-plugin/marketplace.json        marketplace catalog
plugins/nobara-linux-helper/
  .claude-plugin/plugin.json           plugin manifest
  skills/                              5 model-invokable skills
  commands/                            6 slash commands
  hooks/hooks.json                     PreToolUse guardrail declaration
  scripts/pretooluse-guard.sh          command classifier + snapshot trigger
  scripts/snapshot.sh                  Timeshift wrapper
  output-styles/linux-learning.md      teaching output style
  reference/                           machine facts + permission allowlist
```

---
name: package-manager
description: Install, remove, update, or search software safely with dnf5 or Flatpak on this Nobara/Fedora machine. Use when the user wants to add or remove an application, run system updates, or troubleshoot package conflicts.
allowed-tools: Bash(dnf list:*), Bash(dnf info:*), Bash(dnf search:*), Bash(dnf repoquery:*), Bash(dnf provides:*), Bash(dnf grouplist:*), Bash(dnf history list:*), Bash(dnf history info:*), Bash(dnf check-update), Bash(flatpak list:*), Bash(flatpak info:*), Bash(flatpak search:*), Bash(flatpak remotes:*), Read
---

# Safe package management

Manage software on this Nobara Linux 43 machine with `dnf` (dnf5, v5.2) and
Flatpak. The read-only query commands above run freely. The actual
install/remove/update commands are **system-modifying**: when you run one, the
guardrail hook creates a Timeshift snapshot first and asks the user to confirm.

## Machine context
- Nobara 43 = Fedora 43 derivative. It has its own update tooling and may swap
  some stock packages — when a package or repo looks distro-specific, confirm
  with the `nobara-research` skill before acting.
- Prefer `dnf` for system packages; prefer **Flatpak for sandboxed desktop
  apps**.
- Full machine reference: `reference/nobara-system.md` in this plugin.

## Before any install / remove / update

1. **Investigate first** with read-only queries: `dnf info <pkg>`,
   `dnf search <term>`, `dnf repoquery --requires`/`--whatrequires`,
   `dnf provides <file>`.
2. **State the exact command** you will run and what it changes — which
   packages are added/removed, approximate download size, whether it pulls in
   a new repo.
3. **State the rollback path** before running it:
   - `dnf history list` shows transactions; `sudo dnf history undo <id>`
     reverses a single one — a targeted alternative to a full snapshot.
   - The guardrail's Timeshift snapshot is the broader safety net.
4. Run the command. The hook snapshots and prompts; let the user confirm.
5. **Verify afterward** — confirm the package is present/absent and, for
   updates, mention whether a reboot is advisable (kernel, driver, or
   systemd updates).

## Guidance
- For system updates, present `dnf check-update` output first so the user sees
  what will change. On Nobara, also mention its own updater (`nobara-sync` /
  Nobara Package Manager) via `nobara-research` if a full system update is the
  goal — it sequences Nobara-specific steps a bare `dnf upgrade` skips.
- Never combine unrelated changes into one transaction — keep installs and
  removals separate so `dnf history undo` stays surgical.
- Do not enable third-party repos or COPRs without explaining the trust
  implications first.

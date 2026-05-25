---
name: snapshots
description: Manage Timeshift snapshots and rollbacks on this btrfs machine. Use when the user wants to snapshot the system, list snapshots, restore after a bad change, or understand btrfs subvolumes and rollback.
allowed-tools: Bash(sudo timeshift --list), Bash(findmnt:*), Bash(btrfs filesystem usage:*), Bash(btrfs filesystem df:*), Read
---

# Snapshots & rollback

This machine uses **Timeshift** (btrfs mode) for system snapshots.

## Machine context
- `/` is btrfs subvolume `@`; `/home` is `@home`; both on `nvme0n1p3`.
- Timeshift snapshots cover **`/` only** — `@home` is excluded by design.
  User-data recovery is done per-file, not by swapping `@home`.
- A btrfs root rollback is a **subvolume swap plus a reboot** — it is not a
  live operation.

## Creating & listing
- Create now: run `"${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh" create <reason>`.
- List: run `"${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh" list`
  (or `sudo timeshift --list`).
- The guardrail hook also creates a snapshot automatically before any
  system-modifying command, tagged with the command it is protecting.
- Check space with `btrfs filesystem usage /`. Timeshift prunes on its own
  retention schedule (configured in `/etc/timeshift/timeshift.json`).

## Rollback — explain, never perform automatically
Restoring a snapshot is a serious operation. **Never run the restore for the
user.** Instead:
1. Confirm which snapshot, by name, from `timeshift --list`.
2. Explain that `sudo timeshift --restore --snapshot '<name>'` swaps the root
   subvolume and then reboots; it is safest run when little else is happening,
   and a recovery/live environment is the safest place if the system won't boot.
3. Print the exact command and stop. Let the user run it themselves.
4. For `/home` problems, recommend restoring individual files from a backup
   rather than any subvolume swap — Timeshift here does not cover `@home`.

## Second safety net
For package changes specifically, `dnf history undo <id>` reverses a single
transaction without a full rollback — mention it where relevant.

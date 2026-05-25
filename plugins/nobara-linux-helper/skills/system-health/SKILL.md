---
name: system-health
description: Diagnose Linux system health on this Nobara machine — failed services, slow boot, disk/memory pressure, journal errors, btrfs space. Use when the user reports the system is slow, something broke, a service won't start, or asks for a general health check.
allowed-tools: Bash(systemctl status:*), Bash(systemctl --failed), Bash(systemctl list-units:*), Bash(journalctl:*), Bash(systemd-analyze:*), Bash(free:*), Bash(df:*), Bash(lsblk:*), Bash(findmnt:*), Bash(uptime), Bash(btrfs filesystem usage:*), Bash(btrfs filesystem df:*), Read
---

# System health diagnosis

Diagnose the health of this Nobara Linux 43 / KDE Wayland desktop. This skill is
**read-only** — it inspects, it never fixes. Hand risky fixes to the
`package-manager` or `snapshots` skills, or show the user the command and let
them confirm.

## Machine context
- Nobara Linux 43 (Fedora 43 derivative), KDE Plasma / Wayland, bash.
- Ryzen 7 9800X3D, 32 GB RAM + ~16 GB swap (zram + swap partition).
- Root `/` is btrfs subvolume `@`, `/home` is `@home`, both on `nvme0n1p3`.
- Full machine reference: `reference/nobara-system.md` in this plugin.

## Diagnostic sweep

Run the relevant checks below (skip ones not relevant to the reported symptom):

1. **Failed units** — `systemctl --failed`
2. **Boot time** — `systemd-analyze` then `systemd-analyze blame` and
   `systemd-analyze critical-chain` for slow boots.
3. **Recent errors** — `journalctl -p err -b --no-pager` (this boot's errors).
   For a crash, also `journalctl -p err -b -1 --no-pager` (previous boot).
4. **Memory / swap** — `free -h`. Note zram vs swap-partition usage.
5. **Disk space** — `df -h` for mounted filesystems, then
   `btrfs filesystem usage /` (btrfs free space is NOT what `df` shows —
   metadata exhaustion can fill a "non-full" disk).
6. **Mounts** — `findmnt` if a mount or subvolume issue is suspected.
7. **Load** — `uptime` for load average.

## Reporting

Present findings **ordered by severity** (critical → warning → informational).
For each: what you observed, what it means, and a suggested next step. Do not
run fixes. If a fix needs a package change or a snapshot, name the skill or
command that handles it (`package-manager`, `/snapshot`).

When something is Nobara-specific (custom kernel, gaming/multimedia packages),
say so and suggest the `nobara-research` skill to confirm the right procedure.

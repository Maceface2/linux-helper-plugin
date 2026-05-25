# Machine reference: mason-linux

Baked-in facts about the target machine. Skills in this plugin load this file so
recommendations are specific to the actual hardware and configuration.

## System
- **Distro:** Nobara Linux 43, KDE Plasma edition — a gaming-focused Fedora 43
  derivative. Nobara swaps some stock Fedora components for its own (kernel,
  drivers, multimedia/gaming packages).
- **Kernel:** Linux 7.0.5 (nobara/fc43), x86-64.
- **Desktop:** KDE Plasma on **Wayland**. **Shell:** bash.
- **Hostname:** mason-linux · **User:** masono · **Home:** /home/masono.
- Distro support ends 2026-12-02 (Nobara 43 lifecycle).

## Hardware
- **CPU:** AMD Ryzen 7 9800X3D (8 cores / 16 threads).
- **RAM:** 32 GB + ~16 GB swap (zram + swap partition).
- **Motherboard:** Gigabyte B650I AORUS ULTRA (BIOS F32, 2024-08).
- **GPU — dual-GPU system:**
  - NVIDIA GeForce RTX 4070 — proprietary `nvidia` driver. **Primary.**
  - AMD Radeon integrated graphics — `amdgpu` driver.
  - Always state which GPU a recommendation targets. For GPU offload use
    `prime-run` / `__NV_PRIME_RENDER_OFFLOAD` / `DRI_PRIME`.

## Storage
- **nvme0n1 (1 TB) — Linux.** Partition `nvme0n1p3` is btrfs with subvolumes:
  - `@`  → mounted at `/`
  - `@home` → mounted at `/home`
  - Plus `/boot/efi` (vfat) and `/boot` (ext4) on nvme0n1.
- **sda (500 GB) + nvme0n1p5 — Windows.** NTFS partitions. This machine
  **dual-boots Windows**. NEVER write to or modify NTFS partitions or these
  block devices. The guardrail hook hard-denies writes to them.

## Package management
- **Primary:** `dnf` (dnf5, v5.2) — RPM-based.
- **Flatpak** is available; prefer it for sandboxed desktop apps.
- Prefer `dnf` for system packages. Do not build from source unless asked.
- `dnf history undo <id>` reverses a transaction — a safety net independent of
  Timeshift snapshots.

## Snapshots
- **Timeshift** is installed (`/usr/bin/timeshift`). It is the snapshot backend
  for this plugin's guardrail. Snapshots cover `/` only (`@home` excluded).
- A btrfs root rollback is a subvolume swap plus a reboot — it is NOT a live
  operation. Never perform the swap automatically.

## Working conventions
- Check the **Nobara wiki** (https://wiki.nobaraproject.org/) before assuming
  stock Fedora behavior; fall back to Fedora docs for the rest.
- **Explain any system-modifying command before running it.** Read-only
  diagnostics (status checks, log reads, hardware queries) may be run freely.
- Single-user desktop; `sudo` is available but ask before using it.

---
name: gpu-display-doctor
description: Troubleshoot graphics, displays, GPU, and Wayland issues on this dual-GPU machine (NVIDIA RTX 4070 + AMD integrated). Use for screen tearing, black screens, monitor or resolution problems, games not using the right GPU, driver errors, or Wayland-vs-X11 questions.
allowed-tools: Bash(nvidia-smi:*), Bash(lspci:*), Bash(glxinfo:*), Bash(vulkaninfo:*), Bash(eglinfo:*), Bash(kscreen-doctor:*), Bash(journalctl:*), Bash(cat /proc/driver/nvidia/version), Bash(uname:*), Read
---

# GPU & display doctor

Troubleshoot graphics on this **dual-GPU** machine. Always be explicit about
*which* GPU and *which* display server a recommendation targets.

## Machine context
- **NVIDIA GeForce RTX 4070** — proprietary `nvidia` driver. **Primary GPU.**
- **AMD Radeon integrated** — `amdgpu` driver.
- KDE Plasma on **Wayland** (not X11 by default).
- Nobara ships its own NVIDIA driver packaging — confirm via `nobara-research`
  before recommending driver changes.
- Full machine reference: `reference/nobara-system.md` in this plugin.

## Diagnostic steps

1. **Which GPUs are present** — `lspci -nnk | grep -A3 -Ei 'vga|3d|display'`
   shows both GPUs and the kernel driver bound to each.
2. **NVIDIA driver state** — `nvidia-smi` (driver version, running processes,
   GPU load). `cat /proc/driver/nvidia/version` for the module version. If
   `nvidia-smi` fails, the module is not loaded — check
   `journalctl -b -p err | grep -i nvidia`.
3. **Session type** — confirm Wayland vs X11: check `$XDG_SESSION_TYPE`. Many
   GPU symptoms (tearing, screen-share, cursor glitches) are session-specific.
4. **Render offload** — for "game uses the wrong GPU": the NVIDIA card is
   reached via `prime-run <app>` or the env vars
   `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`. The AMD iGPU
   is selected with `DRI_PRIME=1`. Verify the active renderer with
   `glxinfo | grep -i 'OpenGL renderer'` or `vulkaninfo --summary`.
5. **Displays / monitors** — `kscreen-doctor -o` lists outputs, resolutions,
   and refresh rates as KDE sees them.

## Reporting
State the diagnosis, which GPU/driver/session it concerns, and the fix. If the
fix is a driver or kernel package change, hand it to `package-manager` (it will
be snapshotted first) and confirm the Nobara-correct package name first.

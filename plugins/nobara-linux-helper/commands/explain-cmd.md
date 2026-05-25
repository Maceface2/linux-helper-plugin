---
description: Explain what a shell command does, line by line, and flag its risks
argument-hint: <command to explain>
disable-model-invocation: true
---

Explain the shell command below in plain language. **Do NOT execute it.**

Command:
```
$ARGUMENTS
```

Cover:
- What each part / pipeline stage does.
- Which files, services, packages, or devices it touches.
- Whether it needs `sudo` and whether it modifies the system.
- What could go wrong on this specific machine — Nobara 43, KDE/Wayland, btrfs
  subvolumes (`@`, `@home`), dual GPU, and a dual-boot Windows install on NTFS
  partitions that must never be written to.

End with a one-line verdict: **safe to run** / **run with care** / **do not run**,
with the single most important reason.

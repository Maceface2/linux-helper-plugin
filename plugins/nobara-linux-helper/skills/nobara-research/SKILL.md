---
name: nobara-research
description: Look up the Nobara-correct procedure before acting. Use when behavior may differ from stock Fedora — Nobara's custom kernel, drivers, multimedia or gaming packages — or whenever unsure of the right command for this distro.
allowed-tools: WebFetch, WebSearch, Read
---

# Nobara-aware research

Nobara Linux 43 is a gaming-focused Fedora 43 derivative. It **replaces** some
stock Fedora components — kernel, GPU drivers, multimedia/gaming stack, and its
own update tooling (Nobara Package Manager / `nobara-sync`). Stock Fedora
instructions are sometimes wrong here.

## Procedure

1. **Check the Nobara wiki first** — https://wiki.nobaraproject.org/ . Fetch the
   relevant page and prefer its guidance for anything touching kernel, drivers,
   gaming, multimedia codecs, or system updates.
2. **Fall back to Fedora 43 docs** for everything Nobara does not override
   (https://docs.fedoraproject.org/).
3. **Flag the difference.** When Nobara's recommended approach differs from
   stock Fedora, say so explicitly and explain why.
4. Prefer `dnf` for system packages and Flatpak for sandboxed desktop apps.
   Do not recommend building from source unless the user asks.

## Output
Give the Nobara-correct answer, cite the page you used, and call out any step
that is distro-specific. If the task is system-modifying, explain it before it
runs — the guardrail hook will snapshot it.

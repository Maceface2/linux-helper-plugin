---
description: Run a full read-only system health diagnosis of this Nobara machine
argument-hint: [area: boot | disk | memory | services | gpu]
disable-model-invocation: true
---

Run a complete **read-only** health check of this Nobara Linux 43 machine using
the `system-health` skill (use `gpu-display-doctor` instead if the area is
`gpu`).

If `$ARGUMENTS` names an area, focus the diagnosis there. Otherwise sweep
everything: failed services, boot time, journal errors, memory/swap, disk and
btrfs space.

Report findings ordered by severity. Do not apply any fix — for each issue,
explain what it means and name the command or skill that would address it.

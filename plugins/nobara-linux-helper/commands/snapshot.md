---
description: Create a Timeshift snapshot of the system right now
argument-hint: [label for the snapshot]
disable-model-invocation: true
---

Create a Timeshift snapshot now using the `snapshots` skill.

Run: `"${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh" create $ARGUMENTS`
(if `$ARGUMENTS` is empty, the snapshot is labelled `manual`).

This needs root — it relies on the scoped sudoers rule, or will prompt for a
password in the terminal. After it completes, confirm the new snapshot by
running `"${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh" list` and report disk usage
with `btrfs filesystem usage /`.

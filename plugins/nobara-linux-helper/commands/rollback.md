---
description: Guided restore from a Timeshift snapshot (explains, never auto-runs)
argument-hint: <snapshot name>
disable-model-invocation: true
---

Guide the user through restoring this snapshot using the `snapshots` skill:

$ARGUMENTS

This is a serious operation. **Do NOT run the restore yourself.**

1. Run `"${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh" list` and confirm the
   snapshot name exists. If `$ARGUMENTS` is empty or ambiguous, show the list
   and ask which one.
2. Explain that `sudo timeshift --restore --snapshot '<name>'` swaps the root
   (`@`) subvolume and reboots; `/home` (`@home`) is not covered.
3. Print the exact command for the user to run themselves, and note it is
   safest from a recovery/live environment if the system will not boot.
4. Stop there — let the user execute the restore.

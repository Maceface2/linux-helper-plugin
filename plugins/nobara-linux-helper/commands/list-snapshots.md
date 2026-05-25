---
description: List existing Timeshift snapshots and current btrfs disk usage
disable-model-invocation: true
---

List the system's Timeshift snapshots using the `snapshots` skill.

Run `"${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh" list` and present the result as
a readable table: snapshot name, date, tags, and comments. Snapshots whose
comment starts with `claude:` were created by this plugin's guardrail or the
`/snapshot` command.

Then run `btrfs filesystem usage /` and note total snapshot space. If space is
getting tight, mention Timeshift's retention settings in
`/etc/timeshift/timeshift.json`.

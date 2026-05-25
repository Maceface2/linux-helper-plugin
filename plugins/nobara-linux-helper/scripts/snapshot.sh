#!/usr/bin/env bash
#
# snapshot.sh — Timeshift wrapper for the nobara-linux-helper plugin.
#
# Timeshift is the snapshot backend on this machine. Snapshots cover / only
# (the @ subvolume); /home (@home) is intentionally excluded.
#
# Usage:
#   snapshot.sh create [reason...]   Create an on-demand snapshot now.
#   snapshot.sh list                 List existing snapshots.
#
# Both subcommands need root. The guardrail hook relies on a scoped
# /etc/sudoers.d/claude-snapshots NOPASSWD rule so 'create' can run
# non-interactively; without that rule sudo will prompt in the terminal.
#
# Set SNAPSHOT_NONINTERACTIVE=1 to use 'sudo -n' (no password prompt) — the
# guardrail hook sets this so a missing sudoers rule fails fast instead of
# blocking on a password prompt the hook cannot answer.

set -euo pipefail

TIMESHIFT="/usr/bin/timeshift"

sudo_cmd=(sudo)
[ "${SNAPSHOT_NONINTERACTIVE:-0}" = "1" ] && sudo_cmd=(sudo -n)

die() { printf 'snapshot.sh: %s\n' "$1" >&2; exit 1; }

[ -x "$TIMESHIFT" ] || die "Timeshift not found at $TIMESHIFT"

action="${1:-}"

case "$action" in
  create)
    shift || true
    reason="${*:-manual}"
    # Strip newlines/quotes from the reason so it is safe as a --comments value.
    reason="$(printf '%s' "$reason" | tr -d '\n\r"' | cut -c1-200)"
    "${sudo_cmd[@]}" "$TIMESHIFT" --create \
      --comments "claude: ${reason}" \
      --tags O \
      --scripted
    ;;
  list)
    "${sudo_cmd[@]}" "$TIMESHIFT" --list
    ;;
  *)
    die "usage: snapshot.sh {create [reason] | list}"
    ;;
esac

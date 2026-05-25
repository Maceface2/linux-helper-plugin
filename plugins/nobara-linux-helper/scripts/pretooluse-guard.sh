#!/usr/bin/env bash
#
# pretooluse-guard.sh — PreToolUse guardrail for Bash commands.
#
# Reads the hook event JSON on stdin, classifies the proposed command, and:
#   1. DENIES writes to the Windows/NTFS disks (hard stop).
#   2. For system-modifying commands: creates a Timeshift snapshot, then ASKs.
#   3. ALLOWS read-only diagnostics outright (no prompt).
#   4. ASKs for any other use of sudo (elevated, but not classified above).
#   5. Stays silent for everything else (normal permission flow applies).
#
# Design principle: FAIL OPEN. Any internal error ends with no decision, so
# Claude Code's normal permission prompt still protects the user. The guard
# never fails closed (it will not wedge the machine).
#
# Output contract (PreToolUse): a single JSON object on stdout —
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#    "permissionDecision":"allow|deny|ask","permissionDecisionReason":"..."}}
# Emitting nothing (exit 0) lets the normal flow proceed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"

# --- helpers --------------------------------------------------------------

# Emit a decision as JSON and exit. $1=allow|deny|ask  $2=reason
emit() {
  local reason="$2"
  # Escape backslashes and double-quotes for safe embedding in JSON.
  reason="${reason//\\/\\\\}"
  reason="${reason//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' \
    "$1" "$reason"
  exit 0
}

# --- read the event -------------------------------------------------------

input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0   # cannot parse safely -> fail open

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

# --- 1. Windows / NTFS protection (hard deny) -----------------------------
# This machine dual-boots Windows. Never write to /dev/sda* or nvme0n1p5,
# and never reformat/repartition those disks.

ntfs_destructive='(mkfs|wipefs|fdisk|sfdisk|parted|cfdisk|cryptsetup|shred|badblocks[[:space:]]+-[a-zA-Z]*w)[^|]*/dev/(sda|nvme0n1p5)'
ntfs_ddwrite='dd[^|]*of=[[:space:]]*/dev/(sda|nvme0n1p5)'
ntfs_mountrw='mount[^|]*-o[^|]*\b(rw)\b[^|]*/dev/(sda|nvme0n1p5)'

if [[ $cmd =~ $ntfs_destructive ]] || [[ $cmd =~ $ntfs_ddwrite ]] || [[ $cmd =~ $ntfs_mountrw ]]; then
  emit deny "Blocked: this command would write to or reformat a Windows/NTFS disk (/dev/sda or nvme0n1p5). This machine dual-boots Windows and those disks are off-limits."
fi

# --- 2. System-modifying commands (snapshot, then ask) --------------------
# Broad on purpose: a false positive only costs an extra snapshot + prompt.

sysmod_re='(\bdnf[[:space:]]+(install|remove|erase|update|upgrade|downgrade|reinstall|distro-sync|autoremove|mark|module|group|history[[:space:]]+(undo|redo|rollback)|config-manager|copr|swap)\b'
sysmod_re+='|\brpm[[:space:]]+-[a-zA-Z]*[eiUF]'
sysmod_re+='|\bflatpak[[:space:]]+(install|uninstall|update|override|mask|remote-add|remote-delete|remote-modify)\b'
sysmod_re+='|\bsystemctl[[:space:]]+([a-z-]+[[:space:]]+)*(enable|disable|start|stop|restart|reload|mask|unmask|set-default|isolate|edit|revert)\b'
sysmod_re+='|\bsystemctl[[:space:]]+daemon-reload'
sysmod_re+='|\bjournalctl[^|]*--vacuum'
sysmod_re+='|>[[:space:]]*/etc/|>>[[:space:]]*/etc/'
sysmod_re+='|\btee[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*/etc/'
sysmod_re+='|\b(cp|mv|rm|ln|chmod|chown|chgrp|chattr|touch|mkdir|truncate|install)[^|]*[[:space:]]/etc/'
sysmod_re+='|\bsed[[:space:]]+-[a-zA-Z]*i[^|]*/etc/'
sysmod_re+='|\b(nano|vi|vim|nvim|emacs|kate|gedit|kwrite)[[:space:]]+[^|]*/etc/'
sysmod_re+='|\bdd[^|]*of=[[:space:]]*/etc/'
sysmod_re+='|\b(grub2-mkconfig|grub2-install|dracut|akmods|kernel-install|mokutil)\b'
sysmod_re+='|\b(useradd|userdel|usermod|groupadd|groupdel|gpasswd|chsh|visudo)\b'
sysmod_re+='|\b(update-crypto-policies|setsebool|semanage|authselect)\b'
sysmod_re+='|\bfirewall-cmd[[:space:]]+--(add|remove|set|permanent)'
sysmod_re+='|\bnmcli[[:space:]]+(con|connection|dev|device|radio|networking)[[:space:]]+(add|delete|modify|edit|up|down|on|off)'
sysmod_re+='|\b(hostnamectl|timedatectl|localectl)[[:space:]]+set-'
sysmod_re+='|\bsudo[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(rm|mv|cp|dd|tee|chmod|chown|chgrp|chattr|truncate|mkfs|wipefs|ln|sed|mount|umount|swapon|swapoff|sysctl|modprobe|insmod|rmmod)\b'
sysmod_re+=')'

if [[ $cmd =~ $sysmod_re ]]; then
  # Build a short, human-readable snapshot reason from the command.
  reason="$(printf '%s' "$cmd" | tr '\n\r\t' '   ' | cut -c1-90)"
  snapshot_sh="${SCRIPT_DIR}/snapshot.sh"

  if [ -n "$SCRIPT_DIR" ] && [ -x "$snapshot_sh" ] \
     && SNAPSHOT_NONINTERACTIVE=1 "$snapshot_sh" create "guard: $reason" >/dev/null 2>&1; then
    emit ask "System-modifying command detected. A Timeshift snapshot of / was created first, so this change can be rolled back (see /list-snapshots). Review the command, then confirm."
  else
    emit ask "System-modifying command detected. WARNING: the automatic Timeshift snapshot FAILED — the scoped sudoers rule (/etc/sudoers.d/claude-snapshots) may not be installed, or Timeshift is not configured. Consider running /snapshot manually before you confirm."
  fi
fi

# --- 3. Read-only diagnostics (allow outright) ----------------------------
# Anchored at the start of the command (after an optional 'sudo'); only
# reached when steps 1-2 did not match. No command chaining (; && ||) is
# permitted here, so a safe prefix cannot smuggle in a second command.

if [[ ! $cmd =~ (\;|\&\&|\|\|) ]]; then
  readonly_re='^[[:space:]]*(sudo[[:space:]]+)?('
  readonly_re+='systemctl[[:space:]]+(status|--failed|list-units|list-unit-files|list-timers|list-sockets|is-active|is-enabled|is-failed|show|cat|get-default)'
  readonly_re+='|journalctl|systemd-analyze|dmesg'
  readonly_re+='|lsblk|findmnt|df|free|uptime|lscpu|lspci|lsusb|lsmod|uname|hostnamectl|timedatectl|localectl|id|whoami|date|env|printenv|getconf'
  readonly_re+='|nvidia-smi|glxinfo|vulkaninfo|eglinfo|kscreen-doctor|inxi|hwinfo'
  readonly_re+='|dnf[[:space:]]+(list|info|search|repoquery|provides|grouplist|groupinfo|check-update|history[[:space:]]+(list|info)|module[[:space:]]+list|updateinfo|leaves)'
  readonly_re+='|flatpak[[:space:]]+(list|info|search|remotes|remote-ls|history)'
  readonly_re+='|btrfs[[:space:]]+(subvolume[[:space:]]+(list|show)|filesystem[[:space:]]+(usage|df|show))'
  readonly_re+='|timeshift[[:space:]]+--list'
  readonly_re+='|ls|cat|grep|egrep|fgrep|head|tail|wc|stat|file|which|type|echo|pwd|true|tree|du|realpath|basename|dirname'
  readonly_re+=')([[:space:]]|$)'

  if [[ $cmd =~ $readonly_re ]]; then
    emit allow "Read-only diagnostic command — safe to run without a prompt."
  fi
fi

# --- 4. Other use of sudo (elevated; ask before running) ------------------

if [[ $cmd =~ (^|[[:space:];&|])sudo([[:space:]]|$) ]]; then
  emit ask "This command uses sudo (elevated privileges) and was not recognised as a routine read-only diagnostic. Review what it does before confirming."
fi

# --- 5. Everything else: stay silent, normal permission flow applies ------
exit 0

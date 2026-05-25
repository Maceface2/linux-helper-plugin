# Permission allowlist

A Claude Code **plugin cannot ship a `permissions` allowlist** — plugin
`settings.json` only honors `agent` and `subagentStatusLine`. So this plugin
pre-approves read-only diagnostics two ways:

1. **Per-skill `allowed-tools`** (automatic) — each skill in this plugin lists
   the read-only commands it needs. Those run without a prompt while the skill
   is active. No setup required; this travels with the plugin.

2. **User-wide allowlist** (optional, one-time) — if you want these read-only
   diagnostics approved *everywhere*, independent of any skill, add the block
   below to `~/.claude/settings.json`. Best done via the `/permissions` command
   so the syntax is validated rather than hand-editing.

Every entry below is genuinely **read-only**. Nothing here modifies the system.

```json
{
  "permissions": {
    "allow": [
      "Bash(systemctl status:*)",
      "Bash(systemctl --failed)",
      "Bash(systemctl list-units:*)",
      "Bash(systemctl list-unit-files:*)",
      "Bash(journalctl:*)",
      "Bash(systemd-analyze:*)",
      "Bash(lsblk:*)",
      "Bash(findmnt:*)",
      "Bash(df:*)",
      "Bash(free:*)",
      "Bash(uptime)",
      "Bash(lscpu)",
      "Bash(lspci:*)",
      "Bash(lsusb:*)",
      "Bash(uname:*)",
      "Bash(nvidia-smi:*)",
      "Bash(glxinfo:*)",
      "Bash(vulkaninfo:*)",
      "Bash(kscreen-doctor:*)",
      "Bash(dnf list:*)",
      "Bash(dnf info:*)",
      "Bash(dnf search:*)",
      "Bash(dnf repoquery:*)",
      "Bash(dnf history list:*)",
      "Bash(dnf check-update)",
      "Bash(flatpak list:*)",
      "Bash(flatpak info:*)",
      "Bash(flatpak search:*)",
      "Bash(btrfs subvolume list:*)",
      "Bash(btrfs filesystem usage:*)",
      "Bash(btrfs filesystem df:*)"
    ],
    "ask": [
      "Bash(sudo:*)"
    ]
  }
}
```

## Deliberately NOT allowlisted

These must keep prompting — and the guardrail hook snapshots them first:

- `sudo` (anything)
- `dnf install` / `remove` / `update` / `upgrade`
- `systemctl enable` / `disable` / `start` / `stop` / `restart`
- writes under `/etc`
- `flatpak install` / `uninstall` / `update`

`dnf check-update` exits non-zero when updates exist; it is still read-only and
safe to allow.

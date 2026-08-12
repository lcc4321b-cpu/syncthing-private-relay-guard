#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This installer only supports macOS.\n' >&2
  exit 1
fi

for command in install launchctl plutil; do
  command -v "$command" >/dev/null || {
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  }
done

if ! command -v syncthing >/dev/null; then
  printf 'Syncthing was not found. Install it with: brew install syncthing\n' >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LABEL="io.github.syncthing-private-relay-guard"
INSTALL_DIR="$HOME/Library/Application Support/Syncthing/guard"
LOG_DIR="$HOME/Library/Logs/Syncthing"
AGENT_DIR="$HOME/Library/LaunchAgents"
AGENT_PATH="$AGENT_DIR/$LABEL.plist"
INSTALLED_LAUNCHER="$INSTALL_DIR/start-syncthing.sh"

find_conflicting_agent() {
  local plist argument argument_name

  for plist in "$AGENT_DIR"/*.plist; do
    [[ -f "$plist" && "$plist" != "$AGENT_PATH" ]] || continue
    argument="$(/usr/libexec/PlistBuddy -c 'Print :Program' "$plist" 2>/dev/null || true)"
    argument_name="${argument##*/}"
    case "$argument_name" in
      syncthing|syncthing-macos|start-syncthing.sh)
        printf '%s\n' "$plist"
        return 0
        ;;
    esac

    while IFS= read -r argument; do
      argument="${argument#${argument%%[![:space:]]*}}"
      argument_name="${argument##*/}"
      case "$argument_name" in
        syncthing|syncthing-macos|start-syncthing.sh)
          printf '%s\n' "$plist"
          return 0
          ;;
      esac
    done < <(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments' "$plist" 2>/dev/null || true)
  done

  return 1
}

if conflicting_agent="$(find_conflicting_agent)"; then
  printf 'Another LaunchAgent already manages Syncthing: %s\n' "$conflicting_agent" >&2
  printf 'Keep the existing agent or unload it before installing this one.\n' >&2
  exit 1
fi

install -d -m 0755 "$INSTALL_DIR" "$LOG_DIR" "$AGENT_DIR"
install -m 0755 "$SCRIPT_DIR/start-syncthing.sh" "$INSTALLED_LAUNCHER"
install -m 0644 \
  "$SCRIPT_DIR/io.github.syncthing-private-relay-guard.plist" \
  "$AGENT_PATH"

plutil -replace ProgramArguments.1 -string "$INSTALLED_LAUNCHER" "$AGENT_PATH"
plutil -replace StandardOutPath -string "$LOG_DIR/guard.log" "$AGENT_PATH"
plutil -replace StandardErrorPath -string "$LOG_DIR/guard-error.log" "$AGENT_PATH"
plutil -lint "$AGENT_PATH" >/dev/null

domain="gui/$(id -u)"
launchctl bootout "$domain/$LABEL" 2>/dev/null || true
launchctl bootstrap "$domain" "$AGENT_PATH"
launchctl enable "$domain/$LABEL"
launchctl kickstart -k "$domain/$LABEL"

printf 'Syncthing macOS guard installed successfully.\n'
launchctl print "$domain/$LABEL" | sed -n -E \
  '/^[[:space:]]*(state|pid|last exit code|runs) =/p'

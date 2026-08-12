#!/bin/zsh
set -eu

syncthing_bin="${SYNCTHING_BIN:-}"

if [[ -z "$syncthing_bin" ]]; then
  for candidate in /opt/homebrew/bin/syncthing /usr/local/bin/syncthing; do
    if [[ -x "$candidate" ]]; then
      syncthing_bin="$candidate"
      break
    fi
  done
fi

if [[ -z "$syncthing_bin" || ! -x "$syncthing_bin" ]]; then
  print -u2 'Syncthing executable was not found in the Homebrew paths.'
  exit 127
fi

syncthing_home="${SYNCTHING_HOME:-$HOME/Library/Application Support/Syncthing}"

exec "$syncthing_bin" serve \
  --home "$syncthing_home" \
  --no-browser \
  --no-restart \
  --no-upgrade \
  --log-file=default

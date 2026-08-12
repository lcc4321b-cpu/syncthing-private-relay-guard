#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Run this installer as root.\n' >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RELAY_PORT="${RELAY_PORT:-22067}"
DISCOVERY_PORT="${DISCOVERY_PORT:-8443}"
RELAY_SERVICE="${RELAY_SERVICE:-strelaysrv}"
DISCOVERY_SERVICE="${DISCOVERY_SERVICE:-stdiscosrv}"

for command in firewall-cmd systemctl ss install; do
  command -v "$command" >/dev/null || {
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  }
done

systemctl enable --now firewalld
systemctl enable --now "$RELAY_SERVICE" "$DISCOVERY_SERVICE"

firewall-cmd --permanent --quiet --add-port="${RELAY_PORT}/tcp"
firewall-cmd --permanent --quiet --add-port="${DISCOVERY_PORT}/tcp"
firewall-cmd --quiet --add-port="${RELAY_PORT}/tcp"
firewall-cmd --quiet --add-port="${DISCOVERY_PORT}/tcp"

install -o root -g root -m 0755 \
  "$SCRIPT_DIR/syncthing-control-plane-health" \
  /usr/local/sbin/syncthing-control-plane-health
install -o root -g root -m 0644 \
  "$SCRIPT_DIR/syncthing-control-plane-health.service" \
  /etc/systemd/system/syncthing-control-plane-health.service
install -o root -g root -m 0644 \
  "$SCRIPT_DIR/syncthing-control-plane-health.timer" \
  /etc/systemd/system/syncthing-control-plane-health.timer

install -o root -g root -m 0644 /dev/null \
  /etc/sysconfig/syncthing-control-plane-health
printf 'RELAY_PORT=%q\nDISCOVERY_PORT=%q\nRELAY_SERVICE=%q\nDISCOVERY_SERVICE=%q\n' \
  "$RELAY_PORT" "$DISCOVERY_PORT" "$RELAY_SERVICE" "$DISCOVERY_SERVICE" \
  > /etc/sysconfig/syncthing-control-plane-health

systemctl daemon-reload
systemctl enable --now syncthing-control-plane-health.timer
systemctl start syncthing-control-plane-health.service

printf 'Syncthing control-plane guard installed successfully.\n'


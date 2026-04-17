#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local action=$1

  remote_ssh "tail -n 120 /root/endebx-menu-snapd-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-snapd-${action}.trace || true" >&2 || true
}

run_snapd_action() {
  local action=$1

  if ! remote_ssh TEST_MENU_SNAPD_ACTION="$action" bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_snapd.expect > "/root/endebx-menu-snapd-${TEST_MENU_SNAPD_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_snapd.expect failed during ${action}; showing recent remote logs" >&2
    show_remote_logs "$action"
    exit 1
  fi
}

snapd_state() {
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

if package_installed snapd || command -v snap >/dev/null 2>&1; then
  echo installed
else
  echo absent
fi
REMOTE
}

validate_snapd_state() {
  local expected_state=$1

  remote_ssh bash -s -- "$expected_state" <<'REMOTE'
set -euo pipefail

expected_state=$1

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

wait_for_snap_cli() {
  local attempt

  for attempt in $(seq 1 20); do
    if snap version >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

if [ "$expected_state" = installed ]; then
  package_installed snapd
  command -v snap >/dev/null 2>&1
  test ! -e /etc/apt/preferences.d/snapd.pref
  test -e /snap
  test -d /var/snap
  test -d /var/lib/snapd
  test -d /var/cache/snapd
  test -e /run/snapd.socket
  wait_for_snap_cli
else
  ! package_installed snapd
  ! command -v snap >/dev/null 2>&1
  test -f /etc/apt/preferences.d/snapd.pref
  grep -q '^Package: snapd$' /etc/apt/preferences.d/snapd.pref
  test ! -e /snap
  test ! -e /var/snap
  test ! -e /var/lib/snapd
  test ! -e /var/cache/snapd
  test ! -e /run/snapd.socket
  test ! -e /run/snapd-snap.socket
  ! systemctl is-active --quiet snapd.service
fi
REMOTE
}

normalize_to_absent() {
  if [ "$(snapd_state)" = installed ]; then
    run_snapd_action delete
    validate_snapd_state absent
  fi
}

echo "Testing menu-managed Snapd install/delete on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_snapd.expect" "/root/EnDeBx/tests/runner/menu_snapd.expect"

normalize_to_absent

echo "Installing Snapd via menu.sh"
run_snapd_action install
validate_snapd_state installed

echo "Deleting Snapd via menu.sh"
run_snapd_action delete
validate_snapd_state absent

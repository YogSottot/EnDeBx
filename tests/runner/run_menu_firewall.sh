#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local action=$1

  remote_ssh "tail -n 120 /root/endebx-menu-firewall-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-firewall-${action}.trace || true" >&2 || true
}

run_firewall_action() {
  local action=$1

  if ! remote_ssh TEST_MENU_FIREWALL_ACTION="$action" bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_firewall.expect > "/root/endebx-menu-firewall-${TEST_MENU_FIREWALL_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_firewall.expect failed during ${action}; showing recent remote logs" >&2
    show_remote_logs "$action"
    exit 1
  fi
}

validate_firewall_rule_state() {
  local expected_state=$1

  remote_ssh bash -s -- "$expected_state" <<'REMOTE'
set -euo pipefail
source /root/.env.menu

expected_state=$1
zone="${TEST_MENU_FIREWALL_ZONE}"
port_rule="${TEST_MENU_FIREWALL_PORT}"
runtime_state=$(firewall-cmd --zone="$zone" --query-port="$port_rule" || true)
permanent_state=$(firewall-cmd --permanent --zone="$zone" --query-port="$port_rule" || true)

if [ "$expected_state" = enabled ]; then
  [ "$runtime_state" = yes ]
  [ "$permanent_state" = yes ]
else
  [ "$runtime_state" = no ]
  [ "$permanent_state" = no ]
fi
REMOTE
}

normalize_to_disabled() {
  if ! remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/.env.menu

[ "$(firewall-cmd --zone="${TEST_MENU_FIREWALL_ZONE}" --query-port="${TEST_MENU_FIREWALL_PORT}" || true)" = no ]
[ "$(firewall-cmd --permanent --zone="${TEST_MENU_FIREWALL_ZONE}" --query-port="${TEST_MENU_FIREWALL_PORT}" || true)" = no ]
REMOTE
  then
    run_firewall_action delete
    validate_firewall_rule_state disabled
  fi
}

echo "Testing menu-managed firewall rules on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_firewall.expect" "/root/EnDeBx/tests/runner/menu_firewall.expect"

echo "Checking firewalld availability"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
command -v firewall-cmd >/dev/null 2>&1
firewall-cmd --state | grep -qx running
REMOTE

normalize_to_disabled

echo "Adding test firewall port rule"
run_firewall_action add
validate_firewall_rule_state enabled

echo "Deleting test firewall port rule"
run_firewall_action delete
validate_firewall_rule_state disabled

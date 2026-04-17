#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local feature=$1
  local action=$2

  remote_ssh "tail -n 120 /root/endebx-menu-security-tools-${feature}-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-security-tools-${feature}-${action}.trace || true" >&2 || true
}

run_security_tool_action() {
  local feature=$1
  local action=$2

  if ! remote_ssh \
    TEST_MENU_SECURITY_TOOL="$feature" \
    TEST_MENU_SECURITY_TOOL_ACTION="$action" \
    bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_security_tools.expect > "/root/endebx-menu-security-tools-${TEST_MENU_SECURITY_TOOL}-${TEST_MENU_SECURITY_TOOL_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_security_tools.expect failed during ${feature}/${action}; showing recent remote logs" >&2
    show_remote_logs "$feature" "$action"
    exit 1
  fi
}

security_tool_state() {
  local feature=$1

  remote_ssh bash -s -- "$feature" <<'REMOTE'
set -euo pipefail

feature=$1

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

case "$feature" in
  crowdsec)
    if package_installed crowdsec || command -v crowdsec >/dev/null 2>&1; then
      echo installed
    else
      echo absent
    fi
    ;;
  rkhunter)
    if package_installed rkhunter || command -v rkhunter >/dev/null 2>&1; then
      echo installed
    else
      echo absent
    fi
    ;;
  maldet)
    if [ -x /usr/local/sbin/maldet ] || [ -d /usr/local/maldetect ]; then
      echo installed
    else
      echo absent
    fi
    ;;
  aide)
    if package_installed aide || command -v aide >/dev/null 2>&1; then
      echo installed
    else
      echo absent
    fi
    ;;
  *)
    echo "Unsupported security tool state request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

validate_security_tool_state() {
  local feature=$1
  local expected_state=$2

  remote_ssh bash -s -- "$feature" "$expected_state" <<'REMOTE'
set -euo pipefail
source /root/.env.menu

feature=$1
expected_state=$2

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

service_is_enabled() {
  systemctl is-enabled "$1" 2>/dev/null | grep -qx enabled
}

service_is_active_any() {
  local service_name

  for service_name in "$@"; do
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
      return 0
    fi
  done

  return 1
}

case "$feature" in
  crowdsec)
    if [ "$expected_state" = installed ]; then
      package_installed crowdsec
      command -v crowdsec >/dev/null 2>&1
      command -v cscli >/dev/null 2>&1
      test -f /etc/apt/keyrings/crowdsec.asc
      test -f /etc/crowdsec/config.yaml
      test -f /etc/crowdsec/parsers/s02-enrich/whitelists.custom.yaml
      test -f /etc/bash_completion.d/cscli
      systemctl is-active --quiet crowdsec
      service_is_enabled crowdsec
      package_installed crowdsec-firewall-bouncer-nftables
      service_is_active_any crowdsec-firewall-bouncer crowdsec-firewall-bouncer.service
    else
      ! package_installed crowdsec
      ! command -v crowdsec >/dev/null 2>&1
      ! command -v cscli >/dev/null 2>&1
      test ! -e /etc/apt/sources.list.d/packagecloud_io_crowdsec_crowdsec_debian.list
      test ! -e /etc/apt/keyrings/crowdsec.asc
      test ! -e /etc/nginx/bx/maps/crowdsec_nginx.conf
    fi
    ;;
  rkhunter)
    if [ "$expected_state" = installed ]; then
      package_installed rkhunter
      command -v rkhunter >/dev/null 2>&1
      test -f /etc/default/rkhunter
      test -f /etc/rkhunter.conf.local
      grep -q "REPORT_EMAIL=\"${BS_EMAIL_ADMIN_FOR_NOTIFY}\"" /etc/default/rkhunter
    else
      ! package_installed rkhunter
      ! command -v rkhunter >/dev/null 2>&1
    fi
    ;;
  maldet)
    if [ "$expected_state" = installed ]; then
      test -x /usr/local/sbin/maldet
      test -d /usr/local/maldetect
      test -f /usr/local/maldetect/conf.maldet
      test -x /usr/local/bin/yr
      test -x /usr/local/sbin/update-yara-x
      test -x /etc/cron.weekly/update-yara-x
      if [ "${BS_SETUP_MALDET_MONITORING_SERVICE}" = "Y" ]; then
        systemctl is-active --quiet maldet
        service_is_enabled maldet
      fi
    else
      test ! -e /usr/local/sbin/maldet
      test ! -e /usr/local/maldetect
      test ! -e /usr/local/bin/yr
      test ! -e /usr/local/sbin/update-yara-x
      test ! -e /etc/cron.weekly/update-yara-x
      ! systemctl is-active --quiet maldet
    fi
    ;;
  aide)
    if [ "$expected_state" = installed ]; then
      package_installed aide
      command -v aide >/dev/null 2>&1
      test -f /etc/aide/aide.conf
      test -f /etc/aide/aide.conf.d/80_aide_bitrix
      test -L /etc/aide/aide.conf.d/30_aide_bitrix
      test -f /usr/local/sbin/aide-alert-html.sh
      test -f /etc/cron.d/aide-alert-html
      ls /var/lib/aide/aide.db* >/dev/null 2>&1
    else
      ! package_installed aide
      ! command -v aide >/dev/null 2>&1
      test ! -e /etc/cron.d/aide-alert-html
      test ! -e /usr/local/sbin/aide-alert-html.sh
      test ! -e /etc/aide/aide.conf.d/80_aide_bitrix
      test ! -e /etc/aide/aide.conf.d/30_aide_bitrix
      test ! -e /var/lib/aide
      test ! -e /var/log/aide
    fi
    ;;
  *)
    echo "Unsupported security tool validation request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

normalize_to_absent() {
  local feature=$1

  if [ "$(security_tool_state "$feature")" = installed ]; then
    run_security_tool_action "$feature" delete
    validate_security_tool_state "$feature" absent
  fi
}

test_security_tool_install_delete() {
  local feature=$1

  normalize_to_absent "$feature"
  run_security_tool_action "$feature" install
  validate_security_tool_state "$feature" installed
  run_security_tool_action "$feature" delete
  validate_security_tool_state "$feature" absent
}

echo "Testing menu-managed security tools on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_security_tools.expect" "/root/EnDeBx/tests/runner/menu_security_tools.expect"

echo "Testing Crowdsec install/delete"
test_security_tool_install_delete crowdsec

echo "Testing Rkhunter install/delete"
test_security_tool_install_delete rkhunter

echo "Testing Linux Malware Detect install/delete"
test_security_tool_install_delete maldet

echo "Testing AIDE install/delete"
test_security_tool_install_delete aide

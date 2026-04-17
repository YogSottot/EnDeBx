#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local feature=$1
  local action=$2

  remote_ssh "tail -n 120 /root/endebx-menu-site-options-${feature}-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-site-options-${feature}-${action}.trace || true" >&2 || true
}

run_site_option_action() {
  local feature=$1
  local action=${2:-toggle}

  if ! remote_ssh TEST_MENU_SITE_FEATURE="$feature" TEST_MENU_SITE_FEATURE_ACTION="$action" bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_site_options.expect > "/root/endebx-menu-site-options-${TEST_MENU_SITE_FEATURE}-${TEST_MENU_SITE_FEATURE_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_site_options.expect failed during ${feature}/${action}; showing recent remote logs" >&2
    show_remote_logs "$feature" "$action"
    exit 1
  fi
}

feature_state() {
  local feature=$1

  remote_ssh bash -s -- "$feature" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

feature=$1
domain="${TEST_MENU_FULL_DOMAIN}"
site_root="${TEST_MENU_FULL_PATH}"
basic_auth_conf="${BS_PATH_NGINX}/site_settings/${domain}/basic_auth.conf"
htpasswd_file="${BS_PATH_NGINX}/site_settings/${domain}/.htpasswd"
bots_block_conf="${BS_PATH_NGINX}/site_settings/${domain}/bots_block.conf"
ip_conf="${BS_PATH_NGINX_SITES_CONF}/bx_ext_ip.conf"
ip_link="${BS_PATH_NGINX_SITES_ENABLED}/bx_ext_ip.conf"

case "$feature" in
  redirect)
    if [ -f "${site_root}/.htsecure" ]; then
      echo enabled
    else
      echo disabled
    fi
    ;;
  ipblock)
    if [ -e "$ip_conf" ] || [ -L "$ip_link" ]; then
      echo enabled
    else
      echo disabled
    fi
    ;;
  basicauth)
    if [ -e "$basic_auth_conf" ] || [ -e "$htpasswd_file" ]; then
      echo enabled
    else
      echo disabled
    fi
    ;;
  botblock)
    if [ -s "$bots_block_conf" ]; then
      echo enabled
    else
      echo disabled
    fi
    ;;
  *)
    echo "Unsupported feature state request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

validate_feature_state() {
  local feature=$1
  local expected_state=$2

  remote_ssh bash -s -- "$feature" "$expected_state" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

feature=$1
expected_state=$2
domain="${TEST_MENU_FULL_DOMAIN}"
site_root="${TEST_MENU_FULL_PATH}"
basic_auth_conf="${BS_PATH_NGINX}/site_settings/${domain}/basic_auth.conf"
htpasswd_file="${BS_PATH_NGINX}/site_settings/${domain}/.htpasswd"
bots_block_conf="${BS_PATH_NGINX}/site_settings/${domain}/bots_block.conf"
ip_conf="${BS_PATH_NGINX_SITES_CONF}/bx_ext_ip.conf"
ip_link="${BS_PATH_NGINX_SITES_ENABLED}/bx_ext_ip.conf"

case "$feature" in
  redirect)
    if [ "$expected_state" = enabled ]; then
      test -f "${site_root}/.htsecure"
    else
      test ! -e "${site_root}/.htsecure"
    fi
    ;;
  ipblock)
    if [ "$expected_state" = enabled ]; then
      test -f "$ip_conf"
      test -L "$ip_link"
      grep -q "ssl_reject_handshake on;" "$ip_conf"
      grep -q "return 444;" "$ip_conf"
    else
      test ! -L "$ip_link"
      if [ -f "$ip_conf" ]; then
        test ! -s "$ip_conf"
      fi
    fi
    ;;
  basicauth)
    if [ "$expected_state" = enabled ]; then
      test -f "$basic_auth_conf"
      test -f "$htpasswd_file"
      grep -q "auth_basic \"Private\";" "$basic_auth_conf"
      grep -q "auth_basic_user_file ${htpasswd_file};" "$basic_auth_conf"
      htpasswd -vb "$htpasswd_file" "$BS_NGINX_BASIC_AUTH_LOGIN" "$BS_NGINX_BASIC_AUTH_PASSWORD"
    else
      test ! -e "$basic_auth_conf"
      test ! -e "$htpasswd_file"
    fi
    ;;
  botblock)
    if [ "$expected_state" = enabled ]; then
      test -f "$bots_block_conf"
      grep -q "include bots.d/ddos.conf;" "$bots_block_conf"
      grep -q "include bots.d/blockbots.conf;" "$bots_block_conf"
    else
      test ! -e "$bots_block_conf"
    fi
    ;;
  *)
    echo "Unsupported feature validation request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

normalize_to_disabled() {
  local feature=$1
  local action=${2:-toggle}
  local current_state

  current_state="$(feature_state "$feature")"
  if [ "$current_state" = enabled ]; then
    run_site_option_action "$feature" "$action"
    validate_feature_state "$feature" disabled
  fi
}

test_toggle_feature() {
  local feature=$1
  local action=${2:-toggle}

  normalize_to_disabled "$feature" "$action"
  run_site_option_action "$feature" "$action"
  validate_feature_state "$feature" enabled
  run_site_option_action "$feature" "$action"
  validate_feature_state "$feature" disabled
}

echo "Testing menu-managed site options on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_site_options.expect" "/root/EnDeBx/tests/runner/menu_site_options.expect"

echo "Checking that the target full site exists"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/.env.menu

test -d "${TEST_MENU_FULL_PATH}"
REMOTE

echo "Testing redirect HTTP to HTTPS toggle"
test_toggle_feature redirect

echo "Testing block/unblock access by IP toggle"
test_toggle_feature ipblock

echo "Testing basic auth create/delete"
normalize_to_disabled basicauth delete
run_site_option_action basicauth create
validate_feature_state basicauth enabled
run_site_option_action basicauth delete
validate_feature_state basicauth disabled

echo "Testing bot blocker toggle"
test_toggle_feature botblock

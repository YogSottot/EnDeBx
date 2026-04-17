#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local feature=$1
  local action=$2

  remote_ssh "tail -n 120 /root/endebx-menu-extensions-${feature}-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-extensions-${feature}-${action}.trace || true" >&2 || true
}

run_extension_action() {
  local feature=$1
  local action=$2
  local push_remove_redis=${3:-Y}

  if ! remote_ssh \
    TEST_MENU_EXTENSION="$feature" \
    TEST_MENU_EXTENSION_ACTION="$action" \
    TEST_MENU_PUSH_REMOVE_REDIS="$push_remove_redis" \
    bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_extensions.expect > "/root/endebx-menu-extensions-${TEST_MENU_EXTENSION}-${TEST_MENU_EXTENSION_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_extensions.expect failed during ${feature}/${action}; showing recent remote logs" >&2
    show_remote_logs "$feature" "$action"
    exit 1
  fi
}

extension_state() {
  local feature=$1

  remote_ssh bash -s -- "$feature" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh

feature=$1

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

case "$feature" in
  memcached)
    if package_installed memcached || command -v memcached >/dev/null 2>&1; then
      echo installed
    else
      echo absent
    fi
    ;;
  push)
    if [ -f "$BS_PUSH_SERVER_CONFIG" ] || [ -f /etc/systemd/system/push-server.service ] || [ -e /usr/local/bin/push-server-multi ]; then
      echo installed
    else
      echo absent
    fi
    ;;
  sphinx)
    if package_installed sphinxsearch; then
      echo installed
    else
      echo absent
    fi
    ;;
  netdata)
    if command -v netdata >/dev/null 2>&1 || [ -x /usr/sbin/netdata ] || [ -d /etc/netdata ]; then
      echo installed
    else
      echo absent
    fi
    ;;
  docker)
    if command -v docker >/dev/null 2>&1 || package_installed docker-ce; then
      echo installed
    else
      echo absent
    fi
    ;;
  *)
    echo "Unsupported extension state request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

validate_extension_state() {
  local feature=$1
  local expected_state=$2

  remote_ssh bash -s -- "$feature" "$expected_state" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh

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
  memcached)
    if [ "$expected_state" = installed ]; then
      package_installed memcached
      command -v memcached >/dev/null 2>&1
      test -f /etc/memcached.conf
      systemctl is-active --quiet memcached
      service_is_enabled memcached
    else
      ! package_installed memcached
      ! command -v memcached >/dev/null 2>&1
      ! systemctl is-active --quiet memcached
    fi
    ;;
  push)
    if [ "$expected_state" = installed ]; then
      test -f "$BS_PUSH_SERVER_CONFIG"
      test -f /etc/systemd/system/push-server.service
      test -x /usr/local/bin/push-server-multi
      test -L /etc/push-server
      test -L /opt/push-server
      test -d /opt/node_modules/push-server
      test -f /etc/tmpfiles.d/push-server.conf
      test -f /etc/logrotate.d/push-server
      test -d /var/log/push-server
      systemctl is-active --quiet push-server
      service_is_enabled push-server
      package_installed redis-server
      service_is_active_any redis-server redis
    else
      test ! -e "$BS_PUSH_SERVER_CONFIG"
      test ! -e /etc/systemd/system/push-server.service
      test ! -e /usr/local/bin/push-server-multi
      test ! -e /etc/push-server
      test ! -e /opt/push-server
      test ! -e /opt/node_modules/push-server
      test ! -e /etc/tmpfiles.d/push-server.conf
      test ! -e /etc/logrotate.d/push-server
      test ! -e /var/log/push-server
      ! systemctl is-active --quiet push-server
      ! package_installed redis-server
      ! service_is_active_any redis-server redis
    fi
    ;;
  sphinx)
    if [ "$expected_state" = installed ]; then
      package_installed sphinxsearch
      test -f /etc/sphinxsearch/sphinx.conf
      test -f /etc/tmpfiles.d/sphinx.conf
      grep -q "listen.*9312" /etc/sphinxsearch/sphinx.conf
      systemctl is-active --quiet sphinxsearch
      service_is_enabled sphinxsearch
    else
      ! package_installed sphinxsearch
      ! systemctl is-active --quiet sphinxsearch
    fi
    ;;
  netdata)
    if [ "$expected_state" = installed ]; then
      command -v netdata >/dev/null 2>&1 || test -x /usr/sbin/netdata
      package_installed netdata-repo
      test -d /etc/netdata
      test -f /etc/apt/sources.list.d/netdata.list || test -f /etc/apt/sources.list.d/netdata.sources
      test ! -e /etc/apt/sources.list.d/netdata-temp.sources
      test ! -e /etc/apt/keyrings/netdata-archive-keyring.gpg.key
      test -f /etc/nginx/custom_conf.d/section_http/upstream_netdata.conf
      test -f /etc/nginx/custom_conf.d/section_listen_http_and_https/netdata.conf
      test -s /etc/nginx/netdata_passwds
      grep -q "upstream netdata" /etc/nginx/custom_conf.d/section_http/upstream_netdata.conf
      grep -q "proxy_pass http://netdata/" /etc/nginx/custom_conf.d/section_listen_http_and_https/netdata.conf
      systemctl is-active --quiet netdata
      service_is_enabled netdata
    else
      ! command -v netdata >/dev/null 2>&1
      ! package_installed netdata-repo
      test ! -e /usr/sbin/netdata
      test ! -e /etc/netdata
      test ! -e /etc/apt/sources.list.d/netdata.list
      test ! -e /etc/apt/sources.list.d/netdata.sources
      test ! -e /etc/apt/sources.list.d/netdata-temp.sources
      test ! -e /etc/apt/keyrings/netdata-archive-keyring.gpg.key
      test ! -e /etc/nginx/custom_conf.d/section_http/upstream_netdata.conf
      test ! -e /etc/nginx/custom_conf.d/section_listen_http_and_https/netdata.conf
      ! systemctl is-active --quiet netdata
    fi
    ;;
  docker)
    if [ "$expected_state" = installed ]; then
      command -v docker >/dev/null 2>&1
      package_installed docker-ce
      package_installed docker-ce-cli
      test -f /etc/apt/sources.list.d/docker.list
      systemctl is-active --quiet docker
      service_is_enabled docker
      getent group docker >/dev/null
    else
      ! command -v docker >/dev/null 2>&1
      ! package_installed docker-ce
      ! package_installed docker-ce-cli
      ! systemctl is-active --quiet docker
    fi
    ;;
  *)
    echo "Unsupported extension validation request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

normalize_to_absent() {
  local feature=$1
  local current_state

  current_state="$(extension_state "$feature")"
  if [ "$current_state" = installed ]; then
    if [ "$feature" = push ]; then
      run_extension_action "$feature" delete Y
    else
      run_extension_action "$feature" delete
    fi
    validate_extension_state "$feature" absent
  fi
}

test_extension_install_delete() {
  local feature=$1

  normalize_to_absent "$feature"
  run_extension_action "$feature" install
  validate_extension_state "$feature" installed

  if [ "$feature" = push ]; then
    run_extension_action "$feature" delete Y
  else
    run_extension_action "$feature" delete
  fi

  validate_extension_state "$feature" absent
}

echo "Testing menu-managed extensions on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_extensions.expect" "/root/EnDeBx/tests/runner/menu_extensions.expect"

echo "Testing Memcached install/delete"
test_extension_install_delete memcached

#echo "Testing Push server install/delete"
#test_extension_install_delete push

echo "Testing Sphinx install/delete"
test_extension_install_delete sphinx

echo "Testing Netdata install/delete"
test_extension_install_delete netdata

echo "Testing Docker install/delete"
test_extension_install_delete docker

#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

RESOLV_BAK_BASE="/root/endebx-resolv-conf.ntlm"
resolver_changed=0
keep_resolver_on_exit=0

show_remote_logs() {
  local label=$1

  remote_ssh "tail -n 160 /root/endebx-menu-ntlm-${label}.log || true" >&2 || true
  remote_ssh "tail -n 160 /tmp/endebx-menu-ntlm-${label}.trace || true" >&2 || true
}

ensure_remote_dns_tools() {
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if command -v nsupdate >/dev/null 2>&1 && command -v dig >/dev/null 2>&1; then
  exit 0
fi

apt-get update -y
apt-get install -y dnsutils
REMOTE
}

detect_remote_ntlm_lan_ip() {
  remote_ssh bash -s -- "$TEST_MENU_NTLM_DPS" <<'REMOTE'
set -euo pipefail

target=$1
target_ip=""
src_ip=""

if printf '%s\n' "$target" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
  target_ip="$target"
else
  target_ip=$(getent ahostsv4 "$target" | awk 'NR == 1 { print $1; exit }')
fi

if [ -n "$target_ip" ]; then
  src_ip=$(ip -o -4 route get "$target_ip" 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}')
fi

printf '%s\n' "$src_ip"
REMOTE
}

remote_ntlm_dns_fqdn() {
  remote_ssh bash -s -- "$TEST_MENU_NTLM_FQDN" <<'REMOTE'
set -euo pipefail

ntlm_fqdn=$1
printf '%s.%s\n' "$(hostname -s | tr '[:upper:]' '[:lower:]')" "$(printf '%s' "$ntlm_fqdn" | tr '[:upper:]' '[:lower:]')"
REMOTE
}

register_remote_ad_dns() {
  local lan_ip dns_fqdn

  lan_ip=$(detect_remote_ntlm_lan_ip)
  if [ -z "$lan_ip" ]; then
    echo "Unable to detect LAN IP for NTLM DNS registration" >&2
    exit 1
  fi

  dns_fqdn=$(remote_ntlm_dns_fqdn)
  echo "Registering AD DNS record ${dns_fqdn} -> ${lan_ip}"

  remote_ssh bash -s -- "$dns_fqdn" "$lan_ip" "$TEST_MENU_NTLM_DPS" <<'REMOTE'
set -euo pipefail

dns_fqdn=$1
lan_ip=$2
dns_server=$3

if command -v nsupdate >/dev/null 2>&1 && command -v dig >/dev/null 2>&1; then
  nsupdate <<EOF
server ${dns_server}
update delete ${dns_fqdn}. A
update add ${dns_fqdn}. 60 A ${lan_ip}
send
EOF
else
  net -P ads dns register "$dns_fqdn" "$lan_ip"
fi

for _ in 1 2 3 4 5; do
  if command -v dig >/dev/null 2>&1; then
    if dig +short @"${dns_server}" A "$dns_fqdn" | grep -Fxq "$lan_ip"; then
      exit 0
    fi
  elif getent ahostsv4 "$dns_fqdn" | awk '{print $1}' | grep -Fxq "$lan_ip"; then
    exit 0
  fi
  sleep 1
done

echo "AD DNS record ${dns_fqdn} was not resolved to ${lan_ip} after registration" >&2
exit 1
REMOTE
}

unregister_remote_ad_dns() {
  local dns_fqdn

  dns_fqdn=$(remote_ntlm_dns_fqdn)
  echo "Unregistering AD DNS record ${dns_fqdn}"

  remote_ssh bash -s -- "$dns_fqdn" "$TEST_MENU_NTLM_DPS" <<'REMOTE'
set -euo pipefail

dns_fqdn=$1
dns_server=$2

if command -v nsupdate >/dev/null 2>&1 && command -v dig >/dev/null 2>&1; then
  nsupdate <<EOF
server ${dns_server}
update delete ${dns_fqdn}. A
send
EOF
elif net ads dns gethostbyname "$dns_fqdn" >/dev/null 2>&1; then
  net -P ads dns unregister "$dns_fqdn"
fi

for _ in 1 2 3 4 5; do
  if command -v dig >/dev/null 2>&1; then
    if [ -z "$(dig +short @"${dns_server}" A "$dns_fqdn")" ]; then
      exit 0
    fi
  elif ! getent ahostsv4 "$dns_fqdn" >/dev/null 2>&1; then
      exit 0
  fi
  sleep 1
done

echo "AD DNS record ${dns_fqdn} still resolves after unregister" >&2
exit 1
REMOTE
}

restore_remote_resolver() {
  if [ "$resolver_changed" -ne 1 ]; then
    return 0
  fi

  remote_ssh bash -s -- "$RESOLV_BAK_BASE" <<'REMOTE'
set -euo pipefail

backup_base=$1

if [ ! -f "${backup_base}.path" ] || [ ! -f "${backup_base}.orig" ]; then
  exit 0
fi

resolved_path=$(cat "${backup_base}.path")
cat "${backup_base}.orig" > "$resolved_path"
rm -f "${backup_base}.path" "${backup_base}.orig"
REMOTE
  resolver_changed=0
}

cleanup() {
  if [ "$keep_resolver_on_exit" -eq 1 ]; then
    return 0
  fi

  restore_remote_resolver
}

trap cleanup EXIT

configure_remote_resolver() {
  local ntlm_dps=$1

  remote_ssh bash -s -- "$ntlm_dps" "$RESOLV_BAK_BASE" <<'REMOTE'
set -euo pipefail

ntlm_dps=$1
backup_base=$2
resolved_path=$(readlink -f /etc/resolv.conf)

if [ ! -f "${backup_base}.path" ]; then
  printf '%s\n' "$resolved_path" > "${backup_base}.path"
fi

if [ ! -f "${backup_base}.orig" ]; then
  cp "$resolved_path" "${backup_base}.orig"
fi

awk '!/^[[:space:]]*nameserver[[:space:]]+/' "${backup_base}.orig" > "${backup_base}.body"
{
  printf 'nameserver %s\n' "$ntlm_dps"
  cat "${backup_base}.body"
} > "$resolved_path"
rm -f "${backup_base}.body"
REMOTE

  resolver_changed=1
}

run_ntlm_action() {
  local label=$1
  local action=$2

  remote_ssh "rm -f /root/endebx-menu-ntlm-${label}.log /tmp/endebx-menu-ntlm-${label}.trace"

  if ! remote_ssh \
    EXPECT_DEBUG="${EXPECT_DEBUG:-0}" \
    TEST_MENU_NTLM_ACTION="$action" \
    TEST_MENU_NTLM_SITE_PATH="$TEST_MENU_NTLM_SITE_PATH" \
    TEST_MENU_NTLM_SSL_LETS_ENCRYPT="$TEST_MENU_NTLM_SSL_LETS_ENCRYPT" \
    TEST_MENU_NTLM_NAME="$TEST_MENU_NTLM_NAME" \
    TEST_MENU_NTLM_FQDN="$TEST_MENU_NTLM_FQDN" \
    TEST_MENU_NTLM_DPS="$TEST_MENU_NTLM_DPS" \
    TEST_MENU_NTLM_USER="$TEST_MENU_NTLM_USER" \
    TEST_MENU_NTLM_PASS="$TEST_MENU_NTLM_PASS" \
    bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_ntlm.expect > "/root/endebx-menu-ntlm-${TEST_MENU_NTLM_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_ntlm.expect failed during ${action}; showing recent remote logs" >&2
    show_remote_logs "$action"
    exit 1
  fi
}

validate_ntlm_state() {
  local expected_state=$1

  remote_ssh bash -s -- "$expected_state" "$TEST_MENU_NTLM_SITE_PATH" "$TEST_MENU_NTLM_DPS" "$TEST_MENU_NTLM_FQDN" <<'REMOTE'
set -euo pipefail

expected_state=$1
site_path=$2
ntlm_dps=$3
ntlm_fqdn=$4
site_name=$(basename "$site_path")
resolv_path=$(readlink -f /etc/resolv.conf)

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

php_ntlm_use_flag() {
  local php_check_script
  php_check_script=$(mktemp /tmp/endebx-ntlm-option-check.XXXXXX.php)

  cat > "$php_check_script" <<'PHP'
<?php
$root = $argv[1];
$settings = require $root . '/bitrix/.settings.php';
$connection = $settings['connections']['value']['default'] ?? [];
$className = $connection['className'] ?? '';
$host = $connection['host'] ?? 'localhost';
$database = $connection['database'] ?? '';
$login = $connection['login'] ?? '';
$password = $connection['password'] ?? '';
$value = 'N';

if ($className === '\\Bitrix\\Main\\DB\\MysqliConnection')
{
    $db = @new mysqli($host, $login, $password, $database);
    if (!$db->connect_errno)
    {
        $result = $db->query("SELECT VALUE FROM b_option WHERE MODULE_ID='ldap' AND NAME='use_ntlm' LIMIT 1");
        if ($result && ($row = $result->fetch_assoc()))
        {
            $value = (string)$row['VALUE'];
        }
        $db->close();
    }
}
elseif ($className === '\\Bitrix\\Main\\DB\\PgsqlConnection')
{
    $db = @pg_connect("host={$host} dbname={$database} user={$login} password={$password}");
    if ($db)
    {
        $result = @pg_query($db, "SELECT VALUE FROM b_option WHERE MODULE_ID='ldap' AND NAME='use_ntlm' LIMIT 1");
        if ($result && ($row = pg_fetch_assoc($result)))
        {
            $value = (string)$row['value'];
        }
        pg_close($db);
    }
}

echo $value;
PHP

  php "$php_check_script" "$site_path" 2>/dev/null || true
  rm -f "$php_check_script"
}

if [ "$expected_state" = "configured" ]; then
  package_installed samba
  package_installed winbind
  package_installed libapache2-mod-auth-ntlm-winbind
  test -e /etc/apache2/conf-enabled/bx_ntlm.conf
  test -e "/etc/apache2/sites-enabled/ntlm_${site_name}.conf"
  test -e /etc/apache2/mods-enabled/auth_ntlm_winbind.load
  grep -Eq "^[[:space:]]*password server[[:space:]]*=[[:space:]]*${ntlm_dps}$" /etc/samba/smb.conf
  grep -Eiq "^[[:space:]]*default_realm[[:space:]]*=[[:space:]]*${ntlm_fqdn}$" /etc/krb5.conf
  if command -v firewall-cmd >/dev/null 2>&1; then
    test "$(firewall-cmd --query-port=8890/tcp 2>/dev/null || true)" = "yes"
    test "$(firewall-cmd --query-port=8891/tcp 2>/dev/null || true)" = "yes"
  fi
  net ads testjoin >/dev/null 2>&1
  [ "$(php_ntlm_use_flag)" = "Y" ]
else
  ! package_installed winbind
  ! package_installed libapache2-mod-auth-ntlm-winbind
  ! test -e /etc/apache2/conf-enabled/bx_ntlm.conf
  ! test -e "/etc/apache2/sites-enabled/ntlm_${site_name}.conf"
  ! test -e /etc/apache2/mods-enabled/auth_ntlm_winbind.load
  if command -v firewall-cmd >/dev/null 2>&1; then
    test "$(firewall-cmd --query-port=8890/tcp 2>/dev/null || true)" = "no"
    test "$(firewall-cmd --query-port=8891/tcp 2>/dev/null || true)" = "no"
  fi
  [ "$(php_ntlm_use_flag)" = "N" ]
fi
REMOTE
}

ntlm_is_configured() {
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail

command -v net >/dev/null 2>&1
net ads info >/dev/null 2>&1
net ads testjoin >/dev/null 2>&1
REMOTE
}

echo "Testing menu-managed NTLM configuration on $(remote_fqdn)"

generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
# shellcheck source=/dev/null
source "$generated_env_menu"

if [ -z "${TEST_MENU_NTLM_PASS:-}" ]; then
  echo "TEST_MENU_NTLM_PASS is not set in $generated_env_menu" >&2
  exit 1
fi

echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_ntlm.expect" "/root/EnDeBx/tests/runner/menu_ntlm.expect"

echo "Ensuring DNS update tools are available on remote host"
ensure_remote_dns_tools

if ntlm_is_configured; then
  echo "Existing NTLM configuration detected; running delete flow"
  echo "Pointing remote resolver to ${TEST_MENU_NTLM_DPS}"
  configure_remote_resolver "$TEST_MENU_NTLM_DPS"

  unregister_remote_ad_dns

  echo "Deleting NTLM settings through menu.sh"
  run_ntlm_action delete delete
  validate_ntlm_state removed

  echo "Restoring remote resolver configuration"
  restore_remote_resolver
else
  echo "No NTLM configuration detected; running create flow"
  echo "Pointing remote resolver to ${TEST_MENU_NTLM_DPS}"
  configure_remote_resolver "$TEST_MENU_NTLM_DPS"

  echo "Configuring NTLM through menu.sh"
  run_ntlm_action create create

  keep_resolver_on_exit=1

  echo "Re-pointing remote resolver to ${TEST_MENU_NTLM_DPS} after NTLM setup"
  configure_remote_resolver "$TEST_MENU_NTLM_DPS"

  register_remote_ad_dns

  validate_ntlm_state configured

  echo "NTLM is configured for ${TEST_MENU_NTLM_SITE_PATH} on $(remote_fqdn)."
  echo "Resolver is intentionally left pointed to ${TEST_MENU_NTLM_DPS}."
  echo "After manual browser verification, run make menu-ntlm again to delete NTLM settings and restore resolver."
fi

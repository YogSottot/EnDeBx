#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

echo "Creating menu-managed test sites on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_create_sites.expect" "/root/EnDeBx/tests/runner/menu_create_sites.expect"
if ! remote_ssh bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_create_sites.expect > /root/endebx-menu-create-sites.log 2>&1
REMOTE
then
  echo "menu_create_sites.expect failed; showing recent remote logs" >&2
  remote_ssh "tail -n 120 /root/endebx-menu-create-sites.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-create-sites.trace || true" >&2 || true
  exit 1
fi

echo "Validating created sites"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

default_sites_dir=$(dirname "$BS_PATH_DEFAULT_SITE")
link_default_path="${default_sites_dir}/${TEST_MENU_LINK_DEFAULT_DOMAIN}"
full_site_path="${TEST_MENU_FULL_PATH}"
link_full_path="/var/www/${TEST_MENU_FULL_USER}/${TEST_MENU_LINK_FULL_DOMAIN}"

id "${TEST_MENU_FULL_USER}" >/dev/null 2>&1

test -d "$link_default_path"
test -f "$link_default_path/index.php"
test -L "$link_default_path/bitrix"
test -f "${BS_PATH_NGINX_SITES_CONF}/${TEST_MENU_LINK_DEFAULT_DOMAIN}.conf"
test -L "${BS_PATH_NGINX_SITES_ENABLED}/${TEST_MENU_LINK_DEFAULT_DOMAIN}.conf"
test -f "${BS_PATH_APACHE_SITES_CONF}/${TEST_MENU_LINK_DEFAULT_DOMAIN}.conf"
test -L "${BS_PATH_APACHE_SITES_ENABLED}/${TEST_MENU_LINK_DEFAULT_DOMAIN}.conf"

test -d "$full_site_path"
test -f "$full_site_path/index.php"
test -f "$full_site_path/bitrix/.settings.php"
test -f "$full_site_path/bitrix/php_interface/dbconn.php"
test -f "${BS_PATH_NGINX_SITES_CONF}/${TEST_MENU_FULL_DOMAIN}.conf"
test -L "${BS_PATH_NGINX_SITES_ENABLED}/${TEST_MENU_FULL_DOMAIN}.conf"
test -f "${BS_PATH_APACHE_SITES_CONF}/${TEST_MENU_FULL_DOMAIN}.conf"
test -L "${BS_PATH_APACHE_SITES_ENABLED}/${TEST_MENU_FULL_DOMAIN}.conf"

test -d "$link_full_path"
test -f "$link_full_path/index.php"
test -L "$link_full_path/bitrix"
test -f "${BS_PATH_NGINX_SITES_CONF}/${TEST_MENU_LINK_FULL_DOMAIN}.conf"
test -L "${BS_PATH_NGINX_SITES_ENABLED}/${TEST_MENU_LINK_FULL_DOMAIN}.conf"
test -f "${BS_PATH_APACHE_SITES_CONF}/${TEST_MENU_LINK_FULL_DOMAIN}.conf"
test -L "${BS_PATH_APACHE_SITES_ENABLED}/${TEST_MENU_LINK_FULL_DOMAIN}.conf"

if [ "${TEST_MENU_ENABLE_LETS_ENCRYPT:-N}" = "Y" ]; then
  test -f "/etc/letsencrypt/live/${TEST_MENU_DEFAULT_DOMAIN}/fullchain.pem"
  test -f "/etc/letsencrypt/live/${TEST_MENU_DEFAULT_DOMAIN}/privkey.pem"
  test -f "${BS_PATH_NGINX}/site_settings/${BS_DEFAULT_SITE_NAME}/ssl.conf"
  grep -q "/etc/letsencrypt/live/${TEST_MENU_DEFAULT_DOMAIN}/fullchain.pem" "${BS_PATH_NGINX}/site_settings/${BS_DEFAULT_SITE_NAME}/ssl.conf"

  for domain in \
    "${TEST_MENU_LINK_DEFAULT_DOMAIN}" \
    "${TEST_MENU_FULL_DOMAIN}" \
    "${TEST_MENU_LINK_FULL_DOMAIN}"; do
    test -f "/etc/letsencrypt/live/${domain}/fullchain.pem"
    test -f "/etc/letsencrypt/live/${domain}/privkey.pem"
    test -f "${BS_PATH_NGINX}/site_settings/${domain}/ssl.conf"
    grep -q "/etc/letsencrypt/live/${domain}/fullchain.pem" "${BS_PATH_NGINX}/site_settings/${domain}/ssl.conf"
  done
fi
REMOTE

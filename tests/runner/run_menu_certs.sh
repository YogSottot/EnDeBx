#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

echo "Configuring Let's Encrypt certificates on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_configure_certs.expect" "/root/EnDeBx/tests/runner/menu_configure_certs.expect"
if ! remote_ssh bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_configure_certs.expect > /root/endebx-menu-certs.log 2>&1
REMOTE
then
  echo "menu_configure_certs.expect failed; showing recent remote logs" >&2
  remote_ssh "tail -n 120 /root/endebx-menu-certs.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-certs.trace || true" >&2 || true
  exit 1
fi

echo "Validating configured certificates"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

test -f "/etc/letsencrypt/live/${TEST_MENU_DEFAULT_DOMAIN}/fullchain.pem"
test -f "/etc/letsencrypt/live/${TEST_MENU_DEFAULT_DOMAIN}/privkey.pem"
test -f "${BS_PATH_NGINX}/site_settings/${BS_DEFAULT_SITE_NAME}/ssl.conf"
grep -q "/etc/letsencrypt/live/${TEST_MENU_DEFAULT_DOMAIN}/fullchain.pem" \
  "${BS_PATH_NGINX}/site_settings/${BS_DEFAULT_SITE_NAME}/ssl.conf"

for domain in \
  "${TEST_MENU_LINK_DEFAULT_DOMAIN}" \
  "${TEST_MENU_FULL_DOMAIN}" \
  "${TEST_MENU_LINK_FULL_DOMAIN}"; do
  test -f "/etc/letsencrypt/live/${domain}/fullchain.pem"
  test -f "/etc/letsencrypt/live/${domain}/privkey.pem"
  test -f "${BS_PATH_NGINX}/site_settings/${domain}/ssl.conf"
  grep -q "/etc/letsencrypt/live/${domain}/fullchain.pem" \
    "${BS_PATH_NGINX}/site_settings/${domain}/ssl.conf"
done
REMOTE

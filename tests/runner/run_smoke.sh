#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

echo "Running remote smoke checks on $(remote_fqdn)"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

source /root/vm_menu/bash_scripts/config.sh
if [ -f /root/.env.menu ]; then
  # shellcheck source=/dev/null
  source /root/.env.menu
fi

test -x /root/menu.sh
command -v ansible-playbook >/dev/null 2>&1
systemctl is-active --quiet "$BS_SERVICE_NGINX_NAME"
systemctl is-active --quiet "$BS_SERVICE_APACHE_NAME"
systemctl is-active --quiet "php${BX_PHP_DEFAULT_VERSION}-fpm"
test -d "$BS_PATH_DEFAULT_SITE"

case "${BS_INSTALL_DATABASE}" in
  mysql)
    mysqladmin ping >/dev/null 2>&1 || systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql
    ;;
  pgsql)
    pg_isready -q || systemctl is-active --quiet postgresql
    ;;
esac

timeout 20 bash -lc 'printf "0\n" | /root/menu.sh >/tmp/endebx-menu-smoke.log 2>&1'
REMOTE

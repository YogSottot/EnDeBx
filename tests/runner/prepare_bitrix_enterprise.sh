#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

echo "Preparing Bitrix Enterprise files on $(remote_fqdn)"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail

source /root/vm_menu/bash_scripts/config.sh
if [ -f /root/.env.menu ]; then
  # shellcheck source=/dev/null
  source /root/.env.menu
fi

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"
setup_url="${TEST_BITRIX_SETUP_URL:-}"
archive_url=""

case "${BS_INSTALL_DATABASE}" in
  mysql)
    archive_url="${TEST_BITRIX_DIST_URL_MYSQL:-}"
    ;;
  pgsql)
    archive_url="${TEST_BITRIX_DIST_URL_PGSQL:-}"
    ;;
esac

mkdir -p "$site_root"

if [ -n "$setup_url" ]; then
  if [ ! -s "$site_root/bitrixsetup.php" ]; then
    curl -fL "$setup_url" -o "$site_root/bitrixsetup.php"
  fi
fi

if [ -n "$archive_url" ]; then
  archive_name=$(basename "$archive_url")
  archive_path="$site_root/$archive_name"
  if [ ! -s "$archive_path" ]; then
    curl -fL "$archive_url" -o "$archive_path"
  fi
  tar -xzf "$archive_path" -C "$site_root"
fi

chown -R "$BS_DEFAULT_USER_SERVER_SITES:$BS_GROUP_USER_SERVER_SITES" "$site_root"
REMOTE

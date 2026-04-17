#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

ensure_output_dir
archive_name="$(remote_name)-logs-$(date +%Y%m%d-%H%M%S).tgz"
archive_remote="/tmp/endebx-test-logs.tgz"
archive_local="$OUTPUT_DIR/$archive_name"

echo "Collecting logs from $(remote_fqdn)"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail

status_dir=$(mktemp -d)
archive_remote="/tmp/endebx-test-logs.tgz"

systemctl --no-pager --full status nginx >"$status_dir/nginx.status" 2>&1 || true
systemctl --no-pager --full status apache2 >"$status_dir/apache2.status" 2>&1 || true
systemctl --no-pager --full status postgresql >"$status_dir/postgresql.status" 2>&1 || true
systemctl --no-pager --full status mariadb >"$status_dir/mariadb.status" 2>&1 || true

tar -czf "$archive_remote" \
  --ignore-failed-read \
  /root/.env.menu \
  /root/endebx-install.log \
  /tmp/endebx-menu-smoke.log \
  /var/log/nginx \
  /var/log/apache2 \
  "$status_dir"
REMOTE

remote_scp_from "$archive_remote" "$archive_local"
echo "Logs saved to $archive_local"

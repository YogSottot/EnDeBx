#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local action=$1

  remote_ssh "tail -n 120 /root/endebx-menu-ftp-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-ftp-${action}.trace || true" >&2 || true
}

run_menu_ftp_action() {
  local action=$1
  local delete_index=${2:-}

  if ! remote_ssh TEST_MENU_FTP_ACTION="$action" TEST_MENU_FTP_DELETE_INDEX="$delete_index" bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_ftp.expect > "/root/endebx-menu-ftp-${TEST_MENU_FTP_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_ftp.expect failed during ${action}; showing recent remote logs" >&2
    show_remote_logs "$action"
    exit 1
  fi
}

echo "Testing menu-managed FTP user create/delete on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_ftp.expect" "/root/EnDeBx/tests/runner/menu_ftp.expect"

echo "Checking that FTP test starts from a clean state"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

test -d "${TEST_MENU_FTP_DIR}"
if pure-pw show "${TEST_MENU_FTP_USER}" >/dev/null 2>&1; then
  echo "FTP test expects a clean stand, but user ${TEST_MENU_FTP_USER} already exists." >&2
  exit 1
fi
REMOTE

echo "Creating FTP user via menu.sh"
run_menu_ftp_action create

echo "Validating created FTP user"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

pure-pw show "${TEST_MENU_FTP_USER}" > /tmp/endebx-ftp-user-show.txt
pure-pw list | awk '{print $1}' | grep -qx "${TEST_MENU_FTP_USER}"
ftp_directory="$(sed -n 's/^Directory[[:space:]]*: //p' /tmp/endebx-ftp-user-show.txt)"
ftp_uid="$(sed -n 's/^UID[[:space:]]*: \([0-9]\+\).*/\1/p' /tmp/endebx-ftp-user-show.txt)"
ftp_gid="$(sed -n 's/^GID[[:space:]]*: \([0-9]\+\).*/\1/p' /tmp/endebx-ftp-user-show.txt)"
test "$ftp_directory" = "${TEST_MENU_FTP_DIR}/./" || test "$ftp_directory" = "${TEST_MENU_FTP_DIR}"
test "$ftp_uid" = "$(id -u "${BS_USER_SERVER_SITES}")"
test "$ftp_gid" = "$(id -u "${BS_USER_SERVER_SITES}")"
test -f /etc/pure-ftpd/pureftpd.pdb
systemctl is-active --quiet pure-ftpd
systemctl is-enabled pure-ftpd | grep -qx enabled
rm -f /tmp/endebx-ftp-user-show.txt
REMOTE

delete_index="$(
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/.env.menu

pure-pw list | awk '{print $1}' | nl -w1 -s: | awk -F: -v target="${TEST_MENU_FTP_USER}" '$2 == target { print $1 }'
REMOTE
)"

if [ -z "$delete_index" ]; then
  echo "Failed to determine FTP delete index for ${TEST_MENU_FTP_USER}" >&2
  exit 1
fi

echo "Deleting FTP user via menu.sh"
run_menu_ftp_action delete "$delete_index"

echo "Validating removed FTP user"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/.env.menu

! pure-pw show "${TEST_MENU_FTP_USER}" >/dev/null 2>&1
! pure-pw list | awk '{print $1}' | grep -qx "${TEST_MENU_FTP_USER}"
REMOTE

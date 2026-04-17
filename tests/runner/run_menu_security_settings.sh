#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  remote_ssh "tail -n 120 /root/endebx-menu-security-settings.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-security-settings.trace || true" >&2 || true
}

echo "Testing menu-managed SSH/Updates security settings on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_security_settings.expect" "/root/EnDeBx/tests/runner/menu_security_settings.expect"

if ! remote_ssh bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_security_settings.expect > /root/endebx-menu-security-settings.log 2>&1
REMOTE
then
  echo "menu_security_settings.expect failed; showing recent remote logs" >&2
  show_remote_logs
  exit 1
fi

echo "Validating applied security settings"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/.env.menu

ssh_hardening_file=/etc/ssh/sshd_config.d/hardening.conf
periodic_file=/etc/apt/apt.conf.d/10periodic
unattended_file=/etc/apt/apt.conf.d/51override-unattended-upgrades

test -f "$ssh_hardening_file"
grep -q "^Port ${BS_SSH_PORT}$" "$ssh_hardening_file"
grep -q "^PermitRootLogin ${BS_SSH_PERMIT_ROOT_LOGIN}$" "$ssh_hardening_file"
grep -q "^PasswordAuthentication ${BS_SSH_PASSWORD_AUTHENTICATION}$" "$ssh_hardening_file"

grep -q '^BS_SETUP_SECURITY="Y"$' /root/.env.menu
grep -q "^BS_SSH_PORT=\"${BS_SSH_PORT}\"$" /root/.env.menu
grep -q "^BS_SSH_PERMIT_ROOT_LOGIN=\"${BS_SSH_PERMIT_ROOT_LOGIN}\"$" /root/.env.menu
grep -q "^BS_SSH_PASSWORD_AUTHENTICATION=\"${BS_SSH_PASSWORD_AUTHENTICATION}\"$" /root/.env.menu
grep -q "^BS_AUTOUPDATE_ENABLED=\"${BS_AUTOUPDATE_ENABLED}\"$" /root/.env.menu
grep -q "^BS_AUTOUPDATE_REBOOT_ENABLE=\"${BS_AUTOUPDATE_REBOOT_ENABLE}\"$" /root/.env.menu
grep -q "^BS_AUTOUPDATE_REBOOT_TIME=\"${BS_AUTOUPDATE_REBOOT_TIME}\"$" /root/.env.menu
grep -q "^BS_SECRITY_HIDEPID=\"${BS_SECRITY_HIDEPID}\"$" /root/.env.menu

if [ "${BS_AUTOUPDATE_ENABLED}" = "true" ]; then
  dpkg-query -W -f='${Status}' unattended-upgrades 2>/dev/null | grep -q 'ok installed'
  test -f "$periodic_file"
  test -f "$unattended_file"
  grep -q 'APT::Periodic::Unattended-Upgrade "1";' "$periodic_file"
  grep -q "Unattended-Upgrade::Automatic-Reboot \"${BS_AUTOUPDATE_REBOOT_ENABLE}\";" "$unattended_file"
  grep -q "Unattended-Upgrade::Automatic-Reboot-Time \"${BS_AUTOUPDATE_REBOOT_TIME}\";" "$unattended_file"
  grep -q "Unattended-Upgrade::Mail \"${BS_EMAIL_ADMIN_FOR_NOTIFY}\";" "$unattended_file"
fi

if [ "${BS_SECRITY_HIDEPID}" = "true" ]; then
  getent group procmon >/dev/null
  grep -q '^proc /proc proc defaults,hidepid=2,gid=procmon,nosuid,nodev,noexec 0 0$' /etc/fstab
  mount | grep ' on /proc ' | grep -Eq 'hidepid=(2|invisible)'

  if [ -n "${BS_SECRITY_HIDEPID_MONITORING_USER}" ]; then
    id -nG "${BS_SECRITY_HIDEPID_MONITORING_USER}" | tr ' ' '\n' | grep -qx procmon
  fi
else
  if grep -q '^proc /proc proc .*hidepid=2' /etc/fstab; then
    exit 1
  fi
fi
REMOTE

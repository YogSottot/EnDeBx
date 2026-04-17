#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  remote_ssh "tail -n 160 /root/endebx-menu-smtp.log || true" >&2 || true
  remote_ssh "tail -n 160 /tmp/endebx-menu-smtp.trace || true" >&2 || true
  remote_ssh "tail -n 80 /var/www/bitrix/msmtp_default.log || true" >&2 || true
}

run_menu_smtp_action() {
  remote_ssh "rm -f /root/endebx-menu-smtp.log /tmp/endebx-menu-smtp.trace"

  if ! remote_ssh \
    EXPECT_DEBUG="${EXPECT_DEBUG:-0}" \
    bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_smtp.expect > /root/endebx-menu-smtp.log 2>&1
REMOTE
  then
    echo "menu_smtp.expect failed; showing recent remote logs" >&2
    show_remote_logs
    exit 1
  fi
}

echo "Testing menu-managed SMTP settings on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_smtp.expect" "/root/EnDeBx/tests/runner/menu_smtp.expect"

echo "Configuring SMTP via menu.sh"
run_menu_smtp_action

echo "Validating configured SMTP account"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

dpkg-query -W -f='${Status}' msmtp 2>/dev/null | grep -q 'ok installed'
test -x "${BS_SMTP_PATH_WRAPP_SCRIPT_SH}"
test -f "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "account ${TEST_MENU_SMTP_ACCOUNT}" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "host ${TEST_MENU_SMTP_HOST}" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "port ${TEST_MENU_SMTP_PORT}" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "from ${TEST_MENU_SMTP_FROM}" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "user ${TEST_MENU_SMTP_LOGIN}" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "password ${TEST_MENU_SMTP_PASSWORD}" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "auth on" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "tls on" "${BS_SMTP_FILE_SITES_CONFIG}"
grep -Fx "tls_starttls on" "${BS_SMTP_FILE_SITES_CONFIG}"
REMOTE

echo "Sending a test message through mail()"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

existing_lines=0
if [ -f "${TEST_MENU_SMTP_LOG_PATH}" ]; then
  existing_lines=$(wc -l < "${TEST_MENU_SMTP_LOG_PATH}")
fi

su -s /bin/bash "${BS_USER_SERVER_SITES}" -c "php -r 'if (!mail(\"${TEST_MENU_SMTP_RECIPIENT}\", \"Test\", \"Test\", \"From: ${TEST_MENU_SMTP_FROM}\")) { fwrite(STDERR, \"mail() returned false\\n\"); exit(1); }'"

current_lines=$existing_lines
for _ in $(seq 1 30); do
  if [ -f "${TEST_MENU_SMTP_LOG_PATH}" ]; then
    current_lines=$(wc -l < "${TEST_MENU_SMTP_LOG_PATH}")
  else
    current_lines=0
  fi

  if [ "$current_lines" -gt "$existing_lines" ]; then
    break
  fi

  sleep 1
done

[ "$current_lines" -gt "$existing_lines" ]
tail -n +"$((existing_lines + 1))" "${TEST_MENU_SMTP_LOG_PATH}" > /tmp/endebx-smtp-log-new.txt
grep -Fq "host=${TEST_MENU_SMTP_HOST}" /tmp/endebx-smtp-log-new.txt
grep -Fq "tls=on" /tmp/endebx-smtp-log-new.txt
grep -Fq "auth=on" /tmp/endebx-smtp-log-new.txt
grep -Fq "user=${TEST_MENU_SMTP_LOGIN}" /tmp/endebx-smtp-log-new.txt
grep -Fq "from=${TEST_MENU_SMTP_FROM}" /tmp/endebx-smtp-log-new.txt
grep -Fq "recipients=${TEST_MENU_SMTP_RECIPIENT}" /tmp/endebx-smtp-log-new.txt
grep -Fq "smtpstatus=250" /tmp/endebx-smtp-log-new.txt
grep -Fq "exitcode=EX_OK" /tmp/endebx-smtp-log-new.txt
tail -n 1 /tmp/endebx-smtp-log-new.txt
rm -f /tmp/endebx-smtp-log-new.txt
REMOTE

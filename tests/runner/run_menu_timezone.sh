#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local label=$1

  remote_ssh "tail -n 120 /root/endebx-menu-timezone-${label}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-timezone-${label}.trace || true" >&2 || true
}

detect_remote_timezone() {
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail

tz=$(timedatectl show -p Timezone --value 2>/dev/null || true)
if [ -z "$tz" ] && [ -f /etc/timezone ]; then
  tz=$(cat /etc/timezone)
fi
if [ -z "$tz" ] && [ -L /etc/localtime ]; then
  tz=$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')
fi

printf '%s\n' "$tz"
REMOTE
}

choose_test_timezone() {
  local current_timezone=$1
  local restore_timezone=$2
  local candidate

  for candidate in UTC Europe/Berlin Europe/Moscow; do
    if [ "$candidate" != "$current_timezone" ] && [ "$candidate" != "$restore_timezone" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if [ "$current_timezone" != "UTC" ]; then
    printf '%s\n' "UTC"
  else
    printf '%s\n' "Europe/Berlin"
  fi
}

run_timezone_action() {
  local label=$1
  local target_timezone=$2

  if ! remote_ssh \
    TEST_MENU_TIMEZONE_LABEL="$label" \
    TEST_MENU_TARGET_TIMEZONE="$target_timezone" \
    bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_timezone.expect > "/root/endebx-menu-timezone-${TEST_MENU_TIMEZONE_LABEL}.log" 2>&1
REMOTE
  then
    echo "menu_timezone.expect failed during ${label}; showing recent remote logs" >&2
    show_remote_logs "$label"
    exit 1
  fi
}

validate_timezone_state() {
  local expected_timezone=$1

  remote_ssh bash -s -- "$expected_timezone" <<'REMOTE'
set -euo pipefail

expected_timezone=$1

current_timezone=$(timedatectl show -p Timezone --value 2>/dev/null || true)
if [ -z "$current_timezone" ] && [ -f /etc/timezone ]; then
  current_timezone=$(cat /etc/timezone)
fi
if [ -z "$current_timezone" ] && [ -L /etc/localtime ]; then
  current_timezone=$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')
fi

[ "$current_timezone" = "$expected_timezone" ]

if [ -f /etc/timezone ]; then
  grep -qx "$expected_timezone" /etc/timezone
fi

grep -q "^BS_SERVER_TIMEZONE=\"${expected_timezone}\"$" /root/.env.menu

php_ini_matches=$(find /etc/php -type f -name bitrixenv.ini 2>/dev/null || true)
if [ -n "$php_ini_matches" ]; then
  while IFS= read -r php_ini_file; do
    [ -n "$php_ini_file" ] || continue
    grep -q "^date.timezone = ${expected_timezone}$" "$php_ini_file"
  done <<< "$php_ini_matches"
fi
REMOTE
}

echo "Testing menu-managed timezone change on $(remote_fqdn)"
original_timezone=$(detect_remote_timezone)
if [ -z "$original_timezone" ]; then
  echo "Could not detect current remote timezone" >&2
  exit 1
fi

configured_timezone=""
if [ -f "$LOCAL_ENV_TEST" ]; then
  # shellcheck source=/dev/null
  source "$LOCAL_ENV_TEST"
  configured_timezone="${BS_SERVER_TIMEZONE:-}"
fi

restore_timezone="${configured_timezone:-$original_timezone}"
alternate_timezone=$(choose_test_timezone "$original_timezone" "$restore_timezone")

echo "Current timezone: $original_timezone"
echo "Restore timezone: $restore_timezone"
echo "Alternate timezone: $alternate_timezone"

generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_timezone.expect" "/root/EnDeBx/tests/runner/menu_timezone.expect"
remote_scp_to "$REPO_ROOT/vm_menu/ansible/playbooks/change_timezone.yaml" "/root/vm_menu/ansible/playbooks/change_timezone.yaml"

echo "Changing timezone to $alternate_timezone"
run_timezone_action alt "$alternate_timezone"
validate_timezone_state "$alternate_timezone"

echo "Restoring timezone to $restore_timezone"
run_timezone_action restore "$restore_timezone"
validate_timezone_state "$restore_timezone"

#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  remote_ssh "tail -n 120 /root/endebx-menu-php-version.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-php-version.trace || true" >&2 || true
}

detect_php_version_info() {
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail

current_default=$(
  update-alternatives --query php \
    | awk '/^Value: / {print $2}' \
    | grep -oP '\d+\.\d+' \
    | head -n1 || true
)

latest_available=$(
  comm -12 \
    <(apt-cache pkgnames | grep -oP '^php\K[0-9]+\.[0-9]+(?=-cli$)' | sort -Vu) \
    <(apt-cache pkgnames | grep -oP '^php\K[0-9]+\.[0-9]+(?=-fpm$)' | sort -Vu) \
    | tail -n1
)

printf 'current=%s\n' "$current_default"
printf 'latest=%s\n' "$latest_available"
REMOTE
}

validate_php_version_state() {
  local target_version=$1

  remote_ssh bash -s -- "$target_version" <<'REMOTE'
set -euo pipefail

target_version=$1

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

package_installed "php${target_version}-cli"
package_installed "php${target_version}-fpm"
command -v "php${target_version}" >/dev/null 2>&1
update-alternatives --query php | awk '/^Value: / {print $2}' | grep -qx "/usr/bin/php${target_version}"
update-alternatives --query php-fpm.sock | awk '/^Value: / {print $2}' | grep -qx "/run/php/php${target_version}-fpm.sock"
[ "$(php -r 'echo PHP_MAJOR_VERSION "." PHP_MINOR_VERSION;')" = "$target_version" ]
test -S "/run/php/php${target_version}-fpm.sock"
systemctl is-active --quiet "php${target_version}-fpm"
find "/etc/php/${target_version}" -type f -name bitrixenv.ini | grep -q .
REMOTE
}

echo "Testing menu-managed global PHP version change on $(remote_fqdn)"

php_version_info=$(detect_php_version_info)
current_default_version=$(printf '%s\n' "$php_version_info" | sed -n 's/^current=//p')
target_version=$(printf '%s\n' "$php_version_info" | sed -n 's/^latest=//p')

if [ -z "$target_version" ]; then
  echo "Could not determine latest available PHP version on remote host" >&2
  exit 1
fi

echo "Current default PHP version: ${current_default_version:-unknown}"
echo "Target PHP version: $target_version"

generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_php_version.expect" "/root/EnDeBx/tests/runner/menu_php_version.expect"
remote_ssh "rm -f /root/endebx-menu-php-version.log /tmp/endebx-menu-php-version.trace"

if ! remote_ssh \
  EXPECT_DEBUG="${EXPECT_DEBUG:-0}" \
  TEST_MENU_PHP_VERSION_TARGET="$target_version" \
  bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_php_version.expect > /root/endebx-menu-php-version.log 2>&1
REMOTE
then
  echo "menu_php_version.expect failed; showing recent remote logs" >&2
  show_remote_logs
  exit 1
fi

echo "Validating applied global PHP version"
validate_php_version_state "$target_version"

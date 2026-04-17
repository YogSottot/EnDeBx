#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

timeout_seconds="${WAIT_TIMEOUT_SECONDS:-600}"
sleep_seconds="${WAIT_SLEEP_SECONDS:-5}"
deadline=$((SECONDS + timeout_seconds))

require_command ssh

echo "Waiting for SSH on $(remote_ip) ..."
while (( SECONDS < deadline )); do
  if remote_ssh true >/dev/null 2>&1; then
    echo "SSH is available on $(remote_ip)"
    exit 0
  fi
  sleep "$sleep_seconds"
done

echo "Timed out waiting for SSH on $(remote_ip)" >&2
exit 1

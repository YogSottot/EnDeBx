#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOFU_DIR="${TOFU_DIR:-$REPO_ROOT/tests/opentofu}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/tests/output}"
LOCAL_ENV_TEST="${LOCAL_ENV_TEST:-$REPO_ROOT/.env.test}"
GENERATED_ENV_MENU="${GENERATED_ENV_MENU:-$OUTPUT_DIR/generated.env.menu}"
SSH_USER="${SSH_USER:-root}"
SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=10
  -o ServerAliveInterval=30
)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

ensure_output_dir() {
  mkdir -p "$OUTPUT_DIR"
}

tofu_output_raw() {
  local output_name=$1

  require_command tofu
  tofu -chdir="$TOFU_DIR" output -raw "$output_name"
}

remote_ip() {
  tofu_output_raw public_ipv4
}

remote_fqdn() {
  tofu_output_raw vm_fqdn
}

remote_name() {
  tofu_output_raw vm_name
}

remote_ssh_target() {
  printf '%s@%s\n' "$SSH_USER" "$(remote_ip)"
}

remote_ssh() {
  local target
  target=$(remote_ssh_target)
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$target" "$@"
}

remote_scp_to() {
  local source_path=$1
  local target_path=$2
  local target

  target=$(remote_ssh_target)
  scp "${SSH_OPTS[@]}" "$source_path" "${target}:${target_path}"
}

remote_scp_from() {
  local source_path=$1
  local target_path=$2
  local target

  target=$(remote_ssh_target)
  scp "${SSH_OPTS[@]}" "${target}:${source_path}" "$target_path"
}

rsync_ssh_command() {
  local arg

  printf 'ssh'
  for arg in "${SSH_OPTS[@]}"; do
    printf ' %q' "$arg"
  done
}

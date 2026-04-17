#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

require_command rsync

target=$(remote_ssh_target)
rsync_ssh=$(rsync_ssh_command)

echo "Uploading repository to ${target}:/root/EnDeBx"
remote_ssh "mkdir -p /root/EnDeBx"
RSYNC_RSH="$rsync_ssh" rsync -az --delete \
  --exclude '.git/' \
  --exclude '.idea/' \
  --exclude '.vscode/' \
  --exclude '.history/' \
  --exclude '.env.test' \
  --exclude 'tests/output/' \
  --exclude 'tests/opentofu/.terraform/' \
  --exclude 'tests/opentofu/*.tfstate' \
  --exclude 'tests/opentofu/*.tfstate.*' \
  "$REPO_ROOT/" "${target}:/root/EnDeBx/"
remote_ssh "rm -rf /root/vm_menu && \
  mv /root/EnDeBx/vm_menu /root/ && \
  chmod -R +x /root/vm_menu"

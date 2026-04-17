#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

echo "Bootstrapping remote host $(remote_ip)"
echo "Adjusting Ubuntu APT sources if needed"
replace_remote_ubuntu_sources_if_needed

remote_ssh bash -s <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y rsync curl ca-certificates expect
REMOTE

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

generated_env_menu=$("$SCRIPT_DIR/render_env.sh")

echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"

echo "Adjusting Ubuntu APT sources if needed"
replace_remote_ubuntu_sources_if_needed

echo "Running install_full_environment_fpm.sh with uploaded /root/vm_menu"
remote_ssh bash -s <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export INSTALLER_DOWNLOAD_VM_MENU=N
bash /root/EnDeBx/install_full_environment_fpm.sh 2>&1 | tee /root/endebx-install.log
REMOTE

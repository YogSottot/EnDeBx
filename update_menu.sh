#!/usr/bin/env bash
set -euo pipefail

# Update menu
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/update_menu.sh)

# use wget
# bash <(wget -qO- https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/update_menu.sh)

BRANCH="feature/php-fpm"
REPO_URL="https://github.com/YogSottot/DebianLikeBitrixVM.git"

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

DEST_DIR_BACKUP_MENU="$DEST_DIR_MENU/backup_vm_menu"

# Backup vm_menu
current_date=$(date "+%d.%m.%Y %H:%M:%S")
full_path_backup_menu="$DEST_DIR_BACKUP_MENU/$current_date"

mkdir -p "${full_path_backup_menu}"
mkdir -p "${DEST_DIR_MENU}/${DIR_NAME_MENU}"
mv -f "${DEST_DIR_MENU}/${DIR_NAME_MENU}" "${full_path_backup_menu}"

# Clone directory vm_menu with repositories
rm -rf "${DEST_DIR_MENU:?}/DebianLikeBitrixVM"
git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianLikeBitrixVM"
cd "$DEST_DIR_MENU/DebianLikeBitrixVM"
git sparse-checkout set $DIR_NAME_MENU

# Move vm_menu in /root and clean
rm -rf "${DEST_DIR_MENU:?}/${DIR_NAME_MENU:?}"
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
cd "$DEST_DIR_MENU"
rm -rf "${DEST_DIR_MENU:?}/DebianLikeBitrixVM"
chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

rm -f "/tmp/configs.tmp"
rm -f "/tmp/new_version_menu.tmp"

ln -sf $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

# update nginx bitrix_general.conf
# shellcheck source=/dev/null
source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

# shellcheck source=/dev/null
if [ -e $DEST_DIR_MENU/.env.menu ]; then
    source $DEST_DIR_MENU/.env.menu
fi

cp -f "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/roles/geerlingguy.nginx_config/files/nginx/bx/conf/bitrix_general.conf" "$BS_PATH_NGINX/conf/bitrix_general.conf"
cp -f "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/roles/geerlingguy.nginx_config/files/nginx/bx/conf_fpm/bitrix_general.conf" "$BS_PATH_NGINX/conf_fpm/bitrix_general.conf"
nginx -t && systemctl reload "$BS_SERVICE_NGINX_NAME.service"

# check ansible installation
# --- remove ansible if installed via apt ---
if dpkg -l | grep -q "^ii  ansible "; then
    echo "Purging system ansible packages (apt)..."
    apt purge -y ansible
    apt autoremove -y
fi

# Make sure pipx itself exists
if ! command -v pipx >/dev/null 2>&1; then
    apt update && apt install -y pipx
    python3 -m pipx ensurepath
fi
if pipx list | grep -q "package ansible "; then
    ANSIBLE_INSTALLED_VERSION=$(pipx list | grep "package ansible " | awk '{print $3}' | tr -d ',')
    if [ "$ANSIBLE_INSTALLED_VERSION" != "$BS_ANSIBLE_REQUIRED_VERSION" ]; then
        echo "Reinstalling ansible $BS_ANSIBLE_REQUIRED_VERSION (found $BS_ANSIBLE_REQUIRED_VERSION)..."
        pipx uninstall ansible
        pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
        pipx inject ansible jmespath passlib
    else
        echo "Ansible $BS_ANSIBLE_REQUIRED_VERSION already installed."
    fi
else
    echo "Installing ansible $BS_ANSIBLE_REQUIRED_VERSION..."
    pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
    pipx inject ansible jmespath passlib
fi

echo -e "\n\n";
echo "Menu updated! Backup directory old menu: $full_path_backup_menu";
echo -e "\n";

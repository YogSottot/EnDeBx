#!/usr/bin/env bash
set +x
set -euo pipefail

# bash <(wget -qO- https://github.com/YogSottot/DebianLikeBitrixVM/blob/feature/php-fpm/repositories/bitrix-gt/security.sh)
apt update -y
apt upgrade -y --enable-upgrade

if dpkg -s ansible >/dev/null 2>&1; then
    echo "Purging system ansible package..."
    apt purge -y ansible
    apt autoremove -y
else
    echo "No apt ansible package installed."
fi

# Make sure pipx itself exists
if ! command -v pipx >/dev/null 2>&1; then
    apt update && apt install -y pipx
    python3 -m pipx ensurepath
fi
if pipx list | grep -q "package ansible "; then
    ANSIBLE_INSTALLED_VERSION=$(pipx list | grep "package ansible " | awk '{print $3}' | tr -d ',')
    if [ "$ANSIBLE_INSTALLED_VERSION" != "$ANSIBLE_REQUIRED_VERSION" ]; then
        echo "Reinstalling ansible $ANSIBLE_REQUIRED_VERSION (found $ANSIBLE_INSTALLED_VERSION)..."
        pipx uninstall ansible
        pipx install --include-deps "ansible==$ANSIBLE_REQUIRED_VERSION"
        pipx inject ansible jmespath passlib
    else
        echo "Ansible $ANSIBLE_REQUIRED_VERSION already installed."
    fi
else
    echo "Installing ansible $ANSIBLE_REQUIRED_VERSION..."
    pipx install --include-deps "ansible==$ANSIBLE_REQUIRED_VERSION"
    pipx inject ansible jmespath passlib
fi

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

cd $DEST_DIR_MENU

# Final actions
# shellcheck source=/dev/null
source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

# shellcheck source=/dev/null
if [ -e /root/.env.menu ]; then
  source /root/.env.menu
fi

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

# setup swap
if [ "$BS_SETUP_SWAP" == 'Y'  ]; then
    ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PS_SWAP}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
    -e "swap_file_state='present' \
    swap_file_size_mb=${BS_SWAP_SIZE}"
fi

if [ "$BS_INSTALL_CROWDSEC" == Y  ]; then
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_CROWDSEC}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e 'crowdsec_action="'"INSTALL"'" \
      cs_parsers_mywhitelists_ip="'"$(echo "${BS_CROWDESC_WHITELIST_IP}" | sed 's/,/"\n- "/g; s/^/- "/; s/$/"/;')"'" \
      cs_collections_list="'"$(echo "${BS_CROWDSEC_COLLECTION_INSTALL}" | sed 's/,/\n  /g; s/^/  /;')"'" \
      cs_scenarios_list="'"$(echo "${BS_CROWDSEC_SCENARIOS_INSTALL}" | sed 's/,/\n  /g; s/^/  /;')"'" \
      crowdsec_enroll_key="'"${BS_CROWDSEC_ENROLL_KEY}"'"'
fi

if [ "$BS_SETUP_RKHUNTER" == Y  ]; then
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_RKHUNTER}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "rkhunter_action='INSTALL' \
      rkhunter_notification_email=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      rkhunter_ssh_permit_root_login=${BS_SSH_PERMIT_ROOT_LOGIN}"
fi

if [ "$BS_SETUP_MALDET" == Y  ]; then
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_MALDET}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "maldet_action='INSTALL' \
      maldet_email_addr=${BS_EMAIL_ADMIN_FOR_NOTIFY}"
fi

if [ "$BS_SETUP_SECURITY" == "Y" ]; then
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SECURITY}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "security_ssh_port=${BS_SSH_PORT} \
      security_ssh_password_authentication=${BS_SSH_PASSWORD_AUTHENTICATION} \
      security_ssh_permit_root_login=${BS_SSH_PERMIT_ROOT_LOGIN} \
      security_sudoers_passwordless=${BS_SSH_ADMIN_USER} \
      security_autoupdate_enabled=${BS_AUTOUPDATE_ENABLED} \
      security_sudoers_passwordless_ssh_key=\"${BS_SSH_ADMIN_USER_SSH_KEY}\" \
      security_autoupdate_reboot=${BS_AUTOUPDATE_REBOOT_ENABLE} \
      security_autoupdate_reboot_time=${BS_AUTOUPDATE_REBOOT_TIME} \
      security_autoupdate_mail_to=${BS_EMAIL_ADMIN_FOR_NOTIFY}"
fi

if [ "$BS_HTACCESS_SUPPORT" == N ]; then
  systemctl stop apache2.service
  systemctl disable apache2.service
else
  systemctl restart apache2.service
fi

if [ "$BS_PUSH_SERVER_STOPPED" == Y  ]; then
  systemctl stop push-server.service
  systemctl disable push-server.service
  systemctl stop redis-server.service
  systemctl disable redis-server.service
else
  systemctl restart push-server.service
  systemctl restart redis-server.service
fi

if [ -n "${BX_ADDITIONAL_PACKAGES}" ]; then
  for package in ${BX_ADDITIONAL_PACKAGES}; do
    apt -y install "$package"
  done
fi

echo -e "\n\n";
echo "Menu updated! Backup directory old menu: $full_path_backup_menu";
echo -e "\n";

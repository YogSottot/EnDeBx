#!/usr/bin/env bash
set +x
set -euo pipefail

# bash <(wget -qO- https://github.com/YogSottot/DebianLikeBitrixVM/blob/feature/php-fpm/repositories/bitrix-gt/security.sh)

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

if [ "$BS_HTACCESS_SUPPORT" == N  ]; then
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

apt update -y
apt upgrade -y --enable-upgrade

# update menu to latest version
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
mv -f "${DEST_DIR_MENU}/${DIR_NAME_MENU}" "${full_path_backup_menu}"


# Clone directory vm_menu with repositories
git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianLikeBitrixVM"
cd "$DEST_DIR_MENU/DebianLikeBitrixVM"
git sparse-checkout set $DIR_NAME_MENU

# Move vm_menu in /root and clean
rm -rf "${DEST_DIR_MENU:?}/${DIR_NAME_MENU:?}"
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
rm -rf "${DEST_DIR_MENU:?}/DebianLikeBitrixVM"

chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

rm -f "/tmp/configs.tmp"
rm -f "/tmp/new_version_menu.tmp"

ln -sf $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

echo -e "\n\n";
echo "Menu updated! Backup directory old menu: $full_path_backup_menu";
echo -e "\n";

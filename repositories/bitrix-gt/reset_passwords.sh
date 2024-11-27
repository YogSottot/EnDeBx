#!/usr/bin/env bash
set +x
set -euo pipefail


generate_password() {
    local length=$1
    local specials='!@#$%^&*()-_=+[]|;:,.<>?/~'
    local all_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789${specials}"

    local password=""
    for i in $(seq 1 $length); do
        local char=${all_chars:RANDOM % ${#all_chars}:1}
        password+=$char
    done

    echo "$password"
}

DB_NAME="bitrix"
DB_USER="bitrix"
DBPASS=$(generate_password 24)

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

site_user_password=$(generate_password 24)

cd $DEST_DIR_MENU

# shellcheck source=/dev/null
source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

# shellcheck source=/dev/null
if [ -e /root/.env.menu ]; then
  source /root/.env.menu
fi

# set timezone
timedatectl set-timezone "${BS_SERVER_TIMEZONE}"

DOCUMENT_ROOT="${BS_PATH_DEFAULT_SITE}"

ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PS_RESET_PASSWORDS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "domain=${BS_DEFAULT_SITE_NAME} \
  default_domain=${BS_DEFAULT_SITE_NAME} \

  db_name=${DB_NAME} \
  db_user=${DB_USER} \
  db_password=${DBPASS} \
  mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  mysql_collation_server=${BS_DB_COLLATION} \
  mysql_flavor=${BS_DB_FLAVOR} \
  mysql_version=${BS_DB_VERSION} \
  
  site_user_password=${site_user_password} \

  path_sites=${BS_PATH_SITES} \
  document_root=${DOCUMENT_ROOT} \
  default_site_name=${BS_DEFAULT_SITE_NAME} \

  delete_files=$(IFS=,; echo "${DELETE_FILES[*]}") \

  download_bitrix_install_files_new_site=$(IFS=,; echo "${BS_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE[*]}") \
  timeout_download_bitrix_install_files_new_site=${BS_TIMEOUT_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE} \

  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \

  permissions_sites_dirs=${BS_PERMISSIONS_SITES_DIRS} \
  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \

  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  path_nginx=${BS_PATH_NGINX} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_nginx_sites_enabled=${BS_PATH_NGINX_SITES_ENABLED} \
  htaccess_support=${BS_HTACCESS_SUPPORT} \

  service_apache_name=${BS_SERVICE_APACHE_NAME} \
  path_apache=${BS_PATH_APACHE} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \

  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \

  bx_cron_agents_path_file_after_document_root=${BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT} \
  bx_cron_logs_path_dir=${BS_BX_CRON_LOGS_PATH_DIR} \
  bx_cron_logs_path_file=${BS_BX_CRON_LOGS_PATH_FILE} \

  push_server_config=${BS_PUSH_SERVER_CONFIG} \
  push_server_bx_settings=${BS_PUSH_SERVER_BX_SETTINGS} \

  php_version=${BX_PHP_DEFAULT_VERSION} \
  php_current_default_version=${BX_PHP_DEFAULT_VERSION} \
  php_enable_php_fpm_xdebug=false \
  php_default_version_debian=${BX_PHP_DEFAULT_VERSION} \
  php_force_install='true' \
  server_timezone=${BS_SERVER_TIMEZONE}"

if [ "$BS_PUSH_SERVER_STOPPED" == Y  ]; then
  systemctl stop push-server.service
  systemctl disable push-server.service
  systemctl stop redis-server.service
  systemctl disable redis-server.service
else
  systemctl restart push-server.service
  systemctl restart redis-server.service
fi

echo "Password for the user ${BS_USER_SERVER_SITES}:" > /root/passwords.txt;
echo "${site_user_password}" >> /root/passwords.txt;

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

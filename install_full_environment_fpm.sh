#!/usr/bin/env bash
set -euo pipefail
# Install full environment
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/install_full_environment_fpm.sh)

# use wget
# apt install wget -y
# wget https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/.env.menu.example -O /root/.env.menu
# edit .env.menu with your settings.
# bash <(wget -qO- https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/install_full_environment_fpm.sh)

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

BRANCH="feature/php-fpm"
REPO_URL="https://github.com/YogSottot/DebianLikeBitrixVM"

DB_NAME="bitrix"
DB_USER="bitrix"
DBPASS=$(generate_password 24)

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

apt update -y
apt upgrade -y --enable-upgrade
apt install -y pipx git locales-all python3-debian

if [ -f /etc/debian_version ]; then
    ver=$(cut -d. -f1 /etc/debian_version)
    if [ "$ver" -ge 13 ]; then
        systemctl mask tmp.mount
    fi
fi

site_user_password=$(generate_password 24)

# Clone directory vm_menu with repositories
git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianLikeBitrixVM"
cd "$DEST_DIR_MENU/DebianLikeBitrixVM"
git sparse-checkout set $DIR_NAME_MENU

# Move vm_menu in /root and clean
rm -rf "${DEST_DIR_MENU:?}/${DIR_NAME_MENU:?}"
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
rm -rf "${DEST_DIR_MENU:?}/DebianLikeBitrixVM"

cd $DEST_DIR_MENU

chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

ln -fs $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

# Final actions
# shellcheck source=/dev/null
source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

# shellcheck source=/dev/null
if [ -e $DEST_DIR_MENU/.env.menu ]; then
  source $DEST_DIR_MENU/.env.menu
fi

# https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html
BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

# check ansible installation
if pipx list | grep -q "package ansible "; then
    ANSIBLE_INSTALLED_VERSION=$(pipx list | grep "package ansible " | awk '{print $3}' | tr -d ',')
    if [ "$ANSIBLE_INSTALLED_VERSION" != "$BS_ANSIBLE_REQUIRED_VERSION" ]; then
        echo "Reinstalling ansible $BS_ANSIBLE_REQUIRED_VERSION (found $ANSIBLE_INSTALLED_VERSION)..."
        pipx uninstall ansible
        pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
        pipx inject ansible jmespath passlib python-debian
    else
        echo "Ansible $BS_ANSIBLE_REQUIRED_VERSION already installed."
    fi
else
    echo "Installing ansible $BS_ANSIBLE_REQUIRED_VERSION..."
    pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
    pipx inject ansible jmespath passlib python-debian
fi

if [ "${BS_HTACCESS_SUPPORT}" == Y ]; then
  htaccess_support=1
else
  htaccess_support=0
fi

if [ "${BS_ADD_MENU_IN_BASH_PROFILE}" == 'Y' ]; then
    # Check script in .profile and add to .profile if not exist
    if ! grep -qF "$FULL_PATH_MENU_FILE" /root/.profile; then
      cat << INSTALL_MENU >> /root/.profile

if [ -n "\$SSH_CONNECTION" ]; then
    $FULL_PATH_MENU_FILE
fi

INSTALL_MENU
    fi
fi

# set timezone
timedatectl set-timezone "${BS_SERVER_TIMEZONE}"

DOCUMENT_ROOT="${BS_PATH_DEFAULT_SITE}"

# setup swap
if [ "$BS_SETUP_SWAP" == 'Y'  ]; then
    ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PS_SWAP}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
    -e "swap_file_state='present' \
    swap_file_size_mb=${BS_SWAP_SIZE}"
fi

if [ "$BS_SETUP_REPOS" == 'Y'  ]; then
# setup repos
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_REPOS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"
fi

# install deps
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_DEPS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

if [ "$BS_USER_SERVER_SITES" != 'www-data' ]; then
    if ! id "$BS_PATH_USER_HOME" &>/dev/null; then
        useradd --user-group --create-home --home-dir "$BS_PATH_USER_HOME_PREFIX/$BS_PATH_USER_HOME" --shell /usr/bin/bash "$BS_PATH_USER_HOME"
        chmod 775 "$BS_PATH_USER_HOME_PREFIX/$BS_PATH_USER_HOME"
    else
        echo "User $BS_PATH_USER_HOME already exists. Skipping user creation."
    fi
fi

if [ "$BS_INSTALL_BASH_ALIASES" == Y  ]; then
  # setup bashrc
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_BASHRC}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
    -e "user_server_sites=${BS_USER_SERVER_SITES} \
    group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
    default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \
    path_sites=${BS_PATH_SITES} "
fi

if [ "$BS_OPTIMIZE_SYSCTL" == Y  ]; then
  # setup sysctl
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SYSCTL}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"
fi

# setup postfix
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_POSTFIX}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# setup user / nginx / mysql / apache2 / firewalld / php-fpm
extra_vars="domain=${BS_DEFAULT_SITE_NAME} \
  default_domain=${BS_DEFAULT_SITE_NAME} \
  db_name=${DB_NAME} \
  db_user=${DB_USER} \
  db_password=${DBPASS} \
  mysql_flavor=${BS_DB_FLAVOR} \
  mysql_version=${BS_DB_VERSION} \
  mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  mysql_collation_server=${BS_DB_COLLATION} \
  site_user_password=${site_user_password} \
  path_sites=${BS_PATH_SITES} \
  document_root=${DOCUMENT_ROOT} \
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
  htaccess_support=${htaccess_support} \
  service_apache_name=${BS_SERVICE_APACHE_NAME} \
  path_apache=${BS_PATH_APACHE} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \
  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \
  bx_cron_agents_path_file_after_document_root=${BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT} \
  bx_cron_logs_path_dir=${BS_BX_CRON_LOGS_PATH_DIR} \
  bx_cron_logs_path_file=${BS_BX_CRON_LOGS_PATH_FILE} \
  push_server_config=${BS_PUSH_SERVER_CONFIG} \
  php_version=${BX_PHP_DEFAULT_VERSION} \
  php_enable_php_fpm_xdebug=false \
  php_default_version_debian=${BX_PHP_DEFAULT_VERSION} \
  php_current_default_version=${BX_PHP_DEFAULT_VERSION} \
  php_force_install='true' \
  server_timezone=${BS_SERVER_TIMEZONE}"

if [ -n "${BX_ADDITIONAL_PHP_EXTENSIONS}" ]; then
  cat > /tmp/php_extra.yml <<EOF
php_packages_extra: ${BX_ADDITIONAL_PHP_EXTENSIONS}
EOF
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INITIAL_SETUP}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" -e "${extra_vars}" -e @/tmp/php_extra.yml
else
  ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INITIAL_SETUP}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" -e "${extra_vars}"
fi

# setup nginx modules repo
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_NGINX_MOD_REPO}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# setup mydumper repo
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_MYDUMPER_REPO}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# SMTP
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "is_new_install_env=Y \
  account_name='' \
  smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
  smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
  smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
  smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
  smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
  smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG} \
  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH}"

# Full enviroment
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_NEW_FULL_ENVIRONMENT}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "domain=${BS_DEFAULT_SITE_NAME} \
  default_domain=${BS_DEFAULT_SITE_NAME} \

  db_name=${DB_NAME} \
  db_user=${DB_USER} \
  db_password=${DBPASS} \
  mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  mysql_collation_server=${BS_DB_COLLATION} \

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
  htaccess_support=${htaccess_support} \

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
  php_current_default_version=${BX_PHP_DEFAULT_VERSION} \
  server_timezone=${BS_SERVER_TIMEZONE}"

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
      maldet_email_addr=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      maldet_home_prefix=${BS_PATH_USER_HOME_PREFIX}"
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

# disable httpd access logs
find /etc/apache2/ -type f -print0 | xargs -0 sed -i 's/CustomLog/#CustomLog/g'

if [ "$BS_HTACCESS_SUPPORT" == N ]; then
  systemctl stop apache2.service
  systemctl disable apache2.service
  systemctl stop apache-htcacheclean.service
  systemctl disable apache-htcacheclean.service
else
  systemctl restart apache2.service
fi

# fix cloudflare ip detection
wget https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/${BRANCH}/repositories/bitrix-gt/cloudflare_ip_updater.sh -N -P /etc/cron.monthly/
chmod +x /etc/cron.monthly/cloudflare_ip_updater.sh
/etc/cron.monthly/cloudflare_ip_updater.sh

# fix services
systemctl restart php"${BX_PHP_DEFAULT_VERSION}"-fpm.service
systemctl try-restart postfix.service
systemctl try-restart postfix@-.service
firewall-cmd --reload

# fix journald sizes
sed -i -e 's/#SystemMaxUse=/SystemMaxUse=100M/g' /etc/systemd/journald.conf
sed -i -e 's/#RuntimeMaxUse=/RuntimeMaxUse=100M/g' /etc/systemd/journald.conf
systemctl restart systemd-journald

# remove compilers
apt remove build-essential gcc gcc-12 -y
apt autoremove -y

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
echo "Full environment installed";
echo -e "\n";
echo "Password for the user ${BS_USER_SERVER_SITES}:";
echo "${site_user_password}";
echo -e "\n";

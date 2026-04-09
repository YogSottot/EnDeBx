#!/bin/bash
# shellcheck disable=SC2034

export ANSIBLE_CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ansible.cfg"

# General configs
BS_VERSION_MENU="1.3.12"
BS_ANSIBLE_REQUIRED_VERSION="11.9.0"
BS_PATH_USER_HOME_PREFIX="/var/www"
BS_PATH_USER_HOME="html"
BS_PATH_SITES="$BS_PATH_USER_HOME_PREFIX/$BS_PATH_USER_HOME"
BS_DEFAULT_SITE_NAME="bx-site"
BS_PATH_DEFAULT_SITE="$BS_PATH_SITES/$BS_DEFAULT_SITE_NAME"
BS_USER_SERVER_SITES="www-data"
BS_GROUP_USER_SERVER_SITES="www-data"
BS_DEFAULT_USER_SERVER_SITES="www-data"
BS_PERMISSIONS_SITES_DIRS="0775"
BS_PERMISSIONS_SITES_FILES="0664"
BS_EXCLUDED_DIRS_SITES=(".bx_temp" "temp" "tmp" "test" ".ssh" "bitrixenv_error")
BS_SITE_LINKS_RESOURCES=("local" "bitrix" "upload" "images")
BS_SERVER_TIMEZONE="Europe/Moscow"
BS_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE=(
  "https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php"
  "https://www.1c-bitrix.ru/download/scripts/restore.php"
)
BS_TIMEOUT_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE=30
BS_SHOW_IP_CURRENT_SERVER_IN_MENU=true

# Bitrix agents configs
BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT="/bitrix/modules/main/tools/cron_events.php"
BS_BX_CRON_LOGS_PATH_DIR="/var/log/bitrix_cron_agents"
BS_BX_CRON_LOGS_PATH_FILE="agents_cron.log"

# PHP configs (VER#0.0 - it will be automatically replaced when the version is selected)
BX_PHP_DEFAULT_VERSION="8.4"
BS_PHP_INSTALL_TEMPLATE=(
  "phpVER#0.0"
  "phpVER#0.0-bcmath"
  "phpVER#0.0-cli"
  "phpVER#0.0-common"
  "phpVER#0.0-gd"
  "phpVER#0.0-fpm"
  "phpVER#0.0-imap"
  "phpVER#0.0-imagick"
  "phpVER#0.0-intl"
  "phpVER#0.0-ldap"
  "phpVER#0.0-mbstring"
  "phpVER#0.0-mysql"
  "phpVER#0.0-opcache"
  "phpVER#0.0-curl"
  "php-pear"
  "phpVER#0.0-apcu"
  "php-geoip"
  "phpVER#0.0-mcrypt"
  "phpVER#0.0-memcache"
  "phpVER#0.0-zip"
  "phpVER#0.0-pspell"
  "phpVER#0.0-soap"
  "phpVER#0.0-sqlite3"
  "phpVER#0.0-xml"
  "phpVER#0.0-xmlrpc"
  "php-redis"
)

BS_DOWNLOAD_BITRIX_CONFIGS="https://dev.1c-bitrix.ru/docs/chm_files/debian.zip"

# Ansible configs
BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS="-i localhost, -c local"
BS_ANSIBLE_DEBUG_MODE=N
BS_PATH_ANSIBLE_PLAYBOOKS="../ansible/playbooks"

# Ansible playbooks names
BS_ANSIBLE_PB_CREATE_SITE="create_site.yaml"
BS_ANSIBLE_PB_GET_LETS_ENCRYPT_CERTIFICATE="get_lets_encrypt_certificate.yaml"
BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS="enable_or_disable_redirect_http_to_https.yaml"
BS_ANSIBLE_PB_INSTALL_NEW_FULL_ENVIRONMENT="install_new_full_environment_fpm.yaml"
BS_ANSIBLE_PB_SETTINGS_SMTP_SITES="settings_smtp_sites.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_NETDATA="install_or_delete_netdata.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_SPHINX="install_or_delete_sphinx.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_FILE_CONVERSION_SERVER="install_or_delete_file_conversion_server.yaml"
BS_ANSIBLE_PB_DELETE_SITE="delete_site.yaml"
BS_ANSIBLE_PB_ADD_PHP_VERSIONS="add_php_version.yaml"
BS_ANSIBLE_PB_INSTALL_DEPS="install_deps.yaml"
BS_ANSIBLE_PB_INITIAL_SETUP="initial_setup.yaml"
BS_ANSIBLE_PB_SETUP_REPOS="setup_repos.yaml"
BS_ANSIBLE_PB_SETUP_BASHRC="setup_bashrc.yaml"
BS_ANSIBLE_PB_SETUP_POSTFIX="setup_postfix.yaml"
BS_ANSIBLE_PB_EDIT_SITE="edit_site.yaml"
BS_ANSIBLE_PB_NGINX_MOD_REPO="setup_nginx_modules_repo.yaml"
BS_ANSIBLE_PB_SYSCTL="setup_sysctl.yaml"
BS_ANSIBLE_PB_CROWDSEC="install_or_delete_crowdsec.yaml"
BS_ANSIBLE_PB_SECURITY="setup_security.yaml"
BS_ANSIBLE_PB_FTP="install_or_delete_ftpuser.yaml"
BS_ANSIBLE_PB_MYDUMPER_REPO="setup_mydumper_repo.yaml"
BS_ANSIBLE_PB_RKHUNTER="install_or_delete_rkhunter.yaml"
BS_ANSIBLE_PB_MALDET="install_or_delete_maldet.yaml"
BS_ANSIBLE_PB_AIDE="install_or_delete_aide.yaml"
BS_ANSIBLE_PB_MEMCACHED="install_or_delete_memcached.yaml"
BS_ANSIBLE_PB_DEADSNAKES_PPA="setup_deadsnakes_ppa.yaml"
BS_ANSIBLE_PB_DOCKER="install_or_delete_docker.yaml"
BS_ANSIBLE_PB_PUSH_SERVER="install_or_delete_push_server.yaml"
BS_ANSIBLE_PS_BASIC_AUTH="setup_basic_auth.yaml"
BS_ANSIBLE_PS_SWAP="setup_swap.yaml"
BS_ANSIBLE_PS_POSTGRESQL_SETUP="install_or_delete_postgresql.yaml"
BS_ANSIBLE_PS_POSTGRESQL_UPGRADE="upgrade_postgresql.yaml"
BS_ANSIBLE_PS_PGBOUNCER="install_or_delete_pgbouncer.yaml"
BS_ANSIBLE_PS_BOTBLOCKER="enable_or_disable_nginx_ultimate_bot_blocker.yaml"
BS_ANSIBLE_PS_SETUP_DEBIAN_REPO_ON_ASTRA="setup_tmp_debian_repositories_for_astra.yaml"
BS_ANSIBLE_PS_RESET_PASSWORDS="reset_passwords.yaml"
BS_ANSIBLE_PS_MYSQL_SETUP="install_or_delete_mysql.yaml"
BS_ANSIBLE_PS_RECONFIGURE_MYSQL_CONFIG="mysql_reconfigure_config.yaml"
BS_ANSIBLE_PS_MYSQL_UPGRADE_57_80="upgrade_mysql_from57_to80.yaml"
BS_ANSIBLE_PS_MYSQL_UPGRADE_80_84="upgrade_mysql_from80_to84.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_SNAPD="install_or_delete_snapd.yaml"
BS_ANSIBLE_PB_CHANGE_TIMEZONE="change_timezone.yaml"
BS_ANSIBLE_PB_FIREWALL="firewall.yaml"
BS_ANSIBLE_PB_NTLM_AUTH="configure_ntlm_auth.yaml"

# Data Base
BS_MAX_CHAR_DB_NAME=20
BS_MAX_CHAR_DB_USER=20
BS_CHAR_DB_PASSWORD=24
# Primary database for initial installation (mysql / pgsql)
BS_INSTALL_DATABASE=mysql
# (mariadb / percona)
BS_DB_FLAVOR=mariadb
# percona version (5.7 / 8.0 / 8.4)
# mariadb version (5.5 / 10.11)
BS_DB_VERSION=10.11
BS_DB_CHARACTER_SET_SERVER=utf8mb4
BS_DB_COLLATION=utf8mb4_unicode_ci
# PostgreSQL repository source for installation (distro / official)
BS_POSTGRESQL_REPOSITORY_SOURCE=distro
# PostgreSQL version for installation from the official repository
BS_POSTGRESQL_VERSION=17
# Install pgbouncer together with PostgreSQL during initial setup (Y / N)
BS_INSTALL_PGBOUNCER=N

# NGINX configs
BS_SERVICE_NGINX_NAME="nginx"
BS_PATH_NGINX="/etc/${BS_SERVICE_NGINX_NAME}/bx/"
BS_PATH_NGINX_SITES_CONF="$BS_PATH_NGINX/site_avaliable"
BS_PATH_NGINX_SITES_ENABLED="$BS_PATH_NGINX/site_enabled"
# Set Y/N
# Y — nginx + apache + php-fpm
# N — nginx + php-fpm
BS_HTACCESS_SUPPORT="Y"
BS_NGINX_BASIC_AUTH_LOGIN=
BS_NGINX_BASIC_AUTH_PASSWORD=

# Apache configs
BS_SERVICE_APACHE_NAME="apache2"
BS_PATH_APACHE="/etc/${BS_SERVICE_APACHE_NAME}"
BS_PATH_APACHE_SITES_CONF="$BS_PATH_APACHE/sites-available"
BS_PATH_APACHE_SITES_ENABLED="$BS_PATH_APACHE/sites-enabled"
BS_NTLM_HTTP_PORT="8890"
BS_NTLM_HTTPS_PORT="8891"

# Emulation Bitrix VM configs
BS_VAR_NAME_BVM="BITRIX_VA_VER"
BS_VAR_VALUE_BVM="9999.99.99"
BS_VAR_PATH_FILE_BVM="/etc/apache2/envvars"

# SMTP configs
BS_SMTP_FILE_SITES_CONFIG="/etc/msmtprc"
BS_SMTP_FILE_USER_CONFIG="${BS_USER_SERVER_SITES}"
BS_SMTP_FILE_GROUP_USER_CONFIG="${BS_GROUP_USER_SERVER_SITES}"
BS_SMTP_FILE_PERMISSIONS_CONFIG="0644"
BS_SMTP_FILE_USER_LOG="${BS_USER_SERVER_SITES}"
BS_SMTP_FILE_GROUP_USER_LOG="${BS_GROUP_USER_SERVER_SITES}"
BS_SMTP_PATH_WRAPP_SCRIPT_SH="/usr/local/bin/msmtp_wrapper.sh"

# Check new version menu
BS_BRANCH_UPDATE_MENU="main"
BS_REPOSITORY_URL_FILE_VERSION="https://raw.githubusercontent.com/YogSottot/EnDeBx/${BS_BRANCH_UPDATE_MENU}/vm_menu/bash_scripts/config.sh"
BS_URL_SCRIPT_UPDATE_MENU="https://raw.githubusercontent.com/YogSottot/EnDeBx/${BS_BRANCH_UPDATE_MENU}/update_menu.sh"
BS_REPOSITORY_URL="https://github.com/YogSottot/EnDeBx/"
BS_CHECK_UPDATE_MENU_MINUTES=1440

# Mysql binary name
BS_MYSQL_CMD="mysql"

# Push-server configs
BS_PUSH_SERVER_CONFIG=/etc/default/push-server-multi
# Install push-server and redis during full environment installation (Y/N)
BS_INSTALL_PUSH_SERVER=Y
# Do not run push-server by default (Y/N)
BS_PUSH_SERVER_STOPPED=N
# Add to /bitrix/.settings.php config local push-server (Y/N).
BS_PUSH_SERVER_BX_SETTINGS=Y
# Email for let's encrypt and others (rkhunter / maldet / aide / imunify360 / etc)
BS_EMAIL_ADMIN_FOR_NOTIFY=""

# Install bash_aliases и liquidprompt
BS_INSTALL_BASH_ALIASES=N
# Apply syctl / ulimits settings (Y/N)
BS_OPTIMIZE_SYSCTL=N

# Install crowdsec by default
BS_INSTALL_CROWDSEC=N
# Install crowdsec AppSec by default
BS_INSTALL_CROWDSEC_APPSEC=N
# Whitelist bitrix voximplant address
# https://voximplant.kz/kit/docs/basicconcepts/kit_ip_addresses
# https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=48&LESSON_ID=5017&LESSON_PATH=3918.4635.2699.5017
BS_CROWDESC_WHITELIST_IP=3.23.109.173,3.123.246.217,5.252.32.21,13.48.50.139,13.55.250.61,15.237.38.34,18.116.210.223,18.140.111.54,18.198.159.51,18.229.108.9,34.240.122.254,46.137.35.188,46.137.97.175,46.137.123.236,46.137.125.240,46.235.53.93,51.68.148.57,51.68.148.60,51.81.71.17,51.81.71.22,51.250.14.66,51.250.25.139,52.17.35.151,54.232.199.60,69.167.178.6,69.167.178.14,79.127.208.225,79.127.208.226,79.127.235.65,79.127.235.66,79.127.235.69,89.187.182.220,89.219.34.163,93.183.85.50,93.183.85.100,94.139.247.5,95.213.198.99,108.177.136.4,109.61.92.225,109.61.92.227,138.199.36.35,138.199.36.36,143.244.45.161,143.244.45.162,143.244.45.166,148.113.0.31,148.113.0.32,152.228.247.214,158.160.117.236,176.34.103.175,176.98.235.18,176.123.176.243,185.71.64.217,185.116.195.27,185.116.195.28,185.164.148.1,185.164.149.11,185.164.149.13,185.164.149.15,185.164.149.17,185.164.149.19,185.164.149.21,185.164.149.26,185.164.149.28,185.164.149.31,185.164.149.100,185.164.150.3,185.164.150.5,185.164.150.7,185.164.150.8,185.164.150.10,188.0.150.130,188.241.216.130,193.84.88.130,195.208.184.173,217.28.226.16
BS_CROWDESC_WHITELIST_CIDR=51.68.148.58/31,51.81.71.18/31,51.81.71.20/31,108.177.136.0/30,109.61.92.228/30,129.227.94.146/31,129.227.121.194/31,152.228.247.212/31,158.160.135.48/30,158.160.135.52/31,185.164.148.128/29,185.164.148.136/31,185.164.149.34/31,185.164.150.12/30,185.164.150.16/31

# Set your key for connect to cloud console (optional)
BS_CROWDSEC_ENROLL_KEY=
# crowdsec collection list, comma separated
BS_CROWDSEC_COLLECTION_INSTALL=crowdsecurity/mariadb,crowdsecurity/whitelist-good-actors,crowdsecurity/http-cve,crowdsecurity/iptables
BS_CROWDSEC_SCENARIOS_INSTALL=crowdsecurity/apache_log4j2_cve-2021-44228,crowdsecurity/http-cve-2021-42013

# Setup Security by default (change ssh-port, disable root login, disable password auth, etc)
BS_SETUP_SECURITY=N
# Change ssh-port
BS_SSH_PORT=22
#  Allow root login (if you set "no", be sure to specify the creation of an alternate user, otherwise you will not be able to log in to the server) ("yes"/"no"/"prohibit-password")
BS_SSH_PERMIT_ROOT_LOGIN="yes"
# Specify an alternate user to log in to the server with sudo privileges
BS_SSH_ADMIN_USER=
# Use passwordless sudo for alternate admin user ("true"/"false")
BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO="true"
# Password for alternate admin user when sudo requires password
BS_SSH_ADMIN_USER_PASSWORD=""
# Specify the ssh key for the alternate user (in single quotes. Multiple keys can be used on a new line))
BS_SSH_ADMIN_USER_SSH_KEY=
# Enable/Disable login by password ('yes'/'no')
BS_SSH_PASSWORD_AUTHENTICATION="yes"
# Enable auto-installation of security updates ('true'/'false'
BS_AUTOUPDATE_ENABLED="true"
# Enable auto reboot of the server if required after installing updates ("true"/"false")
BS_AUTOUPDATE_REBOOT_ENABLE="false"
# Specify time for auto reboot
BS_AUTOUPDATE_REBOOT_TIME="05:00"
# Hide processes of other users in /proc ("true"/"false")
BS_SECRITY_HIDEPID="false"
# Existing monitoring user that should keep access to /proc
BS_SECRITY_HIDEPID_MONITORING_USER=""

# Setup rkhunter by default (Y/N)
BS_SETUP_RKHUNTER=N

# Setup maldet by default (Y/N)
BS_SETUP_MALDET=N
# Enable maldet monitoring service by default during installation (Y/N)
BS_SETUP_MALDET_MONITORING_SERVICE=N

# Setup swap (Y/N)
BS_SETUP_SWAP=N
# Swap size in MB
BS_SWAP_SIZE=1024

# Add menu in autostart when connect to ssh (Y/N)
BS_ADD_MENU_IN_BASH_PROFILE=Y

# Add your packages in format "package1 package2 package3"
BX_ADDITIONAL_PACKAGES=

# Add your own additional php extension packages, they will be added including when php version changes in the menu
# in format: '["php{{ php_version }}-zmq", "php{{ php_version }}-redis"]'
BX_ADDITIONAL_PHP_EXTENSIONS=

# Setup debian repo by default (Y/N)
BS_SETUP_REPOS=N

# Delete snapd
BS_DELETE_SNAPD=Y=N

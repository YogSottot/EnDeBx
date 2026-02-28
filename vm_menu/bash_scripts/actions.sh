#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

action_create_site(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_CREATE_SITE}")

  pb_redirect_http_to_https=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "domain=${domain} \
  default_domain=${BS_DEFAULT_SITE_NAME} \

  mode=${mode} \

  db_name=${db_name} \
  db_user=${db_user} \
  db_password=${db_password} \
  mysql_flavor=${BS_DB_FLAVOR} \
  mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  mysql_collation_server=${BS_DB_COLLATION} \

  path_site_from_links=${path_site_from_links} \
  ssl_lets_encrypt=${ssl_lets_encrypt} \
  ssl_lets_encrypt_www=${ssl_lets_encrypt_www} \
  ssl_lets_encrypt_email=${ssl_lets_encrypt_email} \
  redirect_to_https=${redirect_to_https} \

  path_sites=${BS_PATH_SITES} \

  default_full_path_site=${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME} \

  site_links_resources=$(IFS=,; echo "${BS_SITE_LINKS_RESOURCES[*]}") \
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
  htaccess_support=$((htaccess_support == 1)) \

  service_apache_name=${BS_SERVICE_APACHE_NAME} \
  path_apache=${BS_PATH_APACHE} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \

  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \

  bx_cron_agents_path_file_after_document_root=${BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT} \
  bx_cron_logs_path_dir=${BS_BX_CRON_LOGS_PATH_DIR} \
  bx_cron_logs_path_file=${BS_BX_CRON_LOGS_PATH_FILE} \

  push_server_config=${BS_PUSH_SERVER_CONFIG} \
  push_server_bx_settings=${push_server_bx_settings} \

  pb_redirect_http_to_https=${pb_redirect_http_to_https} \

  php_version=${new_version_php} \
  php_current_default_version=${default_version} \
  php_enable_php_fpm_xdebug=$((php_enable_php_fpm_xdebug == 1)) \
  php_force_install='true' \
  server_timezone=${BS_SERVER_TIMEZONE} \

  ansible_run_playbooks_params=${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}"

  press_any_key_to_return_menu;
}

action_edit_site(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_EDIT_SITE}")

  pb_redirect_http_to_https=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "domain=${domain} \
  default_domain=${BS_DEFAULT_SITE_NAME} \

  path_site_from_links=${path_site_from_links} \
  ssl_lets_encrypt=${ssl_lets_encrypt} \
  ssl_lets_encrypt_www=${ssl_lets_encrypt_www} \
  ssl_lets_encrypt_email=${ssl_lets_encrypt_email} \
  redirect_to_https=${redirect_to_https} \

  path_sites=${BS_PATH_SITES} \

  default_full_path_site=${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME} \

  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \

  permissions_sites_dirs=${BS_PERMISSIONS_SITES_DIRS} \
  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \

  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  path_nginx=${BS_PATH_NGINX} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_nginx_sites_enabled=${BS_PATH_NGINX_SITES_ENABLED} \
  htaccess_support=$((htaccess_support == 1)) \
  nginx_composite=$((nginx_composite == 1)) \

  service_apache_name=${BS_SERVICE_APACHE_NAME} \
  path_apache=${BS_PATH_APACHE} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \

  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \

  bx_cron_agents_path_file_after_document_root=${BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT} \
  bx_cron_logs_path_dir=${BS_BX_CRON_LOGS_PATH_DIR} \
  bx_cron_logs_path_file=${BS_BX_CRON_LOGS_PATH_FILE} \

  pb_redirect_http_to_https=${pb_redirect_http_to_https} \

  php_version=${new_version_php} \
  php_current_default_version=${default_version} \
  php_enable_php_fpm_xdebug=$((php_enable_php_fpm_xdebug == 1)) \
  php_force_install='false' \
  server_timezone=${BS_SERVER_TIMEZONE} \

  ansible_run_playbooks_params=${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}"

  press_any_key_to_return_menu;
}

action_get_lets_encrypt_certificate(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_GET_LETS_ENCRYPT_CERTIFICATE}")

  ansible-playbook -v "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "domain=${domain} \
  default_domain=${BS_DEFAULT_SITE_NAME} \
  path_site=${path_site} \
  email=${email} \
  is_www=${is_www} \

  default_full_path_site=${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_nginx=${BS_PATH_NGINX} \
  service_nginx_name=${BS_SERVICE_NGINX_NAME} \

  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \

  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \

  redirect_to_https=${redirect_to_https}"

  press_any_key_to_return_menu;
}

action_enable_or_disable_redirect_http_to_https(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "path_site=${path_site} \

  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \

  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \

  domain=${site} \
  action=${action}"

  press_any_key_to_return_menu;
}

action_enable_or_disable_bot_blocker(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_BOTBLOCKER}")

  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "path_site=${path_site_from_links} \

  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_nginx=${BS_PATH_NGINX} \
  service_nginx_name=${BS_SERVICE_NGINX_NAME} \

  domain=${site} \
  bot_blocker_action=${action}"

  press_any_key_to_return_menu;
}

action_emulate_bitrix_vm(){
  clear;

  local action="enable"
  if [[ ! -z "${!BS_VAR_NAME_BVM}" ]]; then
      action="disable"
      echo "   Disabled emulate Bitrix VM";
      sed -i "/export ${BS_VAR_NAME_BVM}/d" $BS_VAR_PATH_FILE_BVM
  else
      echo "export ${BS_VAR_NAME_BVM}=\"${BS_VAR_VALUE_BVM}\"" | tee -a $BS_VAR_PATH_FILE_BVM > /dev/null
      echo "   Enabled emulate Bitrix VM";
  fi

  systemctl restart $BS_SERVICE_APACHE_NAME
  press_any_key_to_return_menu;
}

action_check_new_version_menu(){
  local file_temp_config="/tmp/configs.tmp"
  local file_new_version="/tmp/new_version_menu.tmp"

  if [[ -z ${BS_REPOSITORY_URL_FILE_VERSION} ]] || [[ -z ${BS_REPOSITORY_URL} ]] || [[ -z ${BS_CHECK_UPDATE_MENU_MINUTES} ]]; then
      rm -f "${file_new_version}"
      return;
  fi

  if [ -f "${file_temp_config}" ]; then
    current_time=$(date +%s)
    file_time=$(stat -c %Y "${file_temp_config}")
    diff=$((current_time - file_time))
    if [ ! $diff -lt $(($BS_CHECK_UPDATE_MENU_MINUTES * 60)) ]; then
      curl -m 5 -o "${file_temp_config}" -s ${BS_REPOSITORY_URL_FILE_VERSION} 2>/dev/null
    fi
    else
      curl -m 5 -o "${file_temp_config}" -s ${BS_REPOSITORY_URL_FILE_VERSION} 2>/dev/null
  fi

  if [ ! -f ${file_temp_config} ]; then
    rm -f "${file_new_version}"
    return;
  fi

  new_version=$(grep 'BS_VERSION_MENU' ${file_temp_config} | awk -F'=' '{ print $2 }' | tr -d '"')

  if [[ -z ${new_version} ]]; then
    rm -f "${file_new_version}"
    return;
  fi

  if [[ ${new_version} == ${BS_VERSION_MENU} ]]; then
    rm -f "${file_new_version}"
    return;
  fi

  echo "${new_version}" > $file_new_version
}

function action_update_menu() {
    bash <(curl -sL "${BS_URL_SCRIPT_UPDATE_MENU}")
    exit;
}

function action_update_server() {
    apt update -y
    apt upgrade -y

    press_any_key_to_return_menu;
}

function action_change_php_version(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ADD_PHP_VERSIONS}")

  extra_vars="php_version=${new_version_php} \
  php_current_default_version=${default_version} \
  php_set_manual=$((php_set_manual == 1)) \
  php_force_install='true' \
  user_server_sites=${BS_USER_SERVER_SITES} \
  default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  server_timezone=${BS_SERVER_TIMEZONE} \
  domain=${BS_DEFAULT_SITE_NAME} \
  default_domain=${BS_DEFAULT_SITE_NAME} \
  htaccess_support=$((htaccess_support == 1))"

  if [ -n "${BX_ADDITIONAL_PHP_EXTENSIONS}" ]; then
    cat > /tmp/php_extra.yml <<EOF
  php_packages_extra: ${BX_ADDITIONAL_PHP_EXTENSIONS}
EOF
    ansible-playbook "${pb}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" -e "${extra_vars}" -e @/tmp/php_extra.yml
  else
    ansible-playbook "${pb}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" -e "${extra_vars}"
  fi

  press_any_key_to_return_menu;
}

function action_settings_smtp_sites() {

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
      -e "is_actions_account=Y \
      account_name=${site} \
      email_from=${email_from} \
      smtp_host=${host} \
      smtp_port=${port} \
      is_auth=${is_auth} \
      login=${login} \
      password=${password} \
      authentication_method=${authentication_method} \
      enable_TLS=${enable_TLS} \

      smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
      smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
      smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
      smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
      smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
      smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG} \
      smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \
      path_sites=${BS_PATH_SITES}"

    press_any_key_to_return_menu;
}

function action_install_or_delete_netdata() {

    if [ $action = "INSTALL" ]; then
      login=$(pwgen 20 1)
      password=$(generate_password 30)
      hash_pass=$(htpasswd -nb $login $password)
      echo "$hash_pass" > "/etc/${BS_SERVICE_NGINX_NAME}/netdata_passwds"
    fi

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_NETDATA}")
    ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "netdata_action=${action} \
      service_nginx_name=${BS_SERVICE_NGINX_NAME}"

    if [ $action = "INSTALL" ]; then
      echo -e "
      Netdata is installed and configured.
      please follow the link \e[33mhttp://IP or domain/netdata/\e[0m or \e[33mhttps://IP or domain/netdata/\e[0m
      \e[33mLogin: ${login}\e[0m
      \e[33mPassword: ${password}\e[0m"
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_sphinx() {
    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_SPHINX}")
    ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "sphinx_action=${action}"

    press_any_key_to_return_menu;
}

function action_install_or_delete_file_conversion_server() {

    #if [ $action = "INSTALL" ]; then
    #  echo "Install community.rabbitmq collection";
    #  ansible-galaxy collection install 'community.rabbitmq:==1.3.0';
    #fi

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_FILE_CONVERSION_SERVER}")
    ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "file_conversion_server_action=${action} \
      domain=${domain} \
      full_path_site=${full_path_site} \
      user_server_sites=${BS_USER_SERVER_SITES} \
      default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \
      group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
      service_apache_name=${BS_SERVICE_APACHE_NAME}"
    press_any_key_to_return_menu;
}

function action_install_or_delete_crowdsec() {

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_CROWDSEC}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
      -e 'crowdsec_action="'"${action}"'" \
      cs_parsers_mywhitelists_ip="'"$(echo "${BS_CROWDESC_WHITELIST_IP}" | sed 's/,/"\n- "/g; s/^/- "/; s/$/"/;')"'" \
      cs_collections_list="'"$(echo "${BS_CROWDSEC_COLLECTION_INSTALL}" | sed 's/,/\n  /g; s/^/  /;')"'" \
      cs_scenarios_list="'"$(echo "${BS_CROWDSEC_SCENARIOS_INSTALL}" | sed 's/,/\n  /g; s/^/  /;')"'" \
      crowdsec_enroll_key="'"${BS_CROWDSEC_ENROLL_KEY}"'"'

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Crowdsec is installed and configured. If you have provided a key, be sure to restart crowdsec after accepting the request in the web console."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_rkhunter() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_RKHUNTER}")
  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "rkhunter_action=${action} \
      rkhunter_notification_email=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      rkhunter_ssh_permit_root_login=${BS_SSH_PERMIT_ROOT_LOGIN}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Rkhunter is installed and configured.\n      Config in /etc/rkhunter.conf.local"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Rkhunter is deleted."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_maldet() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_MALDET}")
  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "maldet_action=${action} \
      maldet_email_addr=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      maldet_home_prefix=${BS_PATH_USER_HOME_PREFIX}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Maldet is installed and configured.\n      Config in /usr/local/maldetect/conf.maldet"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Maldet is deleted."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_memcached() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_MEMCACHED}")
  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "memcached_action=${action}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Memcached is installed and configured.\n      Config in /etc/memcached.conf"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Memcached is deleted."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_deadsnakes_ppa() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_DEADSNAKES_PPA}")
  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "deadsnakes_action=${action}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Deadsnakes PPA is installed and configured.\n      Don't forget that you can break systems using Ubuntu PPA in Debian"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Deadsnakes PPA is deleted."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_docker() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_DOCKER}")
  ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "docker_action=${action} \
      docker_packages_state=${docker_packages_state} \
      docker_user_list=${BS_DEFAULT_USER_SERVER_SITES}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Docker is installed"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Docker is is deleted."
    fi

    press_any_key_to_return_menu;
}

function action_delete_site() {
    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_DELETE_SITE}")
    ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "site=${site} \
      full_path_site=${full_path_site} \
      db_name=${db_name} \
      db_user=${db_user} \
      type=${type} \

      user_server_sites=${BS_USER_SERVER_SITES} \
      default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \

      service_nginx_name=${BS_SERVICE_NGINX_NAME} \
      path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
      path_nginx_sites_enabled=${BS_PATH_NGINX_SITES_ENABLED} \

      service_apache_name=${BS_SERVICE_APACHE_NAME} \
      path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF}"

    press_any_key_to_return_menu
}

function action_add_remove_ftp_user() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_FTP}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "pureftp_action=${pureftp_action} \
      ftp_user_name=${ftp_user_name} \
      ftp_user_password=${ftp_user_password} \
      ftp_user_dir=${path_site_from_links} \
      ftp_user_uid=${ftp_user_uid}"

}

function action_add_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \
      postgresql_version=${postgresql_version} \
      postgresql_port=${postgresql_port}" \
      --tags installation,initialise,autotune,configuration

    press_any_key_to_return_menu
}

function action_delete_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \
      postgresql_version=${postgresql_version} \
      postgresql_uninstall_1='true' \
      postgresql_uninstall_2='true'" \
      --tags='uninstallation'

    press_any_key_to_return_menu
}

function action_add_db_user_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \

      postgresql_version=${postgresql_version} \
      postgresql_username=${postgresql_username} \
      postgresql_user_password=${postgresql_user_password} \
      postgresql_user_port=${postgresql_port} \

      postgresql_db_name=${postgresql_db_name} \
      postgresql_user_state=${postgresql_user_state} \
      postgresql_db_lc_collate=${postgresql_db_lc_collate} \
      postgresql_db_lc_ctype=${postgresql_db_lc_ctype} \
      postgresql_db_encoding=${postgresql_db_encoding} \
      postgresql_socket='/run/postgresql/'" \
      --tags users,databases,privileges

    is_install_delete_pgbouncer=$(which pgbouncer);
      pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_PGBOUNCER}")

        ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
        -e "pgbouncer_action=${action} \
            pgbouncer_pkg_state='present' \
            pgbouncer_db_user=${postgresql_username} \
            pgbouncer_db_password=${postgresql_user_password} \
            pgbouncer_db_port=${postgresql_port} \
            pgbouncer_db_host='/run/postgresql/' \
            postgresql_db_encoding=${postgresql_db_encoding}" \
            --tags pgbouncer_add_user
    if [ -n "$is_install_delete_pgbouncer" ]; then
        press_any_key_to_return_menu
    fi

    press_any_key_to_return_menu
}

function action_delete_user_and_db_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \

      postgresql_version=${postgresql_version} \
      postgresql_username=${postgresql_username} \
      postgresql_user_password=${postgresql_user_password} \
      postgresql_user_port=${postgresql_port} \

      postgresql_db_name=${postgresql_db_name} \
      postgresql_user_state=${postgresql_user_state} \
      postgresql_db_lc_collate=${postgresql_db_lc_collate} \
      postgresql_db_lc_ctype=${postgresql_db_lc_ctype} \
      postgresql_db_encoding=${postgresql_db_encoding} \
      postgresql_socket='/run/postgresql/'" \
      --tags databases

    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \

      postgresql_version=${postgresql_version} \
      postgresql_username=${postgresql_username} \
      postgresql_user_password=${postgresql_user_password} \
      postgresql_user_port=${postgresql_port} \

      postgresql_db_name=${postgresql_db_name} \
      postgresql_user_state=${postgresql_user_state} \
      postgresql_db_lc_collate=${postgresql_db_lc_collate} \
      postgresql_db_lc_ctype=${postgresql_db_lc_ctype} \
      postgresql_db_encoding=${postgresql_db_encoding} \
      postgresql_socket='/run/postgresql/'" \
      --tags users

    is_install_delete_pgbouncer=$(which pgbouncer);
      pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_PGBOUNCER}")

        ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
        -e "pgbouncer_action=${action} \
            pgbouncer_pkg_state='absent' \
            pgbouncer_db_user=${postgresql_username} \
            pgbouncer_db_password=${postgresql_user_password} \
            pgbouncer_db_port=${postgresql_port} \
            pgbouncer_db_host='/run/postgresql/' \
            postgresql_db_encoding=${postgresql_db_encoding}" \
            --tags pgbouncer_add_user
    if [ -n "$is_install_delete_pgbouncer" ]; then
        press_any_key_to_return_menu
    fi

    press_any_key_to_return_menu
}

function action_add_delete_pgbouncer() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_PGBOUNCER}")

  if [ "$action" == "DELETE" ]; then
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "pgbouncer_action=${action} \
        pgbouncer_pkg_state=${pgbouncer_state}" \
        --tags pgbouncer_install
  else
      ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "pgbouncer_action=${action} \
        pgbouncer_pkg_state=${pgbouncer_state}" \
        --tags pgbouncer_install,pgbouncer_config
  fi

    press_any_key_to_return_menu
}

function action_enable_or_disable_basic_auth() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_BASIC_AUTH}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "basic_auth_action=${basic_auth_action} \
      htpasswd_path_file=${htpasswd_path_file} \
      htpasswd_basic_auth_conf=${htpasswd_basic_auth_conf} \
      htpasswd_username=${htpasswd_username} \
      htpasswd_password=${htpasswd_password} \
      web_server_daemon=${BS_SERVICE_NGINX_NAME}"

}

function action_setup_debian_repositories_for_astra() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_SETUP_DEBIAN_REPO_ON_ASTRA}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "setup_debian_repositories_for_astra_action=${action}"

    press_any_key_to_return_menu
}

function action_re-generate_mysql_config() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_RECONFIGURE_MYSQL_CONFIG}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"
}

function action_upgrade_percona_5.7_to_8.0() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_MYSQL_UPGRADE_57_80}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"
}

function action_upgrade_percona_8.0_to_8.4() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_MYSQL_UPGRADE_80_84}")
    ansible-playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"
}

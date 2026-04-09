#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

run_ansible_playbook() {
  if [ "${BS_ANSIBLE_DEBUG_MODE^^}" == "Y" ]; then
    command ansible-playbook -v "$@"
  else
    command ansible-playbook "$@"
  fi
}

action_create_site(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_CREATE_SITE}")

  pb_redirect_http_to_https=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "domain=${domain} \
  default_domain=${BS_DEFAULT_SITE_NAME} \

  mode=${mode} \

  db_type=${db_type} \
  db_name=${db_name} \
  db_user=${db_user} \
  db_password=${db_password} \
  db_host=${db_host} \
  db_port=${db_port} \
  postgresql_version=${postgresql_version} \
  postgresql_port=${postgresql_port} \
  postgresql_db_lc_collate=${postgresql_db_lc_collate} \
  postgresql_db_lc_ctype=${postgresql_db_lc_ctype} \
  postgresql_db_encoding=${postgresql_db_encoding} \
  pgbouncer_use=$((pgbouncer_use == 1)) \

  path_site_from_links=${path_site_from_links} \
  ssl_lets_encrypt=${ssl_lets_encrypt} \
  ssl_lets_encrypt_domain=${ssl_lets_encrypt_domain} \
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
  server_timezone=$(get_server_timezone) \

  ansible_run_playbooks_params=${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}"

  press_any_key_to_return_menu;
}

action_edit_site(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_EDIT_SITE}")

  pb_redirect_http_to_https=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "domain=${domain} \
  default_domain=${BS_DEFAULT_SITE_NAME} \

  path_site_from_links=${path_site_from_links} \
  ssl_lets_encrypt=${ssl_lets_encrypt} \
  ssl_lets_encrypt_domain=${ssl_lets_encrypt_domain} \
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
  server_timezone=$(get_server_timezone) \

  ansible_run_playbooks_params=${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}"

  press_any_key_to_return_menu;
}

action_get_lets_encrypt_certificate(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_GET_LETS_ENCRYPT_CERTIFICATE}")

  run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
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

  run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
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

  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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

function action_setup_security() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_SECURITY}")

  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "security_ssh_port=${BS_SSH_PORT} \
      security_ssh_password_authentication=${BS_SSH_PASSWORD_AUTHENTICATION} \
      security_ssh_permit_root_login=${BS_SSH_PERMIT_ROOT_LOGIN} \
      security_admin_user=${BS_SSH_ADMIN_USER} \
      security_admin_user_passwordless_sudo=${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO} \
      security_admin_user_password=\"${BS_SSH_ADMIN_USER_PASSWORD}\" \
      security_autoupdate_enabled=${BS_AUTOUPDATE_ENABLED} \
      security_sudoers_passwordless_ssh_key=\"${BS_SSH_ADMIN_USER_SSH_KEY}\" \
      security_autoupdate_reboot=${BS_AUTOUPDATE_REBOOT_ENABLE} \
      security_autoupdate_reboot_time=${BS_AUTOUPDATE_REBOOT_TIME} \
      security_autoupdate_mail_to=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      security_hidepid_enabled=${BS_SECRITY_HIDEPID} \
      security_hidepid_monitoring_user=${BS_SECRITY_HIDEPID_MONITORING_USER}"

  press_any_key_to_return_menu;
}

function action_manage_firewall_port() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_FIREWALL}")
  firewall_vars="{\"marcelnijenhof_firewalld_allow_ports\":[{\"port\":\"${firewall_port_rule}\",\"zone\":\"${firewall_zone}\",\"state\":\"${firewall_rule_state}\",\"permanent\":true,\"immediate\":true}]}"

  run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS -e "${firewall_vars}"

  press_any_key_to_return_menu;
}

function action_manage_firewall_service() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_FIREWALL}")
  firewall_vars="{\"marcelnijenhof_firewalld_allow_services\":[{\"service\":\"${firewall_service_name}\",\"zone\":\"${firewall_zone}\",\"state\":\"${firewall_rule_state}\",\"permanent\":true,\"immediate\":true}]}"

  run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS -e "${firewall_vars}"

  press_any_key_to_return_menu;
}

function action_manage_firewall_source() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_FIREWALL}")
  firewall_vars="{\"marcelnijenhof_firewalld_zones\":[{\"zone\":\"drop\",\"source\":\"${firewall_source}\",\"state\":\"${firewall_rule_state}\",\"permanent\":true}]}"

  run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS -e "${firewall_vars}"

  press_any_key_to_return_menu;
}

function action_reload_firewall() {
  if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "   firewall-cmd is not available."
    press_any_key_to_return_menu;
    return 1
  fi

  firewall-cmd --complete-reload

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
  server_timezone=$(get_server_timezone) \
  domain=${BS_DEFAULT_SITE_NAME} \
  default_domain=${BS_DEFAULT_SITE_NAME} \
  htaccess_support=$((htaccess_support == 1))"

  if [ -n "${BX_ADDITIONAL_PHP_EXTENSIONS}" ]; then
    cat > /tmp/php_extra.yml <<EOF
  php_packages_extra: ${BX_ADDITIONAL_PHP_EXTENSIONS}
EOF
    run_ansible_playbook "${pb}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" -e "${extra_vars}" -e @/tmp/php_extra.yml
  else
    run_ansible_playbook "${pb}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" -e "${extra_vars}"
  fi

  press_any_key_to_return_menu;
}

function action_settings_smtp_sites() {

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
      enable_STARTTLS=${enable_STARTTLS} \

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
    run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
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
    run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "sphinx_action=${action}"

    press_any_key_to_return_menu;
}

function action_install_or_delete_file_conversion_server() {

    #if [ $action = "INSTALL" ]; then
    #  echo "Install community.rabbitmq collection";
    #  ansible-galaxy collection install 'community.rabbitmq:==1.3.0';
    #fi

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_FILE_CONVERSION_SERVER}")
    run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
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
    local crowdsec_install_appsec="${crowdsec_enable_appsec:-${BS_INSTALL_CROWDSEC_APPSEC:-N}}"

    if [[ "${crowdsec_install_appsec}" =~ ^[Yy]$ ]]; then
      crowdsec_install_appsec="true"
    else
      crowdsec_install_appsec="false"
    fi

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_CROWDSEC}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
      -e 'crowdsec_action="'"${action}"'" \
      crowdsec_install_appsec="'"${crowdsec_install_appsec}"'" \
      cs_parsers_mywhitelists_ip="'"$(echo "${BS_CROWDESC_WHITELIST_IP}" | sed 's/,/"\n- "/g; s/^/- "/; s/$/"/;')"'" \
      cs_parsers_mywhitelists_cidr="'"$(echo "${BS_CROWDESC_WHITELIST_CIDR}" | sed 's/,/"\n- "/g; s/^/- "/; s/$/"/;')"'" \
      cs_collections_list="'"$(echo "${BS_CROWDSEC_COLLECTION_INSTALL}" | sed 's/,/\n  /g; s/^/  /;')"'" \
      cs_scenarios_list="'"$(echo "${BS_CROWDSEC_SCENARIOS_INSTALL}" | sed 's/,/\n  /g; s/^/  /;')"'" \
      crowdsec_enroll_key="'"${BS_CROWDSEC_ENROLL_KEY}"'"'

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Crowdsec is installed and configured. If you have provided a key, be sure to restart crowdsec after accepting the request in the web console. Whitelist in /etc/crowdsec/parsers/s02-enrich/whitelists.custom.yaml"
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_rkhunter() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_RKHUNTER}")
  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
  local maldet_monitoring_vars=""
  local maldet_monitoring_enabled="${maldet_enable_monitoring:-${BS_SETUP_MALDET_MONITORING_SERVICE:-N}}"

  if [ "${action}" = "INSTALL" ] && [[ "${maldet_monitoring_enabled}" =~ ^[Yy]$ ]]; then
    maldet_monitoring_vars=" \
      maldet_default_monitor_mode=/usr/local/maldetect/monitor_paths \
      maldet_service_enabled=true"
  fi

  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "maldet_action=${action} \
      maldet_email_addr=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      maldet_home_prefix=${BS_PATH_USER_HOME_PREFIX}${maldet_monitoring_vars}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Maldet is installed and configured.\n      Config in /usr/local/maldetect/conf.maldet\n      YARA-X CLI is installed in /usr/local/bin/yr and updated weekly via /etc/cron.weekly/update-yara-x"
      if [[ "${maldet_monitoring_enabled}" =~ ^[Yy]$ ]]; then
        echo "      Continuous monitoring is enabled via /usr/local/maldetect/monitor_paths"
      fi
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Maldet and YARA-X are deleted."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_memcached() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_MEMCACHED}")
  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "docker_action=${action} \
      docker_packages_state=${docker_packages_state}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Docker is installed"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      Docker is is deleted."
    fi

    press_any_key_to_return_menu;
}

function action_install_or_delete_push_server() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_PUSH_SERVER}")
  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "push_server_action=${action} \
      push_server_remove_redis=${push_server_remove_redis} \
      user_server_sites=${BS_USER_SERVER_SITES} \
      group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
      default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \
      php_default_version_debian=${BX_PHP_DEFAULT_VERSION}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      Push server is installed and configured."
    elif [ "${push_server_remove_redis}" = "Y" ]; then
      echo -e "
      Push server and Redis are deleted."
    else
      echo -e "
      Push server is deleted. Redis is kept."
    fi

    press_any_key_to_return_menu;
}

function action_delete_site() {
    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_DELETE_SITE}")
    run_ansible_playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "site=${site} \
      full_path_site=${full_path_site} \
      db_name=${db_name} \
      db_user=${db_user} \
      db_type=${db_type} \
      type=${type} \
      postgresql_port=${postgresql_port} \
      pgbouncer_use=$((pgbouncer_use == 1)) \

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
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "pureftp_action=${pureftp_action} \
      ftp_user_name=${ftp_user_name} \
      ftp_user_password=${ftp_user_password} \
      ftp_user_dir=${path_site_from_links} \
      ftp_user_uid=${ftp_user_uid}"

}

function action_add_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \
      postgresql_repository_source=${postgresql_repository_source} \
      postgresql_version=${postgresql_version} \
      postgresql_port=${postgresql_port}" \
      --tags installation,initialise,autotune,configuration

    press_any_key_to_return_menu
}

function action_upgrade_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_UPGRADE}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_repository_source=${postgresql_repository_source} \
      postgresql_upgrade_from_version=${postgresql_upgrade_from_version} \
      postgresql_upgrade_to_version=${postgresql_upgrade_to_version}"

    press_any_key_to_return_menu
}

function action_install_mysql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_MYSQL_SETUP}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_action=${action} \
        mysql_flavor=${BS_DB_FLAVOR} \
        mysql_version=${BS_DB_VERSION} \
        mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"

    press_any_key_to_return_menu
}

function action_delete_mysql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_MYSQL_SETUP}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_action=${action}"

    press_any_key_to_return_menu
}

function action_delete_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "postgresql_action=${action} \
      postgresql_version=${postgresql_version} \
      postgresql_uninstall_1='true' \
      postgresql_uninstall_2='true'" \
      --tags='uninstallation'

    press_any_key_to_return_menu
}

function action_add_db_user_postgresql() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_POSTGRESQL_SETUP}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
      --tags users,databases,privileges,extensions

    is_install_delete_pgbouncer=$(which pgbouncer);
      pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_PGBOUNCER}")

        run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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

    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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

        run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "pgbouncer_action=${action} \
        pgbouncer_pkg_state=${pgbouncer_state}" \
        --tags pgbouncer_install
  else
      run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "pgbouncer_action=${action} \
        pgbouncer_pkg_state=${pgbouncer_state}" \
        --tags pgbouncer_install,pgbouncer_config
  fi

    press_any_key_to_return_menu
}

function action_enable_or_disable_basic_auth() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_BASIC_AUTH}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "basic_auth_action=${basic_auth_action} \
      htpasswd_path_file=${htpasswd_path_file} \
      htpasswd_basic_auth_conf=${htpasswd_basic_auth_conf} \
      htpasswd_username=${htpasswd_username} \
      htpasswd_password=${htpasswd_password} \
      web_server_daemon=${BS_SERVICE_NGINX_NAME}"

}

function action_configure_ntlm_auth() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_NTLM_AUTH}")

  run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "ntlm_action=${ntlm_action} \
      domain=${domain} \
      default_domain=${BS_DEFAULT_SITE_NAME} \
      path_site_from_links=${path_site_from_links} \
      path_user_home_prefix=${BS_PATH_USER_HOME_PREFIX} \
      default_full_path_site=${BS_PATH_DEFAULT_SITE} \
      default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \
      service_nginx_name=${BS_SERVICE_NGINX_NAME} \
      path_nginx=${BS_PATH_NGINX} \
      service_apache_name=${BS_SERVICE_APACHE_NAME} \
      path_apache=${BS_PATH_APACHE} \
      path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
      path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \
      ntlm_http_port=${BS_NTLM_HTTP_PORT} \
      ntlm_https_port=${BS_NTLM_HTTPS_PORT} \
      ntlm_name=${ntlm_name} \
      ntlm_fqdn=${ntlm_fqdn} \
      ntlm_dps=${ntlm_dps} \
      ntlm_host=${ntlm_host} \
      ntlm_user=${ntlm_user} \
      ntlm_pass_file=${ntlm_pass_file} \
      ssl_lets_encrypt=${ssl_lets_encrypt} \
      ssl_lets_encrypt_domain=${ssl_lets_encrypt_domain} \
      ssl_lets_encrypt_www=${ssl_lets_encrypt_www} \
      ssl_lets_encrypt_email=${ssl_lets_encrypt_email} \
      redirect_to_https=${redirect_to_https}"
}

function action_setup_debian_repositories_for_astra() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_SETUP_DEBIAN_REPO_ON_ASTRA}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "setup_debian_repositories_for_astra_action=${action}"

    press_any_key_to_return_menu
}

function action_re-generate_mysql_config() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_RECONFIGURE_MYSQL_CONFIG}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"

    press_any_key_to_return_menu;
}

function action_upgrade_percona_5.7_to_8.0() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_MYSQL_UPGRADE_57_80}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"

    press_any_key_to_return_menu;
}

function action_upgrade_percona_8.0_to_8.4() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PS_MYSQL_UPGRADE_80_84}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
        mysql_collation_server=${BS_DB_COLLATION}"

    press_any_key_to_return_menu;
}

function action_install_or_delete_snapd() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_SNAPD}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "snapd_action=${action}"

    if [ "${action}" = "INSTALL" ]; then
      echo -e "
      snapd is installed"
    elif [ "${action}" = "DELETE" ]; then
      echo -e "
      snapd is is deleted."
    fi

    press_any_key_to_return_menu;

}

function action_change_timezone() {
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_CHANGE_TIMEZONE}")
    run_ansible_playbook "${pb}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
    -e "server_timezone=${server_timezone}"

      echo -e "
      timezone is changed to ${server_timezone}"

    press_any_key_to_return_menu;

}

function get_server_timezone() {
    local tz
    tz=$(timedatectl show -p Timezone --value 2>/dev/null)

    if [ -z "$tz" ]; then
        # fallback (non-systemd or broken timedatectl)
        if [ -f /etc/timezone ]; then
            tz=$(cat /etc/timezone)
        elif [ -L /etc/localtime ]; then
            tz=$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')
        fi
    fi

    echo "$tz"
}

#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$dir/utils.sh"
source "$dir/actions.sh"

function do_load_menu() {
  action_check_new_version_menu &
  load_bitrix_vm_version
  if [ $BS_SHOW_IP_CURRENT_SERVER_IN_MENU = true ]; then
    get_ip_current_server
  fi
}

main_menu(){
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;

    do_load_menu;

    local mesg_menu_emulate_bitrix_vm="Enable Bitrix VM emulating"
    if [[ ! -z "${!BS_VAR_NAME_BVM}" ]]; then
      mesg_menu_emulate_bitrix_vm="Disable Bitrix VM emulating (version: ${!BS_VAR_NAME_BVM})"
    fi

    local msg_new_version_menu="";
    local update_menu_action="";
    if [ -f "/tmp/new_version_menu.tmp" ]; then
      local nv=$(cat /tmp/new_version_menu.tmp)
      msg_new_version_menu="\e[33m          New version of Debian Like BitrixVM
          (your version ${BS_VERSION_MENU} -> new version ${nv}) please follow the link
          \e]8;;${BS_REPOSITORY_URL}\a${BS_REPOSITORY_URL}\e]8;;\a or enter \"update_menu\" to update your menu\n\e[0m"
      update_menu_action="Enter \"update_menu\" to update your menu";
    fi

    echo -e "          Welcome to the menu \"Debian Like BitrixVM\" version ${BS_VERSION_MENU}         \n\n";
    if [ $BS_SHOW_IP_CURRENT_SERVER_IN_MENU = true ]; then
      echo -e "          ${CURRENT_SERVER_IP}\n";
    fi
    echo -e "${msg_new_version_menu}";
    echo "          1) List of sites dirs";
    echo "          2) Add/Change site";
    echo "          3) Configure Let\`s Encrypt certificate";
    echo "          4) Enable or Disable redirect HTTP to HTTPS";
    echo "          5) Add/Remove FTP user";
    echo "          6) Add/Change global PHP version";
    echo "          7) Settings SMTP sites";
    echo "          8) Installing Extensions";
    echo "          9) Security settings";
    echo "          10) Change server timezone";
    echo "          11) Update server";
    echo "          R) Restart the server";
    echo "          P) Turn off the server";
    echo "          DELETE_SITE) Delete a site";
    # check_reboot_needed;
    if [ -n "${update_menu_action}" ]; then
      echo -e "\e[33m             ${update_menu_action}\e[0m";
    fi
    echo "          0) Exit";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1") show_sites_dirs ;;
      "2") menu_edit_sites ;;
      "3") get_lets_encrypt_certificate ;;
      "4") enable_or_disable_redirect_http_to_https ;;
      "5") add_remove_ftp_user ;;
      "6") change_php_version ;;
      "7") settings_smtp_sites ;;
      "8") menu_install_extensions ;;
      "9") menu_security_settings ;;
      "10") change_timezone ;;
      "11") update_server ;;
      "R") reboot_server ;;
      "P") power_off_server ;;
      "DELETE_SITE") delete_site ;;
      "update_menu") update_menu;;

    0|z)  exit
    ;;
     *)
      echo "Error unknown command"
      ;;

    esac
    done
}

menu_install_extensions(){
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;
    detect_os;

    echo -e "\n          Menu -> Installing Extensions:\n";
    echo "          1) Install/Delete Memcached";
    echo "          2) Install/Delete Push server";
    echo "          3) Install/Delete Sphinx";
    echo "          4) Install/Delete File Conversion Server (transformer)";
    echo "          5) Install/Delete Netdata";
    echo "          6) Install/Delete Docker";
    echo "          7) PostgreSQL";
    echo "          8) MySQL";
    echo "          9) Install/Delete Snapd";
if [ "$OS_DISTRO" == ubuntu ] ; then
    echo "          10) Install/Delete Deadsnakes PPA";
fi
if [ "$OS_DISTRO" == astra ] ; then
    echo "          11) Install/Delete Debian repo on Astra Linux";
fi
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

    "1") install_memcached ;;
    "2") install_push_server ;;
    "3") install_sphinx ;;
    "4") install_file_conversion_server ;;
    "5") install_netdata ;;
    "6") install_docker ;;
    "7") menu_postgresql ;;
    "8") menu_mysql ;;
    "9") purge_snapd ;;
    "10")
      if [ "$OS_DISTRO" == ubuntu ] ; then
        install_deadsnakes_ppa
      else
        echo "Error unknown command"
      fi
      ;;
    "11")
      if [ "$OS_DISTRO" == astra ] ; then
        install_debian_repo_on_astra_linux
      else
        echo "Error unknown command"
      fi
      ;;

    0|z)  main_menu
    ;;
     *)
      echo "Error unknown command"
      ;;

    esac
    done
}

menu_security_settings(){
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;

    echo -e "\n          Menu -> Security settings:\n";
    echo "          1) SSH/Updates";
    echo "          2) Install/Delete Crowdsec";
    echo "          3) Install/Delete Rkhunter";
    echo "          4) Install/Delete Linux Malware Detect";
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1") security_settings ;;
      "2") install_crowdsec ;;
      "3") install_rkhunter ;;
      "4") install_linux_malware_detect ;;

    0|z)  main_menu
    ;;
     *)
      echo "Error unknown command"
      ;;

    esac
    done
}

menu_edit_sites(){
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;
    list_sites;

    echo -e "\n          Menu -> Edit site settings:\n";
    echo "          1) Add site";
    echo "          2) Edit existing website";
    echo "          3) Delete site";
    echo "          4) Block/Unblock access by ip";
    echo "          5) Enable/Disable Basic Auth in ${BS_SERVICE_NGINX_NAME}";
    echo "          6) Enable/Disable Bot Blocker in ${BS_SERVICE_NGINX_NAME}";
    echo "          7) Configure NTLM auth for sites";
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1") add_site ;;
      "2") edit_site_config ;;
      "3") delete_site ;;
      "4") block_access_by_ip ;;
      "5") enable_or_disable_basic_auth ;;
      "6") enable_or_disable_bot_blocker ;;
      "7") menu_ntlm_auth_sites ;;

    0|z)  main_menu
    ;;
     *)
      echo "Error unknown command"
      ;;

    esac
    done
}


menu_postgresql(){
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;

    echo -e "\n          Menu -> PostgreSQL settings:\n";
    echo "          1) Install PostgreSQL";
    echo "          2) Delete PostgreSQL";
    echo "          3) Upgrade PostgreSQL";
    echo "          4) Add user and db in PostgreSQL";
    echo "          5) Remove user and db from PostgreSQL";
    echo "          6) Install/Delete Pgbouncer";
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1") install_postgresql ;;
      "2") delete_postgresql ;;
      "3") upgrade_postgresql ;;
      "4") add_user_and_db_postgresql ;;
      "5") delete_user_and_db_postgresql ;;
      "6") install_delete_pgbouncer ;;

    0|z)  main_menu
    ;;
     *)
      echo "Error unknown command"
      ;;

    esac
    done
}

menu_mysql(){
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;
    local mysql_installed=false
    local option_upgrade_57=""
    local option_upgrade_80=""
    local option_delete_mysql=""

    if detect_mysql_version >/dev/null 2>&1; then
      mysql_installed=true
    fi

    echo -e "\n          Menu -> MySQL:\n";
    if $mysql_installed; then
      echo "          Installed: ${MYSQL_FLAVOR} ${MYSQL_VERSION}"
      echo "          1) Re-generate MySQL config";
      local next_option=2
      if [ "$MYSQL_VERSION_MAJOR" == 5.7 ] ; then
        option_upgrade_57="$next_option"
        echo "          ${option_upgrade_57}) Upgrade percona 5.7 to 8.0";
        next_option=$((next_option + 1))
      fi
      if [ "$MYSQL_FLAVOR" == "Percona" ] && [ "$MYSQL_VERSION_MAJOR" == 8.0 ] ; then
        option_upgrade_80="$next_option"
        echo "          ${option_upgrade_80}) Upgrade percona 8.0 to 8.4";
        next_option=$((next_option + 1))
      fi
      option_delete_mysql="$next_option"
      echo "          ${option_delete_mysql}) Delete MySQL";
    else
      echo "          MySQL is not installed"
      echo "          1) Install MySQL";
    fi
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1")
        if $mysql_installed; then
          re-generate_mysql_config
        else
          install_mysql
        fi
        ;;
      "$option_upgrade_57")
        if [ -n "$option_upgrade_57" ]; then
          upgrade_percona_5.7_to_8.0
        else
          echo "Error unknown command"
        fi
        ;;
      "$option_upgrade_80")
        if [ -n "$option_upgrade_80" ]; then
          upgrade_percona_8.0_to_8.4
        else
          echo "Error unknown command"
        fi
        ;;
      "$option_delete_mysql")
        if [ -n "$option_delete_mysql" ]; then
          delete_mysql
        else
          echo "Error unknown command"
        fi
        ;;

    0|z)  main_menu
    ;;
     *)
      echo "Error unknown command"
      ;;

    esac
    done
}

# Function to sanitize and limit the length of names
sanitize_name() {
    local input=$1 max_length=$2
    local sanitized; sanitized=$(echo "$input" | sed 's/-//g' | sed 's/\./_/g' | "${dir_helpers}/perl/translate.pl")
    sanitized=$(cut -c-"$max_length" <<< "$sanitized")
    sanitized=${sanitized%_}
    printf "%s" "$sanitized"
}

# Function to check if a MySQL database exists
db_exists() {
    local db_name=$1
    if ! $BS_MYSQL_CMD -e "USE ${db_name}" 2>/dev/null; then
        return 1
    fi
    return 0
}

# Function to check if a MySQL user exists
user_exists() {
    local db_user=$1
    if ! $BS_MYSQL_CMD -e "SELECT 1 FROM mysql.user WHERE user = '${db_user}'" 2>/dev/null | grep -q 1; then
        return 1
    fi
    return 0
}

is_mysql_installed() {
    detect_mysql_version >/dev/null 2>&1
}

get_distribution_postgresql_version() {
    apt-cache depends postgresql 2>/dev/null |
        awk '/Depends: postgresql-[0-9]+/ {sub("postgresql-", "", $2); print $2; exit}'
}

get_available_postgresql_versions_for_source() {
    local repository_source="${1:-${BS_POSTGRESQL_REPOSITORY_SOURCE}}"

    if [ "${repository_source}" = "distro" ]; then
        get_distribution_postgresql_version
        return 0
    fi

    apt-cache search --names-only '^postgresql-[0-9]+$' 2>/dev/null |
        sed -n 's/^postgresql-\([0-9]\+\)[[:space:]].*/\1/p' |
        sort -n |
        uniq |
        tr '\n' ' '
}

get_installed_postgresql_versions_raw() {
    ls -d /usr/lib/postgresql/[0-9]* 2>/dev/null | xargs -r -n1 basename | sort -n | tr '\n' ' '
}

get_pgbouncer_listen_port() {
    local pgbouncer_port
    pgbouncer_port=$(sed -n 's/^[[:space:]]*listen_port[[:space:]]*=[[:space:]]*//p' /etc/pgbouncer/pgbouncer-other.ini 2>/dev/null | head -n1)
    printf '%s\n' "${pgbouncer_port:-6432}"
}

get_pgbouncer_backend_port_for_user() {
    local username=$1
    sed -n "s/^${username}[[:space:]]*=[[:space:]]*host=.* port=\\([0-9]\\+\\).*/\\1/p" /etc/pgbouncer/pgbouncer-other.ini 2>/dev/null | head -n1
}

get_postgresql_port_by_version() {
    local version=$1
    local port

    port=$(grep -r "/var/lib/postgresql/$version/main" /run/postgresql/ 2>/dev/null | grep -oP '(?<=PGSQL.)\d+' | head -n1)
    if [[ -z "$port" ]]; then
        port=$(sed -nE "s/^[[:space:]]*port[[:space:]]*=[[:space:]]*'?([0-9]+)'?.*/\\1/p" "/etc/postgresql/$version/main/postgresql.conf" 2>/dev/null | head -n1)
    fi

    printf '%s\n' "$port"
}

find_postgresql_version_by_port() {
    local port=$1
    local version current_port
    for version in $(get_installed_postgresql_versions_raw); do
        current_port=$(get_postgresql_port_by_version "$version")
        if [ "$current_port" = "$port" ]; then
            printf '%s\n' "$version"
            return 0
        fi
    done
    return 1
}

postgresql_cluster_exists() {
    local version=$1
    [[ -d "/etc/postgresql/$version/main" ]]
}

print_postgresql_cluster_info() {
    local version=$1
    local port socket status

    if ! postgresql_cluster_exists "$version"; then
        printf "   PostgreSQL cluster for version %s not found\n" "$version"
        return 1
    fi

    port=$(get_postgresql_port_by_version "$version")
    socket="/run/postgresql/.s.PGSQL.$port"
    status="stopped"

    if [[ -n "$port" && -S "$socket" ]]; then
        status="running"
    fi

    printf "   \n   Version: %s\n   Port: %s\n   Status: %s\n\n" "$version" "${port:-unknown}" "$status"
}

postgresql_db_exists() {
    local db_name=$1
    sudo -u postgres psql -h /run/postgresql -p "$postgresql_port" -tAc "SELECT 1 FROM pg_database WHERE datname = '${db_name}'" 2>/dev/null | grep -q 1
}

postgresql_user_exists() {
    local db_user=$1
    sudo -u postgres psql -h /run/postgresql -p "$postgresql_port" -tAc "SELECT 1 FROM pg_roles WHERE rolname = '${db_user}'" 2>/dev/null | grep -q 1
}

database_exists_by_type() {
    local db_engine=$1
    local db_name=$2

    if [ "$db_engine" = "pgsql" ]; then
        postgresql_db_exists "$db_name"
    else
        db_exists "$db_name"
    fi
}

user_exists_by_type() {
    local db_engine=$1
    local username=$2

    if [ "$db_engine" = "pgsql" ]; then
        postgresql_user_exists "$username"
    else
        user_exists "$username"
    fi
}

select_site_database_type() {
    local mysql_available=$1
    local postgresql_available=$2

    db_type="mysql"
    postgresql_version=""
    postgresql_port=""
    postgresql_db_lc_collate="ru_RU.UTF-8"
    postgresql_db_lc_ctype="${postgresql_db_lc_collate}"
    postgresql_db_encoding="UTF-8"
    pgbouncer_use=0
    db_host="localhost"
    db_port="3306"

    if $mysql_available && $postgresql_available; then
        echo "   The following databases are available:"
        echo "   mysql - default database used for site (MySQL)"
        echo "   pgsql - alternative database used for site (PostgreSQL)"
        echo "   Default: mysql"
        echo

        while true; do
            read -r -p "   Enter database type (mysql|pgsql): " input_db_type
            input_db_type=${input_db_type:-mysql}
            case "${input_db_type}" in
                mysql|pgsql)
                    db_type="${input_db_type}"
                    break
                    ;;
                *)
                    echo "   Please enter mysql or pgsql."
                    ;;
            esac
        done
    elif $postgresql_available; then
        db_type="pgsql"
    fi

    if [ "$db_type" = "pgsql" ]; then
        resolve_site_postgresql_instance || return 1
        db_host="127.0.0.1"
        db_port="${postgresql_port}"

        if command -v pgbouncer >/dev/null 2>&1; then
            pgbouncer_use=1
            db_port=$(get_pgbouncer_listen_port)
        fi
    fi
}

resolve_site_postgresql_instance() {
    local versions version_count default_pg_version
    versions=$(get_installed_postgresql_versions_raw)
    version_count=$(wc -w <<< "$versions")

    if [ "$version_count" -eq 0 ]; then
        echo "   PostgreSQL is not installed."
        return 1
    fi

    if [ "$version_count" -gt 1 ]; then
        echo "   Installed PostgreSQL versions: $versions"
        default_pg_version=$(printf '%s\n' "$versions" | awk '{print $1}')
        while true; do
            read_by_def "   Enter PostgreSQL version for site (default: ${default_pg_version}): " postgresql_version "${default_pg_version}"
            if [[ " ${versions} " =~ " ${postgresql_version} " ]] && get_postgresql_info "${postgresql_version}" >/dev/null; then
                break
            fi
            echo "   PostgreSQL version ${postgresql_version} is not installed or not running."
        done
    else
        postgresql_version=$(printf '%s\n' "$versions" | awk '{print $1}')
        if ! get_postgresql_info "${postgresql_version}" >/dev/null; then
            echo "   PostgreSQL version ${postgresql_version} is not running."
            return 1
        fi
    fi
}

# Function to generate a random hash
generate_random_hash() {
    local hash_length=8
    local hash; hash=$(openssl rand -hex "$hash_length")
    printf "%s" "$hash"
}

# Generate username
generate_unique_username() {
    local prefix="user"
    local counter=1
    local username

    while true; do
        username=$(printf "%s%04d" "$prefix" "$counter")
        if ! id "$username" &>/dev/null; then
            echo "$username"
            return
        fi
        ((counter++))
    done
}

# Extract username based on the path
extract_username_from_path() {
        if [[ "${path_site_from_links}" != $BS_PATH_USER_HOME_PREFIX/$BS_PATH_USER_HOME/* ]]; then
          BS_USER_SERVER_SITES=$(echo "${path_site_from_links}" | cut -d'/' -f4)
          BS_PATH_USER_HOME="${BS_USER_SERVER_SITES}"
        fi

        BS_GROUP_USER_SERVER_SITES="${BS_USER_SERVER_SITES}"
        BS_PATH_SITES="${BS_PATH_USER_HOME_PREFIX}/${BS_PATH_USER_HOME}"
}

detect_os() {
    local id=""

    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        id="$ID"
    fi

    OS_DISTRO="$id"
}

add_site(){
    clear;
    list_sites;

    domain=''
    mode=''
    db_type='mysql'
    db_name=''
    db_user=''
    db_password=$(generate_password $BS_CHAR_DB_PASSWORD)
    db_host='localhost'
    db_port='3306'
    postgresql_version=''
    postgresql_port=''
    postgresql_db_lc_collate='ru_RU.UTF-8'
    postgresql_db_lc_ctype="${postgresql_db_lc_collate}"
    postgresql_db_encoding='UTF-8'
    pgbouncer_use=0
    path_site_from_links=$BS_PATH_DEFAULT_SITE
    php_enable_php_fpm_xdebug='N'
    new_version_php="$default_version";
    htaccess_support=${BS_HTACCESS_SUPPORT};
    push_server_bx_settings=${BS_PUSH_SERVER_BX_SETTINGS};

    ssl_lets_encrypt="N";
    ssl_lets_encrypt_www="Y";
    ssl_lets_encrypt_email="${BS_EMAIL_ADMIN_FOR_NOTIFY}";
    redirect_to_https="N";

    echo -e "\n   Menu -> Add a site:\n";
    while [[ -z "$domain" ]]; do
      read_by_def "   Enter site domain (example: example.com): " domain $domain;
      if [ -z "$domain" ]; then
        echo "   Incorrect site domain! Please enter site domain";
      elif [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $domain " ]]; then
        domain='';
        echo "   Domain already exists! Please enter another site domain";
      fi
    done

    if [ -z "$ssl_lets_encrypt_email" ]; then
      ssl_lets_encrypt_email=$(echo "admin@$domain" | "${dir_helpers}/perl/translate.pl")
    fi

    while true; do
        read -r -p "   Enter site mode link or full: " mode
        case $mode in
            link ) break;;
            full ) break;;
            * ) echo "   Incorrect site mode";;
        esac
    done

    case $mode in
      link )
        read_by_def "   Enter path to links site (default: $path_site_from_links): " path_site_from_links $path_site_from_links;
        export db_name=$(php -r '$settings = include "'$path_site_from_links'/bitrix/.settings.php"; echo $settings["connections"]["value"]["default"]["database"];')

        # Extract domain name from link
        main_domain=$(basename "$path_site_from_links")

        # Extract PHP version from link
        local site_config="${BS_PATH_APACHE_SITES_ENABLED}/${main_domain}.conf"

        if [ -f "$site_config" ]; then
          new_version_php=$(grep -oP 'php\K[\d.]+(?=-(?:user\d+)?-?fpm\.sock)' "$site_config")
          if [ -z "$new_version_php" ]; then
            new_version_php=$default_version
          fi
        fi 

        extract_username_from_path

        while true; do
          read -r -p "   Do you want to use xdebug? (Y/N) [${php_enable_php_fpm_xdebug}]: " answer
          answer=${answer:-$php_enable_php_fpm_xdebug}
          case ${answer,,} in
            y ) php_enable_php_fpm_xdebug=1; break;;
            n ) php_enable_php_fpm_xdebug=0; break;;
            * ) printf "   Please enter Y or N.\n";;
          esac
        done
      ;;
      full )
          local mysql_available=false
          local postgresql_available=false

          if is_mysql_installed; then
            mysql_available=true
          fi
          if [ -n "$(get_installed_postgresql_versions_raw)" ]; then
            postgresql_available=true
          fi

          if ! $mysql_available && ! $postgresql_available; then
            echo "   Neither MySQL nor PostgreSQL is installed. Install a database first."
            press_any_key_to_return_menu
            return 1
          fi

          # Choose PHP version for site
          while true; do
              read_by_def "   Enter PHP version for site from installed (default: $default_version): " new_version_php "$new_version_php"
              if [[ " $version_list " =~ " $new_version_php " ]]; then
                  break
              else
                  echo "   Incorrect PHP version! Please enter a version from the installed list."
              fi
          done

          new_version_php="${new_version_php^^}"
          new_version_php=$(echo "$new_version_php" | sed -e 's/PHP//')
          echo -e "\n   Selected PHP version: $new_version_php\n"

          while true; do
            read -r -p "   Do you want to use xdebug? (Y/N) [${php_enable_php_fpm_xdebug}]: " answer
            answer=${answer:-$php_enable_php_fpm_xdebug}
            case ${answer,,} in
              y ) php_enable_php_fpm_xdebug=1; break;;
              n ) php_enable_php_fpm_xdebug=0; break;;
              * ) printf "   Please enter Y or N.\n";;
            esac
          done

          if [ -f "${BS_PUSH_SERVER_CONFIG}" ]; then
            while true; do
              read -r -p "   Do you want to add local push-server config to /bitrix/.setting.php? (Y/N) [${push_server_bx_settings}]: " answer
              answer=${answer:-$push_server_bx_settings}
              case ${answer,,} in
                y ) push_server_bx_settings=Y; break;;
                n ) push_server_bx_settings=N; break;;
                * ) printf "   Please enter Y or N.\n";;
              esac
            done
          else
            push_server_bx_settings=N
          fi

            # Create unique username for each full site
              BS_USER_SERVER_SITES=$(generate_unique_username)
              BS_GROUP_USER_SERVER_SITES=$BS_USER_SERVER_SITES

              while true; do
                  read_by_def "   Enter username for the site user (default: $BS_USER_SERVER_SITES): " BS_USER_SERVER_SITES $BS_USER_SERVER_SITES
                  if id "$BS_USER_SERVER_SITES" &>/dev/null; then
                      echo "   Warning: User $BS_USER_SERVER_SITES already exists."
                      read -r -p "   Do you want to continue with this existing user? (Y/N): " use_existing
                      case $use_existing in
                          [Yy]* ) break;;
                          [Nn]* ) continue;;
                          * ) echo "   Please answer Y or N.";;
                      esac
                  else
                      break
                  fi
              done

              BS_GROUP_USER_SERVER_SITES="${BS_USER_SERVER_SITES}"
              BS_PATH_USER_HOME="${BS_USER_SERVER_SITES}"
              BS_PATH_SITES="${BS_PATH_USER_HOME_PREFIX}/${BS_PATH_USER_HOME}"

              if ! select_site_database_type "$mysql_available" "$postgresql_available"; then
                  press_any_key_to_return_menu
                  return 1
              fi

              # Create the user if it doesn't exist
              if ! id "$BS_USER_SERVER_SITES" &>/dev/null; then
                  useradd -m -d "${BS_PATH_USER_HOME_PREFIX}/${BS_USER_SERVER_SITES}" -s /bin/bash "${BS_USER_SERVER_SITES}"
                  chmod 775 "${BS_PATH_USER_HOME_PREFIX}/${BS_USER_SERVER_SITES}"
              fi
              echo "   Username: ${BS_USER_SERVER_SITES}"

          while true; do
            db_name=$(sanitize_name "db_$domain" "$BS_MAX_CHAR_DB_NAME")
            db_user=$(sanitize_name "usr_$domain" "$BS_MAX_CHAR_DB_USER")

            if database_exists_by_type "$db_type" "$db_name" || user_exists_by_type "$db_type" "$db_user"; then
                printf "Warning: Database '%s' or User '%s' already exists. Generating unique names...\n" "$db_name" "$db_user" >&2
                local unique_hash; unique_hash=$(generate_random_hash)
                db_name=$(sanitize_name "db_$domain_$unique_hash" "$BS_MAX_CHAR_DB_NAME")
                db_user=$(sanitize_name "usr_$domain_$unique_hash" "$BS_MAX_CHAR_DB_USER")
            fi

            # Ensure generated names are unique
            while database_exists_by_type "$db_type" "$db_name" || user_exists_by_type "$db_type" "$db_user"; do
                printf "Error: Generated names '%s' or '%s' already exist. Regenerating...\n" "$db_name" "$db_user" >&2
                unique_hash=$(generate_random_hash)
                db_name=$(sanitize_name "db_$domain_$unique_hash" "$BS_MAX_CHAR_DB_NAME")
                db_user=$(sanitize_name "usr_$domain_$unique_hash" "$BS_MAX_CHAR_DB_USER")
            done

            while true; do
                read_by_def "   Enter database name: (default: $db_name): " db_name $db_name
                db_name=$(sanitize_name "$db_name" "$BS_MAX_CHAR_DB_NAME")

                if database_exists_by_type "$db_type" "$db_name"; then
                    printf "Error: Database '%s' already exists.\n" "$db_name" >&2
                    unique_hash=$(generate_random_hash)
                    db_name=$(sanitize_name "db_$domain_$unique_hash" "$BS_MAX_CHAR_DB_NAME")
                    continue
                fi

                break
            done

            while true; do
                read_by_def "   Enter database user: (default: $db_user): " db_user $db_user
                db_user=$(sanitize_name "$db_user" "$BS_MAX_CHAR_DB_USER")

                if user_exists_by_type "$db_type" "$db_user"; then
                    printf "Error: User '%s' already exists.\n" "$db_user" >&2
                    unique_hash=$(generate_random_hash)
                    db_user=$(sanitize_name "usr_$domain_$unique_hash" "$BS_MAX_CHAR_DB_USER")
                    continue
                fi

                break
            done

            read_by_def "   Enter database password: (default: $db_password): " db_password $db_password
            break
        done
      ;;
    esac

    while true; do
      read -r -p "   Do you want htaccess support? (Y/N) [default: ${htaccess_support}]: " answer
      answer=${answer:-$htaccess_support}
      case ${answer,,} in
        y ) htaccess_support=1; break;;
        n ) htaccess_support=0; break;;
        * ) printf "   Please enter Y or N.\n";;
      esac
    done

    read_by_def "   Enter Y or N for setting SSL Let\`s Encrypt site (default: $ssl_lets_encrypt): " ssl_lets_encrypt $ssl_lets_encrypt;
    ssl_lets_encrypt="${ssl_lets_encrypt^^}"

    if [ $ssl_lets_encrypt == "Y" ]; then
        read_by_def "   Enter Y or N to get a certificate for WWW (default: $ssl_lets_encrypt_www): " ssl_lets_encrypt_www $ssl_lets_encrypt_www;
        read_by_def "   Enter email for SSL Let\`s Encrypt (default: $ssl_lets_encrypt_email): " ssl_lets_encrypt_email $ssl_lets_encrypt_email;
        read_by_def "   Enter Y or N for redirect HTTP to HTTPS (default: $redirect_to_https): " redirect_to_https $redirect_to_https;
        redirect_to_https="${redirect_to_https^^}"
        ssl_lets_encrypt_www="${ssl_lets_encrypt_www^^}"
    fi


    echo -e "\n   Entered data:\n"
    echo "   Domain: $domain";
    echo "   Mode: $mode";

    case $mode in
      link )
        echo "   Path to links site: $path_site_from_links";
        echo "   Xdebug enabled: $php_enable_php_fpm_xdebug"
      ;;
      full )
        echo "   Site user: $BS_USER_SERVER_SITES"
        echo "   Selected PHP version: $new_version_php"
        echo "   Xdebug enabled: $php_enable_php_fpm_xdebug"
        echo "   Push-server config: $push_server_bx_settings"
        echo "   Database type: $db_type"
        if [ "$db_type" == "pgsql" ]; then
          echo "   PostgreSQL version: $postgresql_version"
          if [ "$pgbouncer_use" -eq 1 ]; then
            echo "   Pgbouncer: Y"
          else
            echo "   Pgbouncer: N"
          fi
        fi
        echo "   Database host: $db_host"
        echo "   Database port: $db_port"
        echo "   Database name: $db_name";
        echo "   Database user: $db_user";
        echo "   Database password: $db_password";
      ;;
    esac

    echo "   SSL Let\`s Encrypt: $ssl_lets_encrypt";
    echo "   Htaccess support: $htaccess_support";

    if [ $ssl_lets_encrypt == "Y" ]; then
        echo "   Get a certificate for WWW: $ssl_lets_encrypt_www"
        echo "   SSL Let\`s Encrypt email: $ssl_lets_encrypt_email"
        echo "   Redirect HTTP to HTTPS: $redirect_to_https"
    fi

    echo -e "\n\n"

    while true; do
        read -r -p "   Do you really want to create a website? (Y/N): " answer
        case $answer in
            [Yy]* ) action_create_site; break;;
            [Nn]* ) break;;
            * ) echo "   Please enter Y or N.";;
        esac
    done
}


edit_site_config(){
    clear;
    list_sites;

    domain=''
    mode=''
    path_site_from_links=''
    php_enable_php_fpm_xdebug='N'
    new_version_php="$default_version";
    htaccess_support=${BS_HTACCESS_SUPPORT};

    ssl_lets_encrypt="N";
    ssl_lets_encrypt_domain="";
    ssl_lets_encrypt_www="Y";
    ssl_lets_encrypt_email="${BS_EMAIL_ADMIN_FOR_NOTIFY}";
    redirect_to_https="N";
    nginx_composite="N";

    echo -e "\n   Menu -> Edit site:\n";
    while [[ ! -d "$path_site_from_links" ]]; do
      read_by_def "   Enter existing path to site (default: ${BS_PATH_DEFAULT_SITE}): " path_site_from_links "${BS_PATH_DEFAULT_SITE}";
      if [ ! -d "$path_site_from_links" ]; then
        echo "   Incorrect site dir! Please enter site dir";
      fi
    done

    if [ -z "$ssl_lets_encrypt_email" ]; then
      ssl_lets_encrypt_email=$(echo "admin@$domain" | "${dir_helpers}/perl/translate.pl")
    fi

        # Extract domain name from link
        domain=$(basename "$path_site_from_links")
        ssl_lets_encrypt_domain="$domain"

        # Extract username based on the path
        extract_username_from_path

        # Choose PHP version for site
        while true; do
            read_by_def "   Enter PHP version for site from installed (default: $default_version): " new_version_php "$new_version_php"
            if [[ " $version_list " =~ " $new_version_php " ]]; then
                break
            else
                echo "   Incorrect PHP version! Please enter a version from the installed list."
            fi
        done

        new_version_php="${new_version_php^^}"
        new_version_php=$(echo "$new_version_php" | sed -e 's/PHP//')
        echo -e "\n   Selected PHP version: $new_version_php\n"



        # Xdebug
        while true; do
          read -r -p "   Do you want to use xdebug? (Y/N) [${php_enable_php_fpm_xdebug}]: " answer
          answer=${answer:-$php_enable_php_fpm_xdebug}
          case ${answer,,} in
            y ) php_enable_php_fpm_xdebug=1; break;;
            n ) php_enable_php_fpm_xdebug=0; break;;
            * ) printf "   Please enter Y or N.\n";;
          esac
        done

        # Htaccess
        while true; do
          read -r -p "   Do you want htaccess support? (Y/N) [default: ${htaccess_support}]: " answer
          answer=${answer:-$htaccess_support}
          case ${answer,,} in
            y ) htaccess_support=1; break;;
            n ) htaccess_support=0; break;;
            * ) printf "   Please enter Y or N.\n";;
          esac
        done

        # Composite nginx-files
        while true; do
          read -r -p "   Do you want ${BS_SERVICE_NGINX_NAME}-composite from files support? (Y/N) [default: ${nginx_composite}]: " answer
          answer=${answer:-$nginx_composite}
          case ${answer,,} in
            y ) nginx_composite=1; break;;
            n ) nginx_composite=0; break;;
            * ) printf "   Please enter Y or N.\n";;
          esac
        done

    read_by_def "   Enter Y or N for setting SSL Let\`s Encrypt site (default: $ssl_lets_encrypt): " ssl_lets_encrypt $ssl_lets_encrypt;
    ssl_lets_encrypt="${ssl_lets_encrypt^^}"

    if [ $ssl_lets_encrypt == "Y" ]; then
        local site_ssl_conf="${BS_PATH_NGINX}/site_settings/${domain}/ssl.conf"
        if [ -f "$site_ssl_conf" ] && grep -q '/etc/letsencrypt/live/' "$site_ssl_conf"; then
            local current_ssl_lets_encrypt_domain=""
            current_ssl_lets_encrypt_domain=$(sed -n 's|^[[:space:]]*ssl_certificate[[:space:]]\+/etc/letsencrypt/live/\([^/;[:space:]]\+\)/fullchain\.pem;.*|\1|p' "$site_ssl_conf" | head -n1)
            if [ -n "$current_ssl_lets_encrypt_domain" ]; then
                ssl_lets_encrypt_domain="$current_ssl_lets_encrypt_domain"
            fi
        fi

        if [ "$domain" == "$BS_DEFAULT_SITE_NAME" ]; then
            if [ "$ssl_lets_encrypt_domain" == "$domain" ]; then
                ssl_lets_encrypt_domain=""
            fi

            while true; do
                read_by_def "   Enter domain for SSL Let\`s Encrypt certificate (default: $ssl_lets_encrypt_domain): " ssl_lets_encrypt_domain "$ssl_lets_encrypt_domain";
                if [ -z "$ssl_lets_encrypt_domain" ]; then
                    echo "   Incorrect domain! Please enter another domain";
                else
                    break
                fi
            done
        fi

        if [ -z "$ssl_lets_encrypt_email" ] || [ "$ssl_lets_encrypt_email" == "$(echo "admin@$domain" | "${dir_helpers}/perl/translate.pl")" ]; then
            ssl_lets_encrypt_email=$(echo "admin@$ssl_lets_encrypt_domain" | "${dir_helpers}/perl/translate.pl")
        fi

        read_by_def "   Enter Y or N to get a certificate for WWW (default: $ssl_lets_encrypt_www): " ssl_lets_encrypt_www $ssl_lets_encrypt_www;
        read_by_def "   Enter email for SSL Let\`s Encrypt (default: $ssl_lets_encrypt_email): " ssl_lets_encrypt_email $ssl_lets_encrypt_email;
        read_by_def "   Enter Y or N for redirect HTTP to HTTPS (default: $redirect_to_https): " redirect_to_https $redirect_to_https;
        redirect_to_https="${redirect_to_https^^}"
        ssl_lets_encrypt_www="${ssl_lets_encrypt_www^^}"
    fi


    echo -e "\n   Entered data:\n"
    echo "   Domain: $domain";
    echo "   Path to site: $path_site_from_links";
    echo "   Site user: $BS_USER_SERVER_SITES"
    echo "   Selected PHP version: $new_version_php"
    echo "   Xdebug enabled: $php_enable_php_fpm_xdebug"
    echo "   SSL Let\`s Encrypt: $ssl_lets_encrypt";
    echo "   Htaccess support: $htaccess_support";
    echo "   ${BS_SERVICE_NGINX_NAME} composite: $nginx_composite";

    if [ $ssl_lets_encrypt == "Y" ]; then
        echo "   SSL Let\`s Encrypt domain: $ssl_lets_encrypt_domain"
        echo "   Get a certificate for WWW: $ssl_lets_encrypt_www"
        echo "   SSL Let\`s Encrypt email: $ssl_lets_encrypt_email"
        echo "   Redirect HTTP to HTTPS: $redirect_to_https"
    fi

    echo -e "\n\n"

    while true; do
        read -r -p "   Do you really want to edit a website? (Y/N): " answer
        case $answer in
            [Yy]* ) action_edit_site; break;;
            [Nn]* ) break;;
            * ) echo "   Please enter Y or N.";;
        esac
    done
}

ntlm_cleanup_password_file() {
    if [[ -n "$ntlm_pass_file" ]] && [[ -f "$ntlm_pass_file" ]]; then
        rm -f "$ntlm_pass_file"
    fi
    ntlm_pass_file=""
}

ntlm_prepare_password_file() {
    local ntlm_password_value=$1

    ntlm_cleanup_password_file
    ntlm_pass_file=$(mktemp /tmp/ntlm_pass.XXXXXX)
    chmod 600 "$ntlm_pass_file"
    printf "%s" "$ntlm_password_value" > "$ntlm_pass_file"
}

ntlm_get_server_status() {
    NTLM_STATUS="not_configured"
    NTLM_REALM=""
    NTLM_WORKGROUP=""
    NTLM_LDAP_SERVER=""
    NTLM_LDAP_PORT=""
    NTLM_BIND_PATH=""
    NTLM_KDC=""
    NTLM_TIME_OFFSET=""

    if ! command -v net >/dev/null 2>&1; then
        return 0
    fi

    local net_info
    net_info=$(net ads info 2>/dev/null) || return 0

    NTLM_WORKGROUP=$(echo "$net_info" | awk -F':' '/^Workgroup:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    NTLM_REALM=$(echo "$net_info" | awk -F':' '/^Realm:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    NTLM_LDAP_SERVER=$(echo "$net_info" | awk -F':' '/^LDAP server name:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    if [ -z "$NTLM_LDAP_SERVER" ]; then
        NTLM_LDAP_SERVER=$(echo "$net_info" | awk -F':' '/^LDAP server:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    fi
    NTLM_LDAP_PORT=$(echo "$net_info" | awk -F':' '/^LDAP port:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    NTLM_BIND_PATH=$(echo "$net_info" | awk -F':' '/^Bind Path:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    NTLM_KDC=$(echo "$net_info" | awk -F':' '/^KDC server:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    NTLM_TIME_OFFSET=$(echo "$net_info" | awk -F':' '/^Server time offset:/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')

    if [[ -n "$NTLM_REALM" ]] && [[ -n "$NTLM_LDAP_SERVER" ]] && [[ -n "$NTLM_BIND_PATH" ]] && [[ -n "$NTLM_KDC" ]]; then
        if net ads testjoin >/dev/null 2>&1; then
            NTLM_STATUS="configured"
        fi
    fi
}

ntlm_print_server_status() {
    if [[ "$NTLM_STATUS" == "configured" ]]; then
        echo "                 NTLM auth already configured:"
        echo "------------------------------------------------------------------------------------------------------"
        printf "                 %-15s: %s\n" "Domain" "$NTLM_REALM"
        printf "                 %-15s: %s\n" "LDAP Server" "${NTLM_LDAP_SERVER}:${NTLM_LDAP_PORT}"
        printf "                 %-15s: %s\n" "Realm" "$NTLM_BIND_PATH"
        printf "                 %-15s: %s\n" "KDC" "$NTLM_KDC"
        printf "                 %-15s: %s\n" "TimeOffset" "$NTLM_TIME_OFFSET"
        echo "------------------------------------------------------------------------------------------------------"
    else
        echo "                 NTLM auth does't configured on the server $(hostname)"
    fi
}

ntlm_collect_kernel_sites() {
    NTLM_KERNEL_SITES=""

    while IFS= read -r settings_file; do
        local site_root
        site_root=$(dirname "$(dirname "$settings_file")")
        if [ -L "$site_root/bitrix" ]; then
            continue
        fi
        NTLM_KERNEL_SITES+="$site_root"$'\n'
    done < <(find "$BS_PATH_USER_HOME_PREFIX" -mindepth 4 -maxdepth 4 -path '*/bitrix/.settings.php' 2>/dev/null | sort)
}

ntlm_get_site_db_info() {
    local site_path=$1
    local output

    output=$(php -r '
    $settings = include $argv[1] . "/bitrix/.settings.php";
    $connection = $settings["connections"]["value"]["default"] ?? [];
    $className = $connection["className"] ?? "";
    $dbType = "Unknown";
    if (stripos($className, "Mysql") !== false) {
        $dbType = "MySQL";
    } elseif (stripos($className, "Pgsql") !== false || stripos($className, "Postgres") !== false) {
        $dbType = "PostgreSQL";
    }
    $dbName = $connection["database"] ?? "Unknown";
    echo $dbType . ":" . $dbName;
    ' "$site_path" 2>/dev/null)

    if [ -z "$output" ]; then
        echo "Unknown:Unknown"
    else
        echo "$output"
    fi
}

ntlm_get_site_status() {
    local site_path=$1
    local output

    output=$(php -r '
    $root = $argv[1];
    $_SERVER["DOCUMENT_ROOT"] = $root;
    $DOCUMENT_ROOT = $root;
    define("NO_KEEP_STATISTIC", true);
    define("NOT_CHECK_PERMISSIONS", true);
    define("BX_NO_ACCELERATOR_RESET", true);
    $prolog = $root . "/bitrix/modules/main/include/prolog_before.php";
    if (!is_file($prolog)) {
        echo "N:N:N";
        exit(0);
    }
    require $prolog;
    $ldapInstalled = \Bitrix\Main\Loader::includeModule("ldap");
    $ldapMod = $ldapInstalled ? "Y" : "N";
    $useNtlm = "N";
    $ldapAuth = "N";
    if ($ldapInstalled) {
        $useNtlm = \Bitrix\Main\Config\Option::get("ldap", "use_ntlm", "N");
        $ldapAuth = COption::GetOptionString("ldap", "bitrixvm_auth_support", "N");
    }
    $normalize = static function ($value) {
        $value = strtoupper(trim((string)$value));
        return in_array($value, ["Y", "1", "YES", "TRUE"], true) ? "Y" : "N";
    };
    echo $normalize($ldapMod) . ":" . $normalize($useNtlm) . ":" . $normalize($ldapAuth);
    ' "$site_path" 2>/dev/null)

    if [ -z "$output" ]; then
        echo "N:N:N"
    else
        echo "$output"
    fi
}

ntlm_site_has_existing_settings() {
    local site_path=$1
    local site_name

    site_name=$(basename "$site_path")

    if [ -f "${BS_PATH_APACHE_SITES_CONF}/ntlm_${site_name}.conf" ] || [ -L "${BS_PATH_APACHE_SITES_ENABLED}/ntlm_${site_name}.conf" ]; then
        return 0
    fi

    return 1
}

ntlm_prepare_site_runtime() {
    path_site_from_links=$BS_PATH_DEFAULT_SITE
    ssl_lets_encrypt="N"
    ssl_lets_encrypt_domain=""
    ssl_lets_encrypt_www="Y"
    ssl_lets_encrypt_email="${BS_EMAIL_ADMIN_FOR_NOTIFY}"
    redirect_to_https="N"
    new_version_php="$default_version"
    php_enable_php_fpm_xdebug=0

    echo
    while true; do
        read_by_def "   Enter the path to site (default: $path_site_from_links): " path_site_from_links "$path_site_from_links"
        if [ -d "$path_site_from_links" ]; then
            break
        fi
        echo "   Incorrect site dir! Please enter site dir"
    done

    domain=$(basename "$path_site_from_links")
    ssl_lets_encrypt_domain="$domain"

    local site_config="${BS_PATH_APACHE_SITES_ENABLED}/${domain}.conf"
    if [ ! -f "$site_config" ]; then
        site_config="${BS_PATH_APACHE_SITES_CONF}/${domain}.conf"
    fi

    local php_socket=""
    if [ -f "$site_config" ]; then
        php_socket=$(sed -n 's/.*SetHandler "proxy:unix:\([^|"]*\).*/\1/p' "$site_config" | head -n1)
    fi

    if [ -n "$php_socket" ]; then
        new_version_php=$(echo "$php_socket" | grep -oP 'php\K[\d.]+' | head -n1)
        if [ -z "$new_version_php" ]; then
            new_version_php="$default_version"
        fi
        if [[ "$php_socket" == *"-xdebug"* ]]; then
            php_enable_php_fpm_xdebug=1
        fi
    fi

    local site_ssl_conf="${BS_PATH_NGINX}/site_settings/${domain}/ssl.conf"
    if [ -f "$site_ssl_conf" ] && grep -q '/etc/letsencrypt/live/' "$site_ssl_conf"; then
        ssl_lets_encrypt="Y"
        local current_ssl_lets_encrypt_domain=""
        current_ssl_lets_encrypt_domain=$(sed -n 's|^[[:space:]]*ssl_certificate[[:space:]]\+/etc/letsencrypt/live/\([^/;[:space:]]\+\)/fullchain\.pem;.*|\1|p' "$site_ssl_conf" | head -n1)
        if [ -n "$current_ssl_lets_encrypt_domain" ]; then
            ssl_lets_encrypt_domain="$current_ssl_lets_encrypt_domain"
        fi
    fi

    if [ -z "$ssl_lets_encrypt_email" ]; then
        ssl_lets_encrypt_email=$(echo "admin@$domain" | "${dir_helpers}/perl/translate.pl")
    fi

    echo -e "\n   Selected PHP version: $new_version_php\n"

    while true; do
        read_by_def "   Enter Y or N for setting SSL Let\`s Encrypt site (default: $ssl_lets_encrypt): " ssl_lets_encrypt "$ssl_lets_encrypt"
        ssl_lets_encrypt="${ssl_lets_encrypt^^}"
        case $ssl_lets_encrypt in
            Y|N) break ;;
            *) echo "   Please enter Y or N." ;;
        esac
    done

    if [ "$ssl_lets_encrypt" == "Y" ]; then
        local generated_ssl_lets_encrypt_email=""

        if [ "$domain" == "$BS_DEFAULT_SITE_NAME" ] && [ "$ssl_lets_encrypt_domain" == "$domain" ]; then
            ssl_lets_encrypt_domain=""
        fi

        while true; do
            read_by_def "   Enter domain for SSL Let\`s Encrypt certificate (default: $ssl_lets_encrypt_domain): " ssl_lets_encrypt_domain "$ssl_lets_encrypt_domain"
            if [ -z "$ssl_lets_encrypt_domain" ]; then
                echo "   Incorrect domain! Please enter another domain"
            else
                break
            fi
        done

        generated_ssl_lets_encrypt_email=$(echo "admin@$domain" | "${dir_helpers}/perl/translate.pl")
        if [ -z "$ssl_lets_encrypt_email" ] || [ "$ssl_lets_encrypt_email" == "$generated_ssl_lets_encrypt_email" ]; then
            ssl_lets_encrypt_email=$(echo "admin@$ssl_lets_encrypt_domain" | "${dir_helpers}/perl/translate.pl")
        fi

        read_by_def "   Enter Y or N to get a certificate for WWW (default: $ssl_lets_encrypt_www): " ssl_lets_encrypt_www "$ssl_lets_encrypt_www"
        read_by_def "   Enter email for SSL Let\`s Encrypt (default: $ssl_lets_encrypt_email): " ssl_lets_encrypt_email "$ssl_lets_encrypt_email"
        ssl_lets_encrypt_www="${ssl_lets_encrypt_www^^}"
    fi
}

ntlm_print_sites_status() {
    ntlm_collect_kernel_sites

    local count=0
    while IFS= read -r site_root; do
        [ -z "$site_root" ] && continue
        count=$((count + 1))
    done <<< "$NTLM_KERNEL_SITES"

    if [ "$count" -eq 0 ]; then
        echo "                 Not found kernel sites on the server"
        return 0
    fi

    echo "                 Found $count kernel sites:"
    echo "------------------------------------------------------------------------------------------------------"
    printf "%-15s | %-11s | %-15s | %7s | %7s | %8s | %s\n" "SiteName" "DBType" "dbName" "LDAPMod" "UseNTLM" "LDAPAuth" "DocumentRoot"
    echo "------------------------------------------------------------------------------------------------------"

    while IFS= read -r site_root; do
        [ -z "$site_root" ] && continue

        local site_name
        local db_info
        local db_type
        local db_name
        local ntlm_info
        local ldap_mod
        local use_ntlm
        local ldap_auth

        site_name=$(basename "$site_root")
        db_info=$(ntlm_get_site_db_info "$site_root")
        db_type=$(echo "$db_info" | awk -F':' '{print $1}')
        db_name=$(echo "$db_info" | cut -d':' -f2-)
        ntlm_info=$(ntlm_get_site_status "$site_root")
        ldap_mod=$(echo "$ntlm_info" | awk -F':' '{print $1}')
        use_ntlm=$(echo "$ntlm_info" | awk -F':' '{print $2}')
        ldap_auth=$(echo "$ntlm_info" | awk -F':' '{print $3}')

        printf "%-15s | %-11s | %-15s | %7s | %7s | %8s | %s\n" "$site_name" "$db_type" "$db_name" "$ldap_mod" "$use_ntlm" "$ldap_auth" "$site_root"
    done <<< "$NTLM_KERNEL_SITES"

    echo "------------------------------------------------------------------------------------------------------"
}

configure_ntlm_auth_for_site() {
    clear
    list_sites
    ntlm_get_server_status

    if [[ "$NTLM_STATUS" == "configured" ]]; then
        echo
        echo "   The host is already in the domain."
        echo
        read -r -p "   Do you want to change NTLM settings for the server? (N|y): " answer
        case ${answer:-N} in
            [Yy]*) ;;
            *) return 0 ;;
        esac
    fi

    ntlm_host=$(hostname | awk -F'.' '{print $1}')
    ntlm_name="$NTLM_WORKGROUP"
    ntlm_fqdn="$NTLM_REALM"
    ntlm_dps="$NTLM_LDAP_SERVER"
    ntlm_user="Administrator"

    local ntlm_pass=""

    while true; do
        read_by_def "   NetBIOS Hostname (default $ntlm_host): " ntlm_host "$ntlm_host"
        if [ -z "$ntlm_host" ]; then
            echo "   NetBIOS Hostname cannot be empty. Try again."
            continue
        fi
        if [ ${#ntlm_host} -gt 15 ]; then
            echo "   NetBIOS Hostname must be 15 characters or less."
            continue
        fi

        read_by_def "   NetBIOS Domain/Workgroup Name (ex. TEST): " ntlm_name "$ntlm_name"
        if [ -z "$ntlm_name" ]; then
            echo "   NetBIOS Domain Name cannot be empty. Try again."
            continue
        fi

        read_by_def "   Full Domain Name: (ex. TEST.LOCAL): " ntlm_fqdn "$ntlm_fqdn"
        if [ -z "$ntlm_fqdn" ]; then
            echo "   Full Domain Name cannot be empty. Try again."
            continue
        fi

        read_by_def "   Domain password server (ex. TEST-DC-SP.TEST.LOCAL): " ntlm_dps "$ntlm_dps"
        if [ -z "$ntlm_dps" ]; then
            echo "   Domain password server cannot be empty. Try again."
            continue
        fi

        read_by_def "   Domain admin user name (default Administrator): " ntlm_user "$ntlm_user"
        if [ -z "$ntlm_user" ]; then
            echo "   User name cannot be empty. Try again."
            continue
        fi

        read -r -s -p "   Domain admin user password:  " ntlm_pass
        echo
        if [ -z "$ntlm_pass" ]; then
            echo "   Password cannot be empty. Try again."
            continue
        fi
        break
    done

    echo -e "\n   NTLM Settings:"
    echo "------------------------------------------------------------------------------------------------------"
    printf "   %-18s: %s\n" "NetBIOS Domain" "$ntlm_name"
    printf "   %-18s: %s\n" "NetBIOS Hostname" "$ntlm_host"
    printf "   %-18s: %s\n" "Full Domain Name" "$ntlm_fqdn"
    printf "   %-18s: %s\n" "Password Server" "$ntlm_dps"
    printf "   %-18s: %s\n" "Domain User" "$ntlm_user"
    echo "------------------------------------------------------------------------------------------------------"
    echo "   The site and its shared sites will be configured to use NTLM."

    ntlm_prepare_site_runtime

    if ntlm_site_has_existing_settings "$path_site_from_links"; then
        echo
        echo "   NTLM settings found on the site $domain."
        read -r -p "   Do you want to change them? (N|y): " answer
        case ${answer:-N} in
            [Yy]*) ;;
            *) return 0 ;;
        esac
    fi

    echo -e "\n   Entered data:\n"
    echo "   Domain: $domain"
    echo "   Path to site: $path_site_from_links"
    echo "   Selected PHP version: $new_version_php"
    echo "   SSL Let\`s Encrypt: $ssl_lets_encrypt"
    if [ "$ssl_lets_encrypt" == "Y" ]; then
        echo "   SSL Let\`s Encrypt domain: $ssl_lets_encrypt_domain"
        echo "   Get a certificate for WWW: $ssl_lets_encrypt_www"
        echo "   SSL Let\`s Encrypt email: $ssl_lets_encrypt_email"
    fi
    echo

    while true; do
        read -r -p "   Do you really want to configure NTLM auth? (Y/N): " answer
        case $answer in
            [Yy]* )
                ntlm_action="create"
                ntlm_prepare_password_file "$ntlm_pass"
                if action_configure_ntlm_auth; then
                    echo -e "\n   'configure' NTLM auth successfully executed."
                else
                    echo -e "\n   Error: 'configure' NTLM auth failed." >&2
                fi
                ntlm_cleanup_password_file
                read -r -p "   Press any key to return to the menu..." key
                break
            ;;
            [Nn]* )
                ntlm_cleanup_password_file
                break
            ;;
            * ) echo "   Please enter Y or N." ;;
        esac
    done
}

use_existing_ntlm_auth_for_site() {
    clear
    list_sites
    ntlm_get_server_status

    if [[ "$NTLM_STATUS" != "configured" ]]; then
        echo
        echo "   NTLM auth does't configured on the server $(hostname)"
        read -r -p "   Press any key to return to the menu..." key
        return 0
    fi

    ntlm_prepare_site_runtime

    if ntlm_site_has_existing_settings "$path_site_from_links"; then
        echo
        echo "   NTLM settings found on the site $domain."
        read -r -p "   Do you want to change them? (N|y): " answer
        case ${answer:-N} in
            [Yy]*) ;;
            *) return 0 ;;
        esac
    fi

    ntlm_action="use_existing"
    ntlm_name="$NTLM_WORKGROUP"
    ntlm_fqdn="$NTLM_REALM"
    ntlm_dps="$NTLM_LDAP_SERVER"
    ntlm_host=$(hostname | awk -F'.' '{print $1}')
    ntlm_user="Administrator"
    ntlm_pass_file=""

    echo -e "\n   Entered data:\n"
    echo "   Domain: $domain"
    echo "   Path to site: $path_site_from_links"
    echo "   Selected PHP version: $new_version_php"
    echo "   SSL Let\`s Encrypt: $ssl_lets_encrypt"
    if [ "$ssl_lets_encrypt" == "Y" ]; then
        echo "   SSL Let\`s Encrypt domain: $ssl_lets_encrypt_domain"
        echo "   Get a certificate for WWW: $ssl_lets_encrypt_www"
        echo "   SSL Let\`s Encrypt email: $ssl_lets_encrypt_email"
    fi
    echo

    while true; do
        read -r -p "   Do you really want to use existing NTLM settings? (Y/N): " answer
        case $answer in
            [Yy]* )
                if action_configure_ntlm_auth; then
                    echo -e "\n   'configure' NTLM auth successfully executed."
                else
                    echo -e "\n   Error: 'configure' NTLM auth failed." >&2
                fi
                read -r -p "   Press any key to return to the menu..." key
                break
            ;;
            [Nn]* ) break ;;
            * ) echo "   Please enter Y or N." ;;
        esac
    done
}

delete_ntlm_auth_settings() {
    clear
    list_sites
    ntlm_get_server_status

    if [[ "$NTLM_STATUS" != "configured" ]]; then
        echo
        echo "   NTLM auth does't configured on the server $(hostname)"
        read -r -p "   Press any key to return to the menu..." key
        return 0
    fi

    ntlm_host=$(hostname | awk -F'.' '{print $1}')
    ntlm_name="$NTLM_WORKGROUP"
    ntlm_fqdn="$NTLM_REALM"
    ntlm_dps="$NTLM_LDAP_SERVER"
    ntlm_user="Administrator"

    local ntlm_pass=""

    echo
    while true; do
        read_by_def "   NetBIOS Hostname (default $ntlm_host): " ntlm_host "$ntlm_host"
        read_by_def "   NetBIOS Domain/Workgroup Name (ex. TEST): " ntlm_name "$ntlm_name"
        read_by_def "   Full Domain Name: (ex. TEST.LOCAL): " ntlm_fqdn "$ntlm_fqdn"
        read_by_def "   Domain password server (ex. TEST-DC-SP.TEST.LOCAL): " ntlm_dps "$ntlm_dps"
        read_by_def "   Domain admin user name (default Administrator): " ntlm_user "$ntlm_user"
        read -r -s -p "   Domain admin user password:  " ntlm_pass
        echo
        if [ -z "$ntlm_pass" ]; then
            echo "   Password cannot be empty. Try again."
            continue
        fi
        break
    done

    echo -e "\n   NTLM Settings:"
    echo "------------------------------------------------------------------------------------------------------"
    printf "   %-18s: %s\n" "NetBIOS Domain" "$ntlm_name"
    printf "   %-18s: %s\n" "NetBIOS Hostname" "$ntlm_host"
    printf "   %-18s: %s\n" "Full Domain Name" "$ntlm_fqdn"
    printf "   %-18s: %s\n" "Password Server" "$ntlm_dps"
    printf "   %-18s: %s\n" "Domain User" "$ntlm_user"
    echo "------------------------------------------------------------------------------------------------------"
    echo

    while true; do
        read -r -p "   Do you really want to delete NTLM settings? (Y/N): " answer
        case $answer in
            [Yy]* )
                ntlm_action="delete"
                domain=""
                path_site_from_links=""
                ssl_lets_encrypt="N"
                ssl_lets_encrypt_www="Y"
                ssl_lets_encrypt_email=""
                ntlm_prepare_password_file "$ntlm_pass"
                if action_configure_ntlm_auth; then
                    echo -e "\n   'delete' NTLM auth successfully executed."
                else
                    echo -e "\n   Error: 'delete' NTLM auth failed." >&2
                fi
                ntlm_cleanup_password_file
                read -r -p "   Press any key to return to the menu..." key
                break
            ;;
            [Nn]* )
                ntlm_cleanup_password_file
                break
            ;;
            * ) echo "   Please enter Y or N." ;;
        esac
    done
}

menu_ntlm_auth_sites() {
    comand=;
    until [[ "$comand" == "0" ]]; do
    clear;
    list_sites;
    ntlm_get_server_status;

    echo -e "\n          Menu -> Configure NTLM auth for sites:\n";
    ntlm_print_sites_status;
    echo;
    ntlm_print_server_status;
    echo;
    echo "                 Available actions: ";
    echo "                 1. Configure NTLM settings for the site";
    if [[ "$NTLM_STATUS" == "configured" ]]; then
        echo "                 2. Use existing NTLM settings for the site";
        echo "                 3. Delete NTLM settings";
    fi
    echo "                 0. Previous screen or exit";
    echo;
    read -r -p "Enter your choice: " comand

    case $comand in
      "1") configure_ntlm_auth_for_site ;;
      "2")
        if [[ "$NTLM_STATUS" == "configured" ]]; then
            use_existing_ntlm_auth_for_site
        else
            echo "Error unknown command"
        fi
      ;;
      "3")
        if [[ "$NTLM_STATUS" == "configured" ]]; then
            delete_ntlm_auth_settings
        else
            echo "Error unknown command"
        fi
      ;;
      0|z) return ;;
      *) echo "Error unknown command" ;;
    esac
    done
}

show_sites_dirs(){
  clear;
  list_sites;

  press_any_key_to_return_menu;
}

get_lets_encrypt_certificate(){
  clear;
  list_sites;

    domain=''
    email="${BS_EMAIL_ADMIN_FOR_NOTIFY}";

    path_site="${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME}"
    redirect_to_https="N";
    is_www="Y";

    echo -e "\n   Menu -> Configure Let\`s Encrypt certificate:\n";
    while [[ -z "$domain" ]]; do
          read_by_def "   Enter site domain (example: example.com): " domain $domain;
        if [ -z "$domain" ]; then
          echo "   Incorrect site domain! Please enter another site domain";
        fi
    done
    if [ -z "$email" ]; then
      email=$(echo "admin@$domain" | "${dir_helpers}/perl/translate.pl")
    fi

    read_by_def "   Enter full path to site (default: $path_site): " path_site $path_site;
    read_by_def "   Enter Y or N to get a certificate for WWW (default: $is_www): " is_www $is_www;
    read_by_def "   Enter email (default: $email): " email $email;
    read_by_def "   Enter Y or N for redirecting HTTP to HTTPS (default: $redirect_to_https): " redirect_to_https $redirect_to_https;
    redirect_to_https="${redirect_to_https^^}"
    is_www="${is_www^^}"

    echo -e "\n   Entered data:\n"
    echo "   Domain: $domain";
    echo "   Full path to site: $path_site";
    echo "   Get a certificate for WWW: $is_www"
    echo "   Email: $email"
    echo "   Redirecting HTTP to HTTPS: $redirect_to_https"

    echo -e "\n\n"

    while true; do
        read -r -p "   Do you really want to create a SSL Let\`s Encrypt certificate? (Y/N): " answer
        case $answer in
            [Yy]* ) action_get_lets_encrypt_certificate; break;;
            [Nn]* ) break;;
            * ) echo "   Please enter Y or N.";;
        esac
    done
}

enable_or_disable_redirect_http_to_https(){
  clear;
  list_sites;

  site=$BS_DEFAULT_SITE_NAME;
  path_site_from_links=$BS_PATH_DEFAULT_SITE

  echo -e "\n   Enable or Disable redirecting HTTP to HTTPS:\n";

  read_by_def "  Enter path to site (default: $path_site_from_links): " path_site_from_links $path_site_from_links;

        # Extract domain name from link
        site=$(basename "$path_site_from_links")

  while [[ -z "$site" ]] || ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; do

      if [ -z "$site" ]; then
        echo "   Incorrect site dir! Please enter site dir";
        read_by_def "   Enter site dir: " site "${site}";
      elif ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; then
        site='';
        echo "   Domain does not exist! You can use exists domain";
        read_by_def "   Enter site dir: " site "${site}";
      fi
  done

  current_state='disabled';
  action='enable';

  local index=0
  while [[ -n "${ARR_ALL_USERS_DIR_SITES_DATA["${index}_dir"]}" ]]; do
    if [[ "${ARR_ALL_USERS_DIR_SITES_DATA["${index}_dir"]}" == "$site" ]]; then
      if [[ "${ARR_ALL_USERS_DIR_SITES_DATA[$index,is_https]}" == "Y" ]]; then
        current_state='enabled';
        action='disable';
      fi
      break;
    fi
    ((index++))
  done

    echo "   Your site $site redirecting HTTP to HTTPS status: $current_state";

    extract_username_from_path

    path_site="$BS_PATH_SITES/$site"

  while true; do
    read -r -p "   Do you really want to $action redirect HTTP to HTTPS? (Y/N): " answer
    case $answer in
      [Yy]* ) action_enable_or_disable_redirect_http_to_https; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

enable_or_disable_bot_blocker(){
  clear;
  list_sites;

  site=$BS_DEFAULT_SITE_NAME;
  path_site_from_links=$BS_PATH_DEFAULT_SITE

  echo -e "\n   Enable or Disable Nginx Bad Bot and User-Agent Blocker, Spam Referrer Blocker, Anti DDOS, Bad IP Blocker and Wordpress Theme Detector Blocker:\n";

  read_by_def "  Enter path to site (default: $path_site_from_links): " path_site_from_links $path_site_from_links;

        # Extract domain name from link
        site=$(basename "$path_site_from_links")

  while [[ -z "$site" ]] || ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; do

      if [ -z "$site" ]; then
        echo "   Incorrect site dir! Please enter site dir";
        read_by_def "   Enter site dir: " site "${site}";
      elif ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; then
        site='';
        echo "   Domain does not exist! You can use exists domain";
        read_by_def "   Enter site dir: " site "${site}";
      fi
  done



  if [ -s "${BS_PATH_NGINX}"/site_settings/"${site}"/bots_block.conf ]; then
        current_state='enabled';
        action='disable';
  else
      current_state='disabled';
      action='enable';
  fi

    echo "   Your site $site Bad Bot status: $current_state";

    extract_username_from_path

    path_site="$BS_PATH_SITES/$site"

  while true; do
    read -r -p "   Do you really want to $action Bad Bot? (Y/N): " answer
    case $answer in
      [Yy]* ) action_enable_or_disable_bot_blocker; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}




check_ftp_user_exists() {
    pure-pw show "$1" >/dev/null 2>&1
    return $?
}

list_ftp_users() {
    pure-pw list | awk '{print $1}'
}


generate_unique_ftp_username() {
    local base_name="${BS_USER_SERVER_SITES}-ftp-"
    local counter=0
    local username

    while true; do
        username="${base_name}$(printf "%04d" $counter)"
        if ! check_ftp_user_exists "$username"; then
            echo "$username"
            return
        fi
        ((counter++))
    done
}
add_remove_ftp_user(){
    clear;
    list_sites;

    pureftp_action='C'
    ftp_user_name=''
    ftp_password=$(generate_password $BS_CHAR_DB_PASSWORD)
    path_site_from_links=$BS_PATH_DEFAULT_SITE


      echo -e "\n   Menu -> Create or Delete FTP user:\n";
      while true; do
        read -r -p "   Do you want to Create or Delete FTP-user? (C/D) [${pureftp_action}]: " answer
        answer=${answer:-$pureftp_action}
        case $answer in
          [Cc]* ) pureftp_action=create; break;;
          [Dd]* ) pureftp_action=delete; break;;
          * ) printf "   Please enter C or D.\n";;
        esac
      done


        case $pureftp_action in
      create )
        read_by_def "   Enter path to ftp directory (default: $path_site_from_links): " path_site_from_links "${path_site_from_links}";

        extract_username_from_path

        ftp_user_uid=$(id -u "${BS_USER_SERVER_SITES}")


        # Generate a unique username
        auto_generated_username=$(generate_unique_ftp_username)

        # Prompt the user with the auto-generated username as default
        read -r -p "   Enter FTP username [${auto_generated_username}]: " ftp_user_name

        # If the user didn't enter anything, use the auto-generated username
        ftp_user_name=${ftp_user_name:-$auto_generated_username}

        # Check if the entered username already exists
        while check_ftp_user_exists "$ftp_user_name"; do
            read -p "   User already exists. Enter a different username: " ftp_user_name
        done

        # Generate a random password
        auto_generated_password=$(openssl rand -base64 12)

        # Prompt the user with the auto-generated password as default
        read -r -s -p "   Enter FTP user password [${auto_generated_password}]: " ftp_user_password
        echo

        # If the user didn't enter anything, use the auto-generated password
        ftp_user_password=${ftp_user_password:-$auto_generated_password}

      ;;
      delete )
        echo "List of FTP users:"
        mapfile -t users < <(list_ftp_users)
        for i in "${!users[@]}"; do
            echo "$((i+1)). ${users[i]}"
        done

        read -r -p "   Enter the number of the user you want to delete (or 0 to cancel): " user_number

        if [[ $user_number -gt 0 && $user_number -le ${#users[@]} ]]; then
            ftp_user_name="${users[$((user_number-1))]}"
            read -r -p "   Are you sure you want to delete user '$ftp_user_name'? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo "   User '$ftp_user_name' selected for deletion."
            else
                echo "   Deletion cancelled."
                ftp_user_name=""
            fi
        elif [[ $user_number -eq 0 ]]; then
            echo "   Deletion cancelled."
            ftp_user_name=""
        else
            echo "   Invalid selection. Deletion cancelled."
            ftp_user_name=""
        fi
      ;;
    esac

#    echo -e "\n   Entered data:\n"
    echo "   Task: $pureftp_action ftp user";

    case $answer in
      create )
        echo "   FTP-username: $ftp_user_name";
        echo "   FTP directory: $path_site_from_links"
        echo "   FTP-password: $ftp_user_password";
      ;;
      delete )
        echo "   FTP-username: $ftp_user_name"
      ;;
    esac

    while true; do
      read -r -p "   Do you really want to $pureftp_action an FTP user? (Y/N): " answer
      case $answer in
        [Yy]* ) 
          if action_add_remove_ftp_user; then
            echo -e "\n   '${pureftp_action}' FTP user successfully executed."
          else
            echo -e "\n   Error: '${pureftp_action}' FTP user failed." >&2
          fi
          read -r -p "   Press any key to return to the menu..." key
          break
        ;;
        [Nn]* ) break;;
        * ) echo "   Please enter Y or N.";;
      esac
    done

}

enable_or_disable_basic_auth(){
    clear;
    list_sites;

    basic_auth_action='C'
    htpasswd_username=${BS_NGINX_BASIC_AUTH_LOGIN}
    htpasswd_password=${BS_NGINX_BASIC_AUTH_PASSWORD}
    path_site_from_links=$BS_PATH_DEFAULT_SITE

    echo -e "\n   Menu -> Create or Delete Basic Auth:\n";
    while true; do
        read -r -p "   Do you want to Create or Delete Basic Auth? (C/D) [${basic_auth_action}]: " answer
        answer=${answer:-$basic_auth_action}
        case $answer in
            [Cc]* ) basic_auth_action=create; break;;
            [Dd]* ) basic_auth_action=delete; break;;
            * ) printf "   Please enter C or D.\n";;
        esac
    done

    case $basic_auth_action in
        create )
            read -r -p "   Enter path to site directory (default: $path_site_from_links): " input_path
            path_site_from_links=${input_path:-$path_site_from_links}

            # Extract domain name from link
            site=$(basename "$path_site_from_links")

            # Prompt the user with the username from .env as default
            read -r -p "   Enter Basic Auth username [${htpasswd_username}]: " input_username
            htpasswd_username=${input_username:-$htpasswd_username}

            # Prompt the user with the auto-generated password as default
            read -r -p "   Enter Basic Auth password [${htpasswd_password}]: " input_password
            htpasswd_password=${input_password:-$htpasswd_password}
            echo
        ;;
        delete )
            # Ensure `delete` action still captures the necessary values
            read -r -p "   Enter path to site directory (default: $path_site_from_links): " input_path
            path_site_from_links=${input_path:-$path_site_from_links}

            site=$(basename "$path_site_from_links")
        ;;
    esac

    htpasswd_path_file=${BS_PATH_NGINX}/site_settings/${site}/.htpasswd
    htpasswd_basic_auth_conf=${BS_PATH_NGINX}/site_settings/${site}/basic_auth.conf


    echo -e "\n   Entered data:\n"
    echo "   Task: $basic_auth_action basic auth"
    case $basic_auth_action in
        create )
            echo "   Username: $htpasswd_username"
            echo "   Password: $htpasswd_password"
            echo "   Site: $path_site_from_links"
        ;;
        delete )
            echo "   Site: $path_site_from_links"
        ;;
    esac

    while true; do
        read -r -p "   Do you really want to $basic_auth_action basic auth? (Y/N): " confirm_action
        case $confirm_action in
            [Yy]* )
                if action_enable_or_disable_basic_auth; then
                    echo -e "\n   '${basic_auth_action}' basic auth successfully executed."
                else
                    echo -e "\n   Error: '${basic_auth_action}' basic auth failed." >&2
                fi
                read -r -p "   Press any key to return to the menu..." key
                break
            ;;
            [Nn]* ) break;;
            * ) echo "   Please enter Y or N.";;
        esac
    done
}


block_access_by_ip() {
  echo -e "\n   Menu -> Block/Unblock access by IP:\n"

  if [ -h "${BS_PATH_NGINX_SITES_ENABLED}"/bx_ext_ip.conf ]; then
        current_state='enabled';
        action='disable';
  else
      current_state='disabled';
      action='enable';
  fi

    echo "   Blocking access to ${BS_SERVICE_NGINX_NAME} by server ip addresses is: $current_state";

    read -r -p "   Do you really want to $action Blocking access? (Y/N): " answer
    case $answer in
      [Yy]* )
      if [ $action == 'enable' ]; then
        if enable_ip_blocking; then
        echo "Block completed successfully."
      else
        echo "Block failed to complete."
      fi
      read -n 1 -s -r -p "Press any key to continue..."
      else
        if rm -f "${BS_PATH_NGINX_SITES_ENABLED}/bx_ext_ip.conf"; then
          echo "Unblock completed successfully."
        else
          echo "Unblock failed to complete."
        fi
        read -n 1 -s -r -p "Press any key to continue..."
      fi
        ;;
      [Nn]* ) return;;
      * ) echo "   Please enter Y or N.";;
    esac
}

enable_ip_blocking() {
  ip=$(hostname -I)
  cat <<EOT > "${BS_PATH_NGINX_SITES_CONF}/bx_ext_ip.conf"
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name ${ip};
    
    ssl_reject_handshake on;

    
    location / {
        return 444;
    }
}
EOT

  cd "${BS_PATH_NGINX_SITES_ENABLED}" && \
  ln -sf "${BS_PATH_NGINX_SITES_CONF}/bx_ext_ip.conf" . && \
  "${BS_SERVICE_NGINX_NAME}" -t && \
  systemctl reload "${BS_SERVICE_NGINX_NAME}"
  
}


function update_menu(){
    clear;

    if [ -z "${BS_URL_SCRIPT_UPDATE_MENU}" ]; then
      echo -e "Variable BS_URL_SCRIPT_UPDATE_MENU is not defined\n";
      press_any_key_to_return_menu;
      return 0;
    fi

    while true; do
    read -r -p "   Do you really want to update menu? (Y/N): " answer
    case $answer in
      [Yy]* ) action_update_menu; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function update_server(){
    clear;

    while true; do
    read -r -p "   Do you really want to update server? (Y/N): " answer
    case $answer in
      [Yy]* ) action_update_server; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function change_php_version() {
    clear;
    get_current_version_php
    get_available_version_php

    new_version_php=''
    while [[ -z "$new_version_php" ]]; do
        read_by_def "   Enter PHP version: (example: 8.2 or php8.2): " new_version_php $new_version_php;
        if [ -z "$new_version_php" ]; then
        echo "   Incorrect PHP version! Please enter PHP version";
        fi
    done

    new_version_php="${new_version_php^^}"
    new_version_php=$(echo "$new_version_php" | sed -e 's/PHP//')

    echo -e "\n   Selected PHP version: $new_version_php\n"

    php_set_manual=N
    while true; do
      read -r -p "   Set this version of php as the default version? All sites on ${BS_DEFAULT_USER_SERVER_SITES} that use the default version will be switched to this version. (Y/N)[${php_set_manual}]: " answer
            answer=${answer:-$php_set_manual}
      case ${answer,,} in
        y ) php_set_manual=1; break;;
        n ) php_set_manual=0; break;;
        * ) echo "   Please enter Y or N.";;
      esac
    done

    while true; do
      read -r -p "   Do you really want to add PHP version? (Y/N): " answer
      case ${answer,,} in
        y ) action_change_php_version; break;;
        n ) break;;
        * ) echo "   Please enter Y or N.";;
      esac
    done
}


function settings_smtp_sites() {
    clear;
    list_sites;

    site=$BS_DEFAULT_SITE_NAME;
    email_from="";
    host="";
    port="465";
    is_auth="Y";
    login="";
    password="";
    authentication_method="auto";
    enable_TLS="Y";

    echo -e "\n   Menu -> Settings SMTP sites:\n";

    read_by_def "   Enter site dir (default: $site): " site $site;

    while [[ -z "$site" ]] || ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; do
      if [ -z "$site" ]; then
        echo "   Incorrect site dir! Please enter site dir";
        read_by_def "   Enter site dir: " site $site;
      elif ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; then
        site='';
        echo "   Site dir does not exist! You can use exists site dir";
        read_by_def "   Enter site dir: " site $site;
      fi
    done

    if [[ $site == "$BS_DEFAULT_SITE_NAME" ]]; then
      site="default"
    fi

    pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}")
    res=$(ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
      -e "print_account=Y \
      account_name=${site} \
      smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
      smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
      smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
      smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
      smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
      smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG} \
      smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \
      path_sites=${BS_PATH_SITES}")

    res=$(echo "$res" | grep -oP '(?<=start_parse).*?(?=end_parse)' | sed 's/\\n/\n/g')

    trim_for_test="${res//[[:space:]]}"

    action="create"
    if [ -z "$trim_for_test" ]; then
      echo -e "\e[1;34m\n   The ${site} account was not found. Creating a new account:\n\e[0m"
      else
      action="update"
      echo -e "\e[33m\n   The ${site} account has been found. Here are his settings:\n\e[0m"
      echo -e "     $res\n"
    fi

    read_by_def "   Enter From email address (example: test@example.com): " email_from $email_from;
    read_by_def "   Enter SMTP server address ( smtp.yandex.ru / smtp.gmail.com / smtp.mail.ru / mail.domain.tld ): " host $host;
    read_by_def "   Enter SMTP server port (default: ${port}): " port $port;

    read_by_def "   Enter Y or N for to use SMTP authentication on ${host}:${port} (default: $is_auth): " is_auth $is_auth;
    is_auth="${is_auth^^}"

    if [[ $is_auth == "Y" ]]; then
      login="${email_from}"
      read_by_def "   Enter login (default: $login): " login $login;
      read_by_def "   Enter password: " password $password;
      echo -e "\e[1;34m\n   Available methods are plain,scram-sha-1,cram-md5,gssapi,external,digest-md5,login,ntlm\n\e[0m"
      read_by_def "   Enter SMTP authentication method (default: $authentication_method): " authentication_method $authentication_method;
    fi

    read_by_def "   Enter Y or N to enable TLS for ${host}:${port} (default: $enable_TLS): " enable_TLS $enable_TLS;
    enable_TLS="${enable_TLS^^}"

    echo -e "\n   Entered data:\n"
    echo "   Site dir (account): $site";
    echo "   From email address: $email_from";
    echo "   Server address or DNS: $host"
    echo "   Server port: $port"
    echo "   Use SMTP authentication: $is_auth"

    if [[ $is_auth == "Y" ]]; then
      echo "   Login: $login"
      echo "   Password: $password"
      echo "   SMTP authentication method: $authentication_method"
    fi

    echo "   Enable TLS: $enable_TLS"

    echo -e "\n\n"

    while true; do
        read -r -p "   Do you really want to ${action} a SMTP account? (Y/N): " answer
        case $answer in
            [Yy]* ) action_settings_smtp_sites; break;;
            [Nn]* ) break;;
            * ) echo "   Please enter Y or N.";;
        esac
    done
}

function reboot_server() {
  clear
  while true; do
    read -r -p $'   Do you really want to\e[33m RESTART \e[0mserver? (Y/N): ' answer
    case $answer in
        [Yy]* ) reboot; break;;
        [Nn]* ) break;;
        * ) echo "   Please enter Y or N.";;
    esac
  done
}

function power_off_server() {
  clear
  while true; do
    read -r -p $'   Do you really want to\e[33m SHUT DOWN \e[0mserver? (Y/N): ' answer
    case $answer in
        [Yy]* ) poweroff; break;;
        [Nn]* ) break;;
        * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_netdata() {
  clear

  is_install_netdata=$(which netdata);
  action="INSTALL"
  if [ ! -z "$is_install_netdata" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Netdata? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_netdata; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_sphinx() {
  clear

  action="INSTALL"
  if dpkg-query -W -f='${Status}' sphinxsearch 2>/dev/null | grep -q "ok installed"; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Sphinx? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_sphinx; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_file_conversion_server() {
  clear
  domain='';
  full_path_site="${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME}";
  action="INSTALL";
  if dpkg -l | grep -q rabbitmq-server; then
      action="DELETE"
  fi

  if [ $action == "INSTALL" ]; then
    list_sites;
    echo -e "\n";

    while [[ -z "$domain" ]]; do
      read_by_def "   Enter site domain (example: example.com): " domain $domain;
      if [ -z "$domain" ]; then
        echo "   Incorrect site domain! Please enter another site domain";
      fi
    done

    read_by_def "   Enter full path to site (default: $full_path_site): " full_path_site $full_path_site;

    echo -e "\n   Entered data:\n"
    echo "   Domain: $domain";
    echo "   Full path site: $full_path_site";
    echo -e "\n";
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")File Conversion Server (transformer)? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_file_conversion_server; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_crowdsec() {
  clear

  is_install_crowdsec=$(which crowdsec);
  action="INSTALL"
  if [ ! -z "$is_install_crowdsec" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Crowdsec? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_crowdsec; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_rkhunter() {
  clear

  is_install_rkhunter=$(which rkhunter);
  action="INSTALL"
  if [ -n "$is_install_rkhunter" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Rkhunter? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_rkhunter; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_linux_malware_detect() {
  clear

  is_install_linux_malware_detect=$(which maldet);
  action="INSTALL"
  if [ -n "$is_install_linux_malware_detect" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Maldet? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_maldet; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_memcached() {
  clear

  is_install_memcached=$(which memcached);
  action="INSTALL"
  if [ -n "$is_install_memcached" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")memcached? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_memcached; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_deadsnakes_ppa() {
  clear

  is_install_deadsnakes_ppa=$(grep -R "deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/);
  action="INSTALL"
  if [ -n "$is_install_deadsnakes_ppa" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Deadsnakes PPA? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_deadsnakes_ppa; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}


function install_docker() {
  clear

  is_install_docker=$(which docker);
  action="INSTALL"
  if [ -n "$is_install_docker" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  if [ "$action" == "DELETE" ]; then
      docker_packages_state='absent'
  else
      docker_packages_state='present'
  fi

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")docker? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_docker; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}


function install_delete_pgbouncer() {
  clear

  is_install_delete_pgbouncer=$(which pgbouncer);
  action="INSTALL"
  pgbouncer_state="present"
  if [ -n "$is_install_delete_pgbouncer" ]; then
      action="DELETE"
      pgbouncer_state="absent"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")pgbouncer? (Y/N): " answer
    case $answer in
      [Yy]* ) action_add_delete_pgbouncer; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}


function install_postgresql() {
  clear
  local versions filtered_versions distro_postgresql_version
  versions=$(get_installed_postgresql_versions)
  filtered_versions=$(validate_numeric_version "$versions")
  
  for version in $filtered_versions; do
      get_postgresql_info "$version"
  done

  postgresql_repository_source="${BS_POSTGRESQL_REPOSITORY_SOURCE}"
  postgresql_version="${BS_POSTGRESQL_VERSION}"
  postgresql_port='5432'

  action="INSTALL"

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read_by_def "   Enter PostgreSQL repository source (official/distro) [${postgresql_repository_source}]: " postgresql_repository_source "${postgresql_repository_source}"
    postgresql_repository_source="${postgresql_repository_source,,}"
    case "${postgresql_repository_source}" in
      official|distro) break ;;
      *) echo "   Please enter official or distro." ;;
    esac
  done

  if [ "${postgresql_repository_source}" = "distro" ]; then
    distro_postgresql_version=$(get_distribution_postgresql_version)
    if [ -z "${distro_postgresql_version}" ]; then
      echo "   Unable to determine PostgreSQL version from distribution repository."
      press_any_key_to_return_menu
      return 1
    fi
    postgresql_version="${distro_postgresql_version}"
    echo "   Distribution repository version: ${postgresql_version}"
  else
    read -r -p "   Avaliable version: https://wiki.postgresql.org/wiki/Apt
   Enter postgresql version (default: $postgresql_version): " input_version
    postgresql_version=${input_version:-$postgresql_version}
  fi

  read -r -p "   Specify the port that this version will use (default: $postgresql_port): " input_port
  postgresql_port=${input_port:-$postgresql_port}

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")PostgreSQL? (Y/N): " answer
    case $answer in
      [Yy]* ) action_add_postgresql; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done

}

get_installed_postgresql_versions() {
    local versions
    versions=$(get_installed_postgresql_versions_raw)
    printf "   Installed versions: %s\n" "$versions"
}

validate_numeric_version() {
    local version_list="$1" valid_versions=""
    for version in $version_list; do
        if [[ "$version" =~ ^[0-9]+$ ]]; then
            valid_versions+="$version "
        fi
    done
    printf '%s\n' "$valid_versions"
}
get_postgresql_info() {
    local version=$1
    local port socket
    port=$(get_postgresql_port_by_version "$version")
    socket="/run/postgresql/.s.PGSQL.$port"

    if [ -n "$port" ] && [ -S "$socket" ]; then
        printf "   \n   Version: %s\n   Port: %s\n   Unix socket: %s\n\n" "$version" "$port" "$socket"
        export postgresql_port="$port"
        export postgresql_socket="$socket"
        return 0
    else
        printf "   PostgreSQL for version %s not found\n" "$version"
        return 1
    fi
}

function delete_postgresql() {
  clear
  local versions filtered_versions
  versions=$(get_installed_postgresql_versions)
  filtered_versions=$(validate_numeric_version "$versions")
  
  for version in $filtered_versions; do
      get_postgresql_info "$version"
  done

      action="DELETE"

  action_color="\e[33m ${action} \e[0m"

    read -r -p "   Enter the version of postgresql to remove: "  input_version
            postgresql_version=${input_version:-$postgresql_version}


  while true; do
    read -r -p "   All data / users / databases of the selected version will be deleted! Make a backup copy first!
   Do you really want to$(echo -e "${action_color}")PostgreSQL? (Y/N):" answer
    case $answer in
      [Yy]* ) action_delete_postgresql; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function upgrade_postgresql() {
  clear
  local versions filtered_versions available_versions distro_postgresql_version default_from input_from

  versions=$(get_installed_postgresql_versions_raw)
  filtered_versions=$(validate_numeric_version "$versions")

  if [[ -z "${filtered_versions// }" ]]; then
      echo "   PostgreSQL is not installed."
      press_any_key_to_return_menu
      return 1
  fi

  echo "   Installed PostgreSQL versions:"
  for version in $filtered_versions; do
      print_postgresql_cluster_info "$version"
  done

  postgresql_repository_source="${BS_POSTGRESQL_REPOSITORY_SOURCE}"
  postgresql_upgrade_to_version="${BS_POSTGRESQL_VERSION}"
  default_from=""

  if [[ $(wc -w <<< "$filtered_versions") -eq 1 ]]; then
      default_from=$(printf '%s\n' "$filtered_versions" | awk '{print $1}')
  fi

  while true; do
    if [[ -n "$default_from" ]]; then
        read_by_def "   Enter installed PostgreSQL version to upgrade from [${default_from}]: " postgresql_upgrade_from_version "${default_from}"
    else
        read -r -p "   Enter installed PostgreSQL version to upgrade from: " input_from
        postgresql_upgrade_from_version="${input_from}"
    fi

    if [[ " ${filtered_versions} " =~ " ${postgresql_upgrade_from_version} " ]] && postgresql_cluster_exists "${postgresql_upgrade_from_version}"; then
        break
    fi

    echo "   PostgreSQL version ${postgresql_upgrade_from_version} is not installed."
  done

  while true; do
    read_by_def "   Enter PostgreSQL repository source for target version (official/distro) [${postgresql_repository_source}]: " postgresql_repository_source "${postgresql_repository_source}"
    postgresql_repository_source="${postgresql_repository_source,,}"
    case "${postgresql_repository_source}" in
      official|distro) break ;;
      *) echo "   Please enter official or distro." ;;
    esac
  done

  available_versions=$(get_available_postgresql_versions_for_source "${postgresql_repository_source}")
  if [[ -n "${available_versions// }" ]]; then
      echo "   Available PostgreSQL versions for installation: ${available_versions}"
  else
      echo "   Unable to determine available PostgreSQL versions from current APT cache."
  fi

  if [ "${postgresql_repository_source}" = "distro" ]; then
    distro_postgresql_version=$(get_distribution_postgresql_version)
    if [ -z "${distro_postgresql_version}" ]; then
      echo "   Unable to determine PostgreSQL version from distribution repository."
      press_any_key_to_return_menu
      return 1
    fi
    postgresql_upgrade_to_version="${distro_postgresql_version}"
    echo "   Distribution repository version: ${postgresql_upgrade_to_version}"
  else
    while true; do
      read_by_def "   Enter PostgreSQL version to upgrade to [${postgresql_upgrade_to_version}]: " postgresql_upgrade_to_version "${postgresql_upgrade_to_version}"

      if ! [[ "${postgresql_upgrade_to_version}" =~ ^[0-9]+$ ]]; then
        echo "   PostgreSQL version must be numeric."
        continue
      fi

      break
    done
  fi

  if ! [[ "${postgresql_upgrade_to_version}" =~ ^[0-9]+$ ]]; then
      echo "   PostgreSQL version must be numeric."
      press_any_key_to_return_menu
      return 1
  fi

  if (( 10#${postgresql_upgrade_to_version} <= 10#${postgresql_upgrade_from_version} )); then
      echo "   Target PostgreSQL version must be greater than source version."
      press_any_key_to_return_menu
      return 1
  fi

  if postgresql_cluster_exists "${postgresql_upgrade_to_version}"; then
      echo "   PostgreSQL cluster for version ${postgresql_upgrade_to_version} already exists."
      echo "   Remove it first or choose another target version."
      press_any_key_to_return_menu
      return 1
  fi

  action="UPGRADE"

  echo -e "\n   Entered data:\n"
  echo "   Task: ${action} PostgreSQL"
  echo "   Upgrade from version: ${postgresql_upgrade_from_version}"
  echo "   Upgrade to version: ${postgresql_upgrade_to_version}"
  echo "   Target repository source: ${postgresql_repository_source}"
  echo
  echo "   Databases, users and cluster config will be migrated to the new version."
  echo "   The new cluster will keep the original port."
  echo "   The old PostgreSQL version will be removed after successful upgrade."
  echo

  while true; do
    read -r -p "   Confirm that you have a backup and want to upgrade PostgreSQL? (Y/N): " answer
    case $answer in
      [Yy]* ) action_upgrade_postgresql; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function validate_input() {
    local input=$1
    local field_name=$2
    if [[ -z "$input" ]]; then
        echo "Error: $field_name cannot be empty."
        return 1
    fi
    # Add more specific validation rules as needed
    return 0
}

validate_port_number() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] || return 1
    (( port >= 1 && port <= 65535 ))
}

get_current_ssh_port() {
    local port
    port=$(sshd -T 2>/dev/null | awk '/^port / {print $2; exit}')
    if [[ -z "$port" ]]; then
        port="$BS_SSH_PORT"
    fi
    printf '%s\n' "$port"
}

is_port_busy_by_other_service() {
    local port="$1"
    local current_ssh_port
    current_ssh_port=$(get_current_ssh_port)

    if [[ "$port" == "$current_ssh_port" ]]; then
        return 1
    fi

    ss -ltnH "( sport = :${port} )" 2>/dev/null | grep -q .
}

validate_ssh_port_for_security() {
    local port="$1"

    if ! validate_port_number "$port"; then
        echo "   Invalid port. Enter a number from 1 to 65535."
        return 1
    fi

    if is_port_busy_by_other_service "$port"; then
        echo "   Port ${port} is already in use."
        return 1
    fi

    return 0
}

validate_yes_no_or_prohibit_password() {
    local value="${1,,}"
    [[ "$value" == "yes" || "$value" == "no" || "$value" == "prohibit-password" ]]
}

validate_yes_no_value() {
    local value="${1,,}"
    [[ "$value" == "yes" || "$value" == "no" || "$value" == "y" || "$value" == "n" ]]
}

validate_true_false_value() {
    local value="${1,,}"
    [[ "$value" == "true" || "$value" == "false" || "$value" == "yes" || "$value" == "no" || "$value" == "y" || "$value" == "n" ]]
}

normalize_to_yes_no() {
    local value="${1,,}"
    case "$value" in
        y|yes) printf 'yes\n' ;;
        n|no) printf 'no\n' ;;
        *) printf '%s\n' "$value" ;;
    esac
}

normalize_to_true_false() {
    local value="${1,,}"
    case "$value" in
        y|yes|true) printf 'true\n' ;;
        n|no|false) printf 'false\n' ;;
        *) printf '%s\n' "$value" ;;
    esac
}

validate_time_hhmm() {
    local value="$1"
    [[ "$value" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

system_user_exists() {
    local username="$1"
    id "$username" >/dev/null 2>&1
}

function security_settings() {
    clear

    local current_ssh_port
    current_ssh_port=$(get_current_ssh_port)

    BS_SSH_PORT=${BS_SSH_PORT:-$current_ssh_port}
    BS_SSH_PERMIT_ROOT_LOGIN=${BS_SSH_PERMIT_ROOT_LOGIN:-yes}
    BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO=${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO:-true}
    BS_SSH_ADMIN_USER_PASSWORD=${BS_SSH_ADMIN_USER_PASSWORD:-}
    BS_SSH_PASSWORD_AUTHENTICATION=${BS_SSH_PASSWORD_AUTHENTICATION:-yes}
    BS_AUTOUPDATE_ENABLED=${BS_AUTOUPDATE_ENABLED:-true}
    BS_AUTOUPDATE_REBOOT_ENABLE=${BS_AUTOUPDATE_REBOOT_ENABLE:-false}
    BS_AUTOUPDATE_REBOOT_TIME=${BS_AUTOUPDATE_REBOOT_TIME:-05:00}
    BS_SECRITY_HIDEPID=${BS_SECRITY_HIDEPID:-false}
    BS_SECRITY_HIDEPID_MONITORING_USER=${BS_SECRITY_HIDEPID_MONITORING_USER:-}

    echo -e "\n   Menu -> Security settings:\n"

    while true; do
        read_by_def "   Enter SSH port (default: ${BS_SSH_PORT}): " BS_SSH_PORT "${BS_SSH_PORT}"
        if validate_ssh_port_for_security "${BS_SSH_PORT}"; then
            break
        fi
    done

    while true; do
        read_by_def "   Enter PermitRootLogin (yes/no/prohibit-password) [${BS_SSH_PERMIT_ROOT_LOGIN}]: " BS_SSH_PERMIT_ROOT_LOGIN "${BS_SSH_PERMIT_ROOT_LOGIN}"
        BS_SSH_PERMIT_ROOT_LOGIN="${BS_SSH_PERMIT_ROOT_LOGIN,,}"
        if validate_yes_no_or_prohibit_password "${BS_SSH_PERMIT_ROOT_LOGIN}"; then
            break
        fi
        echo "   Please enter yes, no or prohibit-password."
    done

    read_by_def "   Enter sudo admin user for SSH access [${BS_SSH_ADMIN_USER}]: " BS_SSH_ADMIN_USER "${BS_SSH_ADMIN_USER}"

    if [[ -n "${BS_SSH_ADMIN_USER}" ]]; then
        while true; do
            read_by_def "   Use passwordless sudo for admin user (true/false) [${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}]: " BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO "${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}"
            BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO=$(normalize_to_true_false "${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}")
            if validate_true_false_value "${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}"; then
                break
            fi
            echo "   Please enter true or false."
        done

        if [[ "${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}" == "false" ]]; then
            local generated_admin_password
            generated_admin_password="${BS_SSH_ADMIN_USER_PASSWORD:-$(generate_password 20)}"
            read_by_def "   Enter password for admin user [${generated_admin_password}]: " BS_SSH_ADMIN_USER_PASSWORD "${generated_admin_password}"
        else
            BS_SSH_ADMIN_USER_PASSWORD=""
        fi
    else
        BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO="true"
        BS_SSH_ADMIN_USER_PASSWORD=""
    fi

    while true; do
        read_by_def "   Enable PasswordAuthentication (yes/no) [${BS_SSH_PASSWORD_AUTHENTICATION}]: " BS_SSH_PASSWORD_AUTHENTICATION "${BS_SSH_PASSWORD_AUTHENTICATION}"
        BS_SSH_PASSWORD_AUTHENTICATION=$(normalize_to_yes_no "${BS_SSH_PASSWORD_AUTHENTICATION}")
        if validate_yes_no_value "${BS_SSH_PASSWORD_AUTHENTICATION}"; then
            break
        fi
        echo "   Please enter yes or no."
    done

    while true; do
        read_by_def "   Enable unattended security updates (true/false) [${BS_AUTOUPDATE_ENABLED}]: " BS_AUTOUPDATE_ENABLED "${BS_AUTOUPDATE_ENABLED}"
        BS_AUTOUPDATE_ENABLED=$(normalize_to_true_false "${BS_AUTOUPDATE_ENABLED}")
        if validate_true_false_value "${BS_AUTOUPDATE_ENABLED}"; then
            break
        fi
        echo "   Please enter true or false."
    done

    if [[ "${BS_AUTOUPDATE_ENABLED}" == "true" ]]; then
        while true; do
            read_by_def "   Enable auto reboot after updates (true/false) [${BS_AUTOUPDATE_REBOOT_ENABLE}]: " BS_AUTOUPDATE_REBOOT_ENABLE "${BS_AUTOUPDATE_REBOOT_ENABLE}"
            BS_AUTOUPDATE_REBOOT_ENABLE=$(normalize_to_true_false "${BS_AUTOUPDATE_REBOOT_ENABLE}")
            if validate_true_false_value "${BS_AUTOUPDATE_REBOOT_ENABLE}"; then
                break
            fi
            echo "   Please enter true or false."
        done

        if [[ "${BS_AUTOUPDATE_REBOOT_ENABLE}" == "true" ]]; then
            while true; do
                read_by_def "   Enter auto reboot time in HH:MM [${BS_AUTOUPDATE_REBOOT_TIME}]: " BS_AUTOUPDATE_REBOOT_TIME "${BS_AUTOUPDATE_REBOOT_TIME}"
                if validate_time_hhmm "${BS_AUTOUPDATE_REBOOT_TIME}"; then
                    break
                fi
                echo "   Invalid time format. Use HH:MM."
            done
        fi
    fi

    while true; do
        read_by_def "   Enable hidepid for /proc (true/false) [${BS_SECRITY_HIDEPID}]: " BS_SECRITY_HIDEPID "${BS_SECRITY_HIDEPID}"
        BS_SECRITY_HIDEPID=$(normalize_to_true_false "${BS_SECRITY_HIDEPID}")
        if validate_true_false_value "${BS_SECRITY_HIDEPID}"; then
            break
        fi
        echo "   Please enter true or false."
    done

    if [[ "${BS_SECRITY_HIDEPID}" == "true" ]]; then
        while true; do
            read_by_def "   Enter existing monitoring user for /proc access (optional) [${BS_SECRITY_HIDEPID_MONITORING_USER}]: " BS_SECRITY_HIDEPID_MONITORING_USER "${BS_SECRITY_HIDEPID_MONITORING_USER}"
            if [[ -z "${BS_SECRITY_HIDEPID_MONITORING_USER}" ]] || system_user_exists "${BS_SECRITY_HIDEPID_MONITORING_USER}"; then
                break
            fi
            echo "   User ${BS_SECRITY_HIDEPID_MONITORING_USER} does not exist."
        done
    else
        BS_SECRITY_HIDEPID_MONITORING_USER=""
    fi

    if [[ "${BS_SSH_PERMIT_ROOT_LOGIN}" == "no" && -z "${BS_SSH_ADMIN_USER}" ]]; then
        echo "   If PermitRootLogin=no, you must specify BS_SSH_ADMIN_USER."
        press_any_key_to_return_menu
        return 1
    fi

    echo -e "\n   Entered data:\n"
    echo "   SSH port: ${BS_SSH_PORT}"
    echo "   PermitRootLogin: ${BS_SSH_PERMIT_ROOT_LOGIN}"
    if [[ -n "${BS_SSH_ADMIN_USER}" ]]; then
        echo "   SSH admin user: ${BS_SSH_ADMIN_USER}"
        echo "   Passwordless sudo: ${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}"
        if [[ "${BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO}" == "false" ]]; then
            echo "   Admin user password: ${BS_SSH_ADMIN_USER_PASSWORD}"
        fi
    fi
    echo "   PasswordAuthentication: ${BS_SSH_PASSWORD_AUTHENTICATION}"
    echo "   Auto updates enabled: ${BS_AUTOUPDATE_ENABLED}"
    if [[ "${BS_AUTOUPDATE_ENABLED}" == "true" ]]; then
        echo "   Auto reboot enabled: ${BS_AUTOUPDATE_REBOOT_ENABLE}"
        if [[ "${BS_AUTOUPDATE_REBOOT_ENABLE}" == "true" ]]; then
            echo "   Auto reboot time: ${BS_AUTOUPDATE_REBOOT_TIME}"
        fi
    fi
    echo "   HidePID: ${BS_SECRITY_HIDEPID}"
    if [[ "${BS_SECRITY_HIDEPID}" == "true" ]]; then
        echo "   HidePID monitoring user: ${BS_SECRITY_HIDEPID_MONITORING_USER}"
    fi
    echo -e "\n"

    while true; do
        read -r -p "   Do you really want to apply security settings? (Y/N): " answer
        case ${answer,,} in
            y )
                BS_SETUP_SECURITY="Y"
                action_setup_security
                break
                ;;
            n ) break ;;
            * ) echo "   Please enter Y or N." ;;
        esac
    done
}

function add_user_and_db_postgresql() {
        clear
        get_installed_postgresql_versions

        postgresql_user_state='present'

        action="CREATE"
        postgresql_db_lc_collate="ru_RU.UTF-8"
        postgresql_db_lc_ctype="${postgresql_db_lc_collate}"
        postgresql_db_encoding="UTF-8"

        auto_generated_password=$(openssl rand -base64 12)

        action_color="\e[33m ${action} \e[0m"

        read -r -p "   Enter the version of postgresql to create the user and database: "  input_version
        postgresql_version=${input_version:-$postgresql_version}

        get_postgresql_info "${postgresql_version}"

        read -r -p "   Enter username: "  input_username
        if validate_input "$input_username" "Username"; then
          postgresql_username=$input_username
        else
          return 1
        fi

        read -r -p "   Enter password (default: ${auto_generated_password}) :"  input_user_password
        postgresql_user_password=${input_user_password:-${auto_generated_password}}

        read -r -p "   Enter dbname (default: $postgresql_username) :"  input_dbname
        postgresql_db_name=${input_dbname:-$postgresql_username}

        read -r -p "   Enter LC_COLLATE (default: $postgresql_db_lc_collate) :"  input_lc_collate
        postgresql_db_lc_collate=${input_lc_collate:-$postgresql_db_lc_collate}

        read -r -p "   Enter LC_CTYPE (default: $postgresql_db_lc_ctype) :"  input_lc_ctype
        postgresql_db_lc_ctype=${input_lc_ctype:-$postgresql_db_lc_ctype}

        read -r -p "   Enter db encoding (default: $postgresql_db_encoding) :"  input_db_encoding
        postgresql_db_encoding=${input_db_encoding:-$postgresql_db_encoding}

        echo -e "\n   Entered data:\n"
        echo "   Task: $action user/db in PostgreSQL"
        echo "   Username: $postgresql_username"
        echo "   Password: $postgresql_user_password"
        echo "   DB name: $postgresql_db_name"
        echo "   LC_COLLATE: $postgresql_db_lc_collate"
        echo "   LC_CTYPE: $postgresql_db_lc_ctype"
        echo "   DB encoding: $postgresql_db_encoding"
        echo "   DB port: $postgresql_port"
        echo "   DB socket: $postgresql_socket"

        while true; do
          read -r -p "   Do you really want to$(echo -e "${action_color}") user/db in PostgreSQL? (Y/N):" answer
          case $answer in
            [Yy]* ) action_add_db_user_postgresql; break;;
            [Nn]* ) break;;
            * ) echo "   Please enter Y or N.";;
          esac
        done
}

function delete_user_and_db_postgresql() {
  clear
  get_installed_postgresql_versions;

  postgresql_user_state='absent'

  action="DELETE"

  action_color="\e[33m ${action} \e[0m"

    read -r -p "   Enter the version of postgresql to delete the user and database: "  input_version
            postgresql_version=${input_version:-$postgresql_version}

    get_postgresql_info "${postgresql_version}"

    read -r -p "   Enter username: "  input_username
        if validate_input "$input_username" "Username"; then
            postgresql_username=$input_username
        else
            return 1
        fi

    read -r -p "   Enter dbname (default: $postgresql_username) :"  input_dbname
            postgresql_db_name=${input_dbname:-$postgresql_username}
    

    echo -e "\n   Entered data:\n"
    echo "   Task: $action user/db in PostgreSQL"
    echo "   Username: $postgresql_username"
    echo "   DB name: $postgresql_db_name"
    echo "   DB port: $postgresql_port"
    echo "   DB socket: $postgresql_socket"


  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}") user/db from PostgreSQL? (Y/N):" answer
    case $answer in
      [Yy]* ) action_delete_user_and_db_postgresql; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_debian_repo_on_astra_linux() {
  clear

  action="INSTALL"
  if [ -s /etc/apt/sources.list.d/debian_repositories_for_astra.list ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Debian repo on Astra Linux? (Y/N): " answer
    case $answer in
      [Yy]* ) action_setup_debian_repositories_for_astra; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

detect_mysql_version() {
    local output version major flavor

    output="$(mysql --version 2>/dev/null)" || {
        echo "mysql not found"
        return 1
    }

    # Extract first X.Y.Z
    if [[ $output =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        version="${BASH_REMATCH[1]}"
    else
        version="0.0.0"
    fi

    # Detect flavor
    if [[ $output == *MariaDB* ]]; then
        flavor="MariaDB"
    elif [[ $output == *Percona* ]]; then
        flavor="Percona"
    else
        flavor="MySQL"
    fi

    major="${version%.*}"

    # Export as global vars (like set_fact)
    MYSQL_FLAVOR="$flavor"
    MYSQL_VERSION="$version"
    MYSQL_VERSION_MAJOR="$major"
}

get_debian_major_version() {
    local os_id version_id major_version

    if [ -r /etc/os-release ]; then
        os_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')
        version_id=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')

        if [ "${os_id}" = "debian" ] && [[ "${version_id}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            printf '%s\n' "${version_id%%.*}"
            return 0
        fi
    fi

    if [ -r /etc/debian_version ]; then
        major_version=$(cut -d. -f1 /etc/debian_version)
        if [[ "${major_version}" =~ ^[0-9]+$ ]]; then
            printf '%s\n' "${major_version}"
        fi
    fi
}

get_ubuntu_major_version() {
    local os_id version_id

    if [ -r /etc/os-release ]; then
        os_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')
        version_id=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')

        if [ "${os_id}" = "ubuntu" ] && [[ "${version_id}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            printf '%s\n' "${version_id%%.*}"
        fi
    fi
}

function install_mysql() {
    clear
    local input_flavor input_version input_charset input_collation debian_major_version ubuntu_major_version

    action="INSTALL"
    debian_major_version=$(get_debian_major_version)
    ubuntu_major_version=$(get_ubuntu_major_version)

    while true; do
        read_by_def "   Enter MySQL flavor (percona/mariadb) [${BS_DB_FLAVOR}]: " input_flavor "${BS_DB_FLAVOR}"
        input_flavor="${input_flavor,,}"
        case "${input_flavor}" in
            percona|mariadb)
                BS_DB_FLAVOR="${input_flavor}"
                break
                ;;
            *)
                echo "   Please enter percona or mariadb."
                ;;
        esac
    done

    if [ "${BS_DB_FLAVOR}" = "percona" ]; then
        while true; do
            read_by_def "   Enter Percona version (5.7/8.0/8.4) [${BS_DB_VERSION}]: " input_version "${BS_DB_VERSION}"
            case "${input_version}" in
                5.7|8.0|8.4)
                    if [ -n "${debian_major_version}" ] &&
                       [ "${debian_major_version}" -ge 13 ] &&
                       { [ "${input_version}" = "5.7" ] || [ "${input_version}" = "8.0" ]; }; then
                        echo "   Percona ${input_version} is not available on Debian ${debian_major_version}. Enter another version."
                        continue
                    fi
                    if [ -n "${ubuntu_major_version}" ] &&
                       [ "${ubuntu_major_version}" -ge 24 ] &&
                       [ "${input_version}" = "5.7" ]; then
                        echo "   Percona ${input_version} is not available on Ubuntu ${ubuntu_major_version}.04+. Enter another version."
                        continue
                    fi
                    BS_DB_VERSION="${input_version}"
                    break
                    ;;
                *)
                    echo "   Please enter 5.7, 8.0 or 8.4."
                    ;;
            esac
        done
    else
        BS_DB_VERSION="10.11"
    fi

    read_by_def "   Enter BS_DB_CHARACTER_SET_SERVER (default: ${BS_DB_CHARACTER_SET_SERVER}): " input_charset "${BS_DB_CHARACTER_SET_SERVER}"
    BS_DB_CHARACTER_SET_SERVER="${input_charset}"

    read_by_def "   Enter BS_DB_COLLATION (default: ${BS_DB_COLLATION}): " input_collation "${BS_DB_COLLATION}"
    BS_DB_COLLATION="${input_collation}"

    echo -e "\n   Entered data:\n"
    echo "   Action: ${action} MySQL"
    echo "   MySQL flavor: ${BS_DB_FLAVOR}"
    echo "   MySQL version: ${BS_DB_VERSION}"
    echo "   Character set: ${BS_DB_CHARACTER_SET_SERVER}"
    echo "   Collation: ${BS_DB_COLLATION}"
    echo -e "\n"

    while true; do
        read -r -p "   Do you really want to install MySQL? (Y/N): " answer
        case $answer in
          [Yy]* ) action_install_mysql; break;;
          [Nn]* ) break;;
          * ) echo "   Please enter Y or N.";;
        esac
    done
}

function delete_mysql() {
    clear
    action="DELETE"

    echo -e "   All MySQL databases, users and data files will be deleted."
    echo

    while true; do
        read -r -p "   Do you really want to delete MySQL? (Y/N): " answer
        case $answer in
          [Yy]* ) action_delete_mysql; break;;
          [Nn]* ) break;;
          * ) echo "   Please enter Y or N.";;
        esac
    done
}

function re-generate_mysql_config() {
    clear;
    while true; do
    read -r -p "   Do you really want to re-generate MySQL config? (Y/N): " answer
    case $answer in
      [Yy]* ) action_re-generate_mysql_config; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done

}

function upgrade_percona_5.7_to_8.0() {
    clear;
    while true; do
    echo -e "   You confirm that you have made a complete backup of the database. \n"
    read -r -p "   Do you really want to Upgrade Percona MySQL from 5.7 to 8.0?(Y/N): " answer
    case $answer in
      [Yy]* ) action_upgrade_percona_5.7_to_8.0; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done

}

function upgrade_percona_8.0_to_8.4() {
    clear;
    while true; do
    echo -e "   You confirm that you have made a complete backup of the database. \n"
    read -r -p "   Do you really want to Upgrade Percona MySQL from 8.0 to 8.4? (Y/N): " answer
    case $answer in
      [Yy]* ) action_upgrade_percona_8.0_to_8.4; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done

}

function purge_snapd() {
  clear

  is_purge_snapd=$(which snap);
  action="INSTALL"
  if [ ! -z "$is_purge_snapd" ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Snapd? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_snapd; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function install_push_server() {
  clear

  push_server_remove_redis="N"
  action="INSTALL"
  if [ -f "${BS_PUSH_SERVER_CONFIG}" ] || [ -f /etc/systemd/system/push-server.service ] || [ -e /usr/local/bin/push-server-multi ]; then
      action="DELETE"
  fi

  action_color="\e[33m ${action} \e[0m"

  if [ "$action" == "DELETE" ]; then
    while true; do
      read -r -p "   Delete Redis too? (Y/N) [${push_server_remove_redis}]: " answer
      answer=${answer:-$push_server_remove_redis}
      case ${answer,,} in
        y ) push_server_remove_redis="Y"; break;;
        n ) push_server_remove_redis="N"; break;;
        * ) echo "   Please enter Y or N.";;
      esac
    done
  fi

  while true; do
    read -r -p "   Do you really want to$(echo -e "${action_color}")Push server? (Y/N): " answer
    case $answer in
      [Yy]* ) action_install_or_delete_push_server; break;;
      [Nn]* ) break;;
      * ) echo "   Please enter Y or N.";;
    esac
  done
}

function change_timezone() {
    clear;
    server_timezone=${BS_SERVER_TIMEZONE}

        read_by_def "   Enter new timezone: (current TZ: ${server_timezone} ): " server_timezone ${server_timezone};

    server_timezone="${server_timezone}"


    echo -e "\n   Selected TZ: ${server_timezone}\n"

    while true; do
      read -r -p "   Do you really want to change_timezone? (Y/N): " answer
      case ${answer,,} in
        y ) action_change_timezone; break;;
        n ) break;;
        * ) echo "   Please enter Y or N.";;
      esac
    done
}

function delete_site() {
    clear;
    list_sites;
    echo -e "\n   Menu ->\e[33m Delete site:\e[0m\n";

    site=''
    db_type='mysql'
    db_name=''
    db_user=''
    db_host=''
    db_port=''
    postgresql_port=''
    pgbouncer_use=0
    path_site_from_links='';

    read_by_def "  Enter path to site (example: /var/www/html/bx-site): " path_site_from_links "${path_site_from_links}";
    while [[ -z "$path_site_from_links" ]]|| ! [[ " ${ARR_ALL_USERS_DIR_SITES_DATA[*]} " =~ " $path_site_from_links " ]]; do
            echo "   Incorrect path to dir! Please enter path to site dir";
            read_by_def "   Enter path to dir: " path_site_from_links $path_site_from_links;
    done


    # Extract domain name from link
    site=$(basename "$path_site_from_links")


    #read_by_def "   Enter site dir: " site $site;
    #while [[ -z "$site" ]] || ! [[ " ${ARR_ALL_USERS_DIR_SITES[*]} " =~ " $site " ]]; do
    #        echo "   Incorrect site dir! Please enter site dir";
    #        read_by_def "   Enter site dir: " site $site;
    #done
    extract_username_from_path

    full_path_site="${BS_PATH_SITES}/${site}"
    bx_path_site="${full_path_site}/bitrix"

    type="full";
    if [ -L "$bx_path_site" ]; then
      type="link";
    fi

    echo -e "\n  \e[33m You entered ${type^^} site:\e[0m";

    if [[ "$type" == "full" ]]; then

        output=$(php "$dir_helpers/php/get_database_data.php" "$bx_path_site")

        IFS=$'\n' read -r -d '' -a results <<< "$output"

        db_name="${results[0]}"
        db_user="${results[1]}"
        db_type="${results[2]:-mysql}"
        db_host="${results[3]}"
        db_port="${results[4]}"

        if [ "$db_type" = "pgsql" ]; then
          postgresql_port="${db_port:-5432}"
          if command -v pgbouncer >/dev/null 2>&1 && [ "${db_port}" = "$(get_pgbouncer_listen_port)" ]; then
            local backend_port
            backend_port=$(get_pgbouncer_backend_port_for_user "$db_user")
            if [ -n "$backend_port" ]; then
              postgresql_port="$backend_port"
              pgbouncer_use=1
            fi
          fi

          postgresql_version=$(find_postgresql_version_by_port "$postgresql_port" || true)
        fi

        echo -e "\n  \e[33m The site directory (${full_path_site}) will be permanently deleted!!!\e[0m";
        echo -e "\n  \e[33m The database (${db_name}) and the user database (${db_user}) will be permanently deleted!!!\e[0m";
        echo -e "\n  \e[33m Nginx and Apache configs will be renamed!!!\e[0m";
    else

        echo -e "\n  \e[33m The site directory (${full_path_site}) will be permanently deleted!!!\e[0m";
        echo -e "\n  \e[33m Nginx and Apache configs will be renamed!!!\e[0m";
    fi

    echo -e "\n";

    action_color="\e[33m PERMANENTLY DELETE THE SITE ${site}\e[0m"
    while true; do
      local code_rand=$((100000 + RANDOM % 899999))
      read -r -p "  If you really want to$(echo -e "${action_color}"), enter the code: ${code_rand} or enter 0 to exit " answer
      case "${answer}" in
        "${code_rand}" ) break;;
        0 ) return 0 ;;
      esac
    done

    echo -e "\n";

    if [[ "$site" == "$BS_DEFAULT_SITE_NAME" ]]; then
        site="default";
    fi

    while true; do
      read -r -p "   Do you really want to delete site? (Y/N): " answer
      case $answer in
        [Yy]* ) action_delete_site; break;;
        [Nn]* ) break;;
        * ) echo "   Please enter Y or N.";;
      esac
    done
}

check_reboot_needed() {
    if command -v needrestart >/dev/null 2>&1; then
        local ksta
        ksta=$(needrestart -b | grep "NEEDRESTART-KSTA:" | cut -d' ' -f2)
        if [ "$ksta" = "2" ] || [ "$ksta" = "3" ]; then
            echo "          Reboot is needed (kernel upgrade pending)"
            return 0
        else
            #echo "          No reboot required"
            return 1
        fi
    else
        #echo "          needrestart is not installed"
        return 2
    fi
}

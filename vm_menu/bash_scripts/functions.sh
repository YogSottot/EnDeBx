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
    echo "          9) Update server";
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
      "9") update_server ;;
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

    echo -e "\n          Menu -> Installing Extensions:\n";
    echo "          1) Install/Delete Sphinx";
    echo "          2) Install/Delete File Conversion Server (transformer)";
    echo "          3) Install/Delete Netdata";
    echo "          4) Install/Delete Crowdsec";
    echo "          5) Install/Delete Rkhunter";
    echo "          6) Install/Delete Linux Malware Detect ";
    echo "          7) Install/Delete Memcached";
    echo "          8) Install/Delete Deadsnakes PPA";
    echo "          9) Install/Delete Docker";
    echo "          10) PostgreSQL";
    echo "          11) Install/Delete Debian repo on Astra Linux";
    echo "          12) MySQL";
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

    "1") install_sphinx ;;
    "2") install_file_conversion_server ;;
    "3") install_netdata ;;
    "4") install_crowdsec ;;
    "5") install_rkhunter ;;
    "6") install_linux_malware_detect ;;
    "7") install_memcached ;;
    "8") install_deadsnakes_ppa ;;
    "9") install_docker ;;
    "10") menu_postgresql ;;
    "11") install_debian_repo_on_astra_linux ;;
    "12") menu_mysql ;;

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
    echo "          3) Add user and db in PostgreSQL";
    echo "          4) Remove user and db from PostgreSQL";
    echo "          5) Install/Delete Pgbouncer";
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1") install_postgresql ;;
      "2") delete_postgresql ;;
      "3") add_user_and_db_postgresql ;;
      "4") delete_user_and_db_postgresql ;;
      "5") install_delete_pgbouncer ;;

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
    #clear;
    detect_mysql_version;

    echo -e "\n          Menu -> MySQL:\n";
    echo "          1) Re-generate MySQL config";
  if [ "$MYSQL_VERSION_MAJOR" == 5.7 ] ; then
    echo "          2) Upgrade percona 5.7 to 8.0";
  fi
  if [ "$MYSQL_FLAVOR" == "Percona" ] && [ "$MYSQL_VERSION_MAJOR" == 8.0 ] ; then
    echo "          3) Upgrade percona 8.0 to 8.4";
  fi
    echo "          0) Return to main menu";
    echo -e "\n\n";
    echo -n "Enter command: "
    read -r comand

    case $comand in

      "1") re-generate_mysql_config ;;
      "2") upgrade_percona_5.7_to_8.0 ;;
      "3") upgrade_percona_8.0_to_8.4  ;;

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

add_site(){
    clear;
    list_sites;

    domain=''
    mode=''
    db_name=''
    db_user=''
    db_password=$(generate_password $BS_CHAR_DB_PASSWORD)
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

          while true; do
            read -r -p "   Do you want to add local push-server config to /bitrix/.setting.php? (Y/N) [${push_server_bx_settings}]: " answer
            answer=${answer:-$push_server_bx_settings}
            case ${answer,,} in
              y ) push_server_bx_settings=Y; break;;
              n ) push_server_bx_settings=N; break;;
              * ) printf "   Please enter Y or N.\n";;
            esac
          done

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


              # Create the user if it doesn't exist
              if ! id "$BS_USER_SERVER_SITES" &>/dev/null; then
                  useradd -m -d "${BS_PATH_USER_HOME_PREFIX}/${BS_USER_SERVER_SITES}" -s /bin/bash "${BS_USER_SERVER_SITES}"
                  chmod 775 "${BS_PATH_USER_HOME_PREFIX}/${BS_USER_SERVER_SITES}"
              fi
              echo "   Username: ${BS_USER_SERVER_SITES}"

          while true; do
            db_name=$(sanitize_name "db_$domain" "$BS_MAX_CHAR_DB_NAME")
            db_user=$(sanitize_name "usr_$domain" "$BS_MAX_CHAR_DB_USER")

            if db_exists "$db_name" || user_exists "$db_user"; then
                printf "Warning: Database '%s' or User '%s' already exists. Generating unique names...\n" "$db_name" "$db_user" >&2
                local unique_hash; unique_hash=$(generate_random_hash)
                db_name=$(sanitize_name "db_$domain_$unique_hash" "$BS_MAX_CHAR_DB_NAME")
                db_user=$(sanitize_name "usr_$domain_$unique_hash" "$BS_MAX_CHAR_DB_USER")
            fi

            # Ensure generated names are unique
            while db_exists "$db_name" || user_exists "$db_user"; do
                printf "Error: Generated names '%s' or '%s' already exist. Regenerating...\n" "$db_name" "$db_user" >&2
                unique_hash=$(generate_random_hash)
                db_name=$(sanitize_name "db_$domain_$unique_hash" "$BS_MAX_CHAR_DB_NAME")
                db_user=$(sanitize_name "usr_$domain_$unique_hash" "$BS_MAX_CHAR_DB_USER")
            done

            while true; do
                read_by_def "   Enter database name: (default: $db_name): " db_name $db_name
                db_name=$(sanitize_name "$db_name" "$BS_MAX_CHAR_DB_NAME")

                if db_exists "$db_name"; then
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

                if user_exists "$db_user"; then
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
    listen 443 ssl;
    listen [::]:443 ssl;
    
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
  local versions filtered_versions
  versions=$(get_installed_postgresql_versions)
  filtered_versions=$(validate_numeric_version "$versions")
  
  for version in $filtered_versions; do
      get_postgresql_info "$version"
  done

  postgresql_version='17';
  postgresql_port='5432';

  action="INSTALL"

  action_color="\e[33m ${action} \e[0m"

  read -r -p "   Avaliable version: https://wiki.postgresql.org/wiki/Apt
   Enter postgresql version (default: $postgresql_version): " input_version
            postgresql_version=${input_version:-$postgresql_version}

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
    versions=$(ls -d /usr/lib/postgresql/[0-9]* 2>/dev/null | xargs -n1 basename | sort -n | tr '\n' ' ')
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
    port=$(grep -r "/var/lib/postgresql/$version/main" /run/postgresql/ | grep -oP '(?<=PGSQL.)\d+')
    socket="/run/postgresql/.s.PGSQL.$port"

    if [ -n "$port" ] && [ -S "$socket" ]; then
        printf "   \n   Version: %s\n   Port: %s\n   Unix socket: %s\n\n" "$version" "$port" "$socket"
        export postgresql_port="$port"
        export postgresql_socket="$socket"
    else
        printf "   PostgreSQL for version %s not found\n" "$version"
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

function delete_site() {
    clear;
    list_sites;
    echo -e "\n   Menu ->\e[33m Delete site:\e[0m\n";

    site=''
    db_name=''
    db_user=''
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


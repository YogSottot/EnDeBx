#!/bin/bash

declare -A ARR_ALL_USERS_DIR_SITES_DATA

generate_password() {
    local length=$1
    local specials='!@#$%^&*()-_=+[]|;:,.<>?/~'
    local all_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789${specials}"

    local password=""
    for i in $(seq 1 $length); do
        local char=${all_chars:RANDOM % ${#all_chars}:1}
        password+=$char
    done

    echo $password
}

list_sites(){
  ARR_ALL_USERS_DIR_SITES_DATA=()
  ARR_ALL_USERS_DIR_SITES=()
  get_current_version_php

  printf "   List of sites dirs: \n"

  # Функция для заполнения массива данными
  fill_array() {
    local user_home_dirs
    local index=0

    # Get the list of user home directories inside BS_PATH_USER_HOME_PREFIX
    if ! user_home_dirs=$(find "$BS_PATH_USER_HOME_PREFIX" -mindepth 1 -maxdepth 1 -type d | grep -vFf <(printf "%s\n" "${BS_EXCLUDED_DIRS_SITES[@]}")); then
      #printf "Error: Unable to list user home directories\n" >&2
      return 1
    fi

    # Loop through each user's home directory
    for user_home in $user_home_dirs; do
      local username; username=$(basename "$user_home")
      local user_sites_dir="$user_home"

      # Process additional sites for both default and other users
      if [[ -d "$user_sites_dir" ]]; then
        for tmp_dir in $(find "$user_sites_dir" -maxdepth 1 -type d | grep -v "^$user_sites_dir$" | sed 's|.*/||'); do

          # Skip hidden directories or excluded directories
          if [[ $tmp_dir =~ ^\. ]] || [[ " ${BS_EXCLUDED_DIRS_SITES[@]} " =~ " $tmp_dir " ]]; then
            #printf "Skipping directory: %s for user: %s\n" "$tmp_dir" "$username" >&2
            continue
          fi

          #printf "Processing user: %s, site: %s\n" "$username" "$tmp_dir" >&2

          ARR_ALL_USERS_DIR_SITES+=("$tmp_dir")
          ARR_ALL_USERS_DIR_SITES_DATA["${index}_dir"]="$tmp_dir"
          ARR_ALL_USERS_DIR_SITES_DATA[$index,is_default]="N"
          ARR_ALL_USERS_DIR_SITES_DATA[$index,is_https]="N"
          ARR_ALL_USERS_DIR_SITES_DATA[$index,doc_root]="$user_sites_dir/$tmp_dir"
          ARR_ALL_USERS_DIR_SITES_DATA[$index,user]="$username"

          # Check for HTTPS
          if [[ -f "$user_sites_dir/$tmp_dir/.htsecure" ]]; then
            ARR_ALL_USERS_DIR_SITES_DATA[$index,is_https]="Y"
          fi

          # Add PHP version information from Apache config
          local site_config="${BS_PATH_APACHE_SITES_ENABLED}/${tmp_dir}.conf"
          if [[ -f "$site_config" ]]; then
            local php_version; php_version=$(grep -oP 'php\K[\d.]+(?=-(?:user\d+)?-?fpm\.sock)' "$site_config")

            if [[ -z "$php_version" ]]; then
              php_version=$default_version
              ARR_ALL_USERS_DIR_SITES_DATA[$index,php_default]="Y"
            else
              ARR_ALL_USERS_DIR_SITES_DATA[$index,php_default]=$([[ "$php_version" == "$default_version" ]] && echo "Y" || echo "N")
            fi
            ARR_ALL_USERS_DIR_SITES_DATA[$index,php_version]="$php_version"
          else
            ARR_ALL_USERS_DIR_SITES_DATA[$index,php_version]="N/A"
            ARR_ALL_USERS_DIR_SITES_DATA[$index,php_default]="N/A"
          fi

          ((index++))
        done
      fi
    done
  }

  # Функция для вывода горизонтальной линии
  print_line() {
    printf "   +"
    for i in {1..20}; do printf "-"; done
    printf "+"
    for i in {1..21}; do printf "-"; done
    printf "+"
    for i in {1..16}; do printf "-"; done
    printf "+"
    for i in {1..25}; do printf "-"; done
    printf "+"
    for i in {1..26}; do printf "-"; done
    printf "+"
    for i in {1..13}; do printf "-"; done
    printf "+"
    for i in {1..18}; do printf "-"; done
    printf "+"
  }

  # Функция для вывода таблицы для определённого пользователя
  print_user_table() {
    local username="$1"

    printf "\n   Sites for user: %s\n" "$username"
    print_line
    printf "   | %-40s | %-14s | %-50s | %-11s | %-16s |\n" "Directory site" "Redirect HTTPS" "Document root" "PHP Version" "Default PHP"
    print_line

    local index=0
    while [[ -n "${ARR_ALL_USERS_DIR_SITES_DATA["${index}_dir"]}" ]]; do
      if [[ "${ARR_ALL_USERS_DIR_SITES_DATA[$index,user]}" == "$username" ]]; then
        printf "   | %-40s | %-14s | %-50s | %-11s | %-16s |\n" \
          "${ARR_ALL_USERS_DIR_SITES_DATA["${index}_dir"]}" \
          "${ARR_ALL_USERS_DIR_SITES_DATA[$index,is_https]}" \
          "${ARR_ALL_USERS_DIR_SITES_DATA[$index,doc_root]}" \
          "${ARR_ALL_USERS_DIR_SITES_DATA[$index,php_version]}" \
          "${ARR_ALL_USERS_DIR_SITES_DATA[$index,php_default]}"
        print_line
      fi
      ((index++))
    done
  }

  # Функция для вывода таблицы для всех пользователей
  print_tables() {
      # Define an error handling function
      handle_error() {
          echo "Error: $1" >&2
          exit 1
      }

      # Получаем список директорий пользователей
      if ! readarray -t user_directories < <(find "$BS_PATH_USER_HOME_PREFIX" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | grep -vFf <(printf "%s\n" "${BS_EXCLUDED_DIRS_SITES[@]}")); then
          handle_error "Failed to read user directories"
      fi

      # Now you can use ${user_directories[@]} in your script
      for user in "${user_directories[@]}"; do
          print_user_table "$user"
      done
  }

  fill_array
  print_tables
  get_current_version_php
}


press_any_key_to_return_menu(){
    echo -e "\n";
    while true; do
        read -r -p "   To return to the menu, please press Enter " answer
        case $answer in
            * ) break;;
        esac
    done
}

read_by_def(){
    local message=${1}   # сообщение
    local var_name=${2}  # имя устанавливаемой переменной
    local def_val=${3}   # значение по умолчанию
    local user_input     # то, что ввел пользователь

    read -r -p "$message" user_input

    if [[ -z "$user_input" ]]; then
        printf -v "$var_name" "%s" "$def_val"
    else
        printf -v "$var_name" "%s" "$user_input"
    fi
}

function load_bitrix_vm_version() {
  unset $BS_VAR_NAME_BVM
  if test -f "$BS_VAR_PATH_FILE_BVM"; then
      source "${BS_VAR_PATH_FILE_BVM}"
  fi
}

function get_interfaces() {
  ip -o -4 addr list | grep -v ' lo ' | awk '{print $2, $4}'
}

function  get_ip_current_server() {
  while true; do
    interfaces=$(get_interfaces)
    if [ -n "$interfaces" ]; then
        break
    fi
    # ip monitor address | grep -m 1 'inet ' > /dev/null
  done

  CURRENT_SERVER_IP="Interface\tIP\n"

  while read -r line; do
      iface=$(echo $line | awk '{print $1}')
      ip=$(echo $line | awk '{print $2}' | cut -d'/' -f1)
      CURRENT_SERVER_IP+="          $iface\t$ip\n"
  done <<< "$interfaces"
}

function get_current_version_php() {
    default_version=$(update-alternatives --query php | grep 'Value:' | awk '{print $2}' | grep -oP '\d+\.\d+')
    version_list=$(update-alternatives --list php | grep -oP '\d+\.\d+' | sort -u | tr '\n' ' ')
    
    echo -e "\n   Current default PHP version: $default_version"
    echo -e "   All installed PHP versions: $version_list"
}


function get_available_version_php() {
    echo -e "\n   Available PHP versions:\n"

    versions=$(apt-cache search php | grep -oP '^php[0-9.]+ ' | sort -ur)
    for version in $versions; do
        echo "   $version"
    done

    echo -e "\n"
}

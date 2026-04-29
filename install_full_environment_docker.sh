#!/usr/bin/env bash
set -euo pipefail
# Install full environment
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/YogSottot/EnDeBx/main/install_full_environment_fpm.sh)

# use wget
# apt install wget -y
# wget https://raw.githubusercontent.com/YogSottot/EnDeBx/main/.env.menu.example -O /root/.env.menu
# edit .env.menu with your settings.
# bash <(wget -qO- https://raw.githubusercontent.com/YogSottot/EnDeBx/main/install_full_environment_fpm.sh)

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

BRANCH="main"
REPO_URL="https://github.com/YogSottot/EnDeBx"

DB_NAME="bitrix"
DB_USER="bitrix"
DBPASS=$(generate_password 24)

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

apt update -y
apt upgrade -y --enable-upgrade

if is_astra_linux; then
    apt install -y git locales-all python3-debian python3-pip python3-venv
    python3 -m venv "$PIPX_BOOTSTRAP_VENV"
    "$PIPX_BOOTSTRAP_VENV/bin/python" -m pip install --upgrade pipx
    mkdir -p "$HOME/.local/bin"
    ln -fs "$PIPX_BOOTSTRAP_VENV/bin/pipx" "$HOME/.local/bin/pipx"
    "$PIPX_BOOTSTRAP_VENV/bin/pipx" ensurepath
else
    apt install -y pipx git locales-all python3-debian
fi

site_user_password=$(generate_password 24)

case "${INSTALLER_DOWNLOAD_VM_MENU}" in
  Y)
    # Clone directory vm_menu with repositories
    git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/EnDeBx"
    cd "$DEST_DIR_MENU/EnDeBx"
    git sparse-checkout set $DIR_NAME_MENU

    # Move vm_menu in /root and clean
    rm -rf "${DEST_DIR_MENU:?}/${DIR_NAME_MENU:?}"
    mv -f "$DIR_NAME_MENU" "$DEST_DIR_MENU"
    rm -rf "${DEST_DIR_MENU:?}/EnDeBx"
    ;;
  N)
    if [ ! -d "$DEST_DIR_MENU/$DIR_NAME_MENU" ]; then
      echo "Directory $DEST_DIR_MENU/$DIR_NAME_MENU not found. Upload it first or set INSTALLER_DOWNLOAD_VM_MENU=Y."
      exit 1
    fi
    ;;
  *)
    echo "Unsupported INSTALLER_DOWNLOAD_VM_MENU value: ${INSTALLER_DOWNLOAD_VM_MENU}. Use Y or N."
    exit 1
    ;;
esac

cd "$DEST_DIR_MENU"

chmod -R +x "$DEST_DIR_MENU/$DIR_NAME_MENU"

ln -fs "$FULL_PATH_MENU_FILE" "$DEST_DIR_MENU/menu.sh"

# Final actions
# shellcheck source=/dev/null
source "$DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh"

# shellcheck source=/dev/null
if [ -e "$DEST_DIR_MENU/.env.menu" ]; then
  source "$DEST_DIR_MENU/.env.menu"
fi

# https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html
BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

run_ansible_playbook() {
    if [ "${BS_ANSIBLE_DEBUG_MODE^^}" = "Y" ]; then
        command ansible-playbook -v "$@"
    else
        command ansible-playbook "$@"
    fi
}

# check ansible installation
if pipx list | grep -q "package ansible "; then
    ANSIBLE_INSTALLED_VERSION=$(pipx list | grep "package ansible " | awk '{print $3}' | tr -d ',')
    if [ "$ANSIBLE_INSTALLED_VERSION" != "$BS_ANSIBLE_REQUIRED_VERSION" ]; then
        echo "Reinstalling ansible $BS_ANSIBLE_REQUIRED_VERSION (found $ANSIBLE_INSTALLED_VERSION)..."
        pipx uninstall ansible
        pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
        pipx inject ansible jmespath passlib python-debian psycopg2-binary ipaddress
    else
        echo "Ansible $BS_ANSIBLE_REQUIRED_VERSION already installed."
    fi
else
    echo "Installing ansible $BS_ANSIBLE_REQUIRED_VERSION..."
    pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
    pipx inject ansible jmespath passlib python-debian
fi

DEBIAN_MAJOR_VERSION=$(get_debian_major_version)
UBUNTU_MAJOR_VERSION=$(get_ubuntu_major_version)

if [ -n "${DEBIAN_MAJOR_VERSION}" ] && [ "${DEBIAN_MAJOR_VERSION}" -ge 13 ]; then
      systemctl mask tmp.mount
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
run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_CHANGE_TIMEZONE}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" -e "server_timezone=${BS_SERVER_TIMEZONE}"

DOCUMENT_ROOT="${BS_PATH_DEFAULT_SITE}"

# setup swap
if [ "$BS_SETUP_SWAP" == 'Y'  ]; then
    run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PS_SWAP}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
    -e "swap_file_state='present' \
    swap_file_size_mb=${BS_SWAP_SIZE}"
fi

if [ "$BS_SETUP_REPOS" == 'Y'  ]; then
# setup repos
run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_REPOS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"
fi

# setup nginx modules repo
run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_NGINX_MOD_REPO}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# install deps
run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_DEPS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

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
  run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_BASHRC}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
    -e "user_server_sites=${BS_USER_SERVER_SITES} \
    group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
    default_user_server_sites=${BS_DEFAULT_USER_SERVER_SITES} \
    path_sites=${BS_PATH_SITES} "
fi

if [ "$BS_OPTIMIZE_SYSCTL" == Y  ]; then
  # setup sysctl
  run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SYSCTL}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"
fi

# install docker
run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_DOCKER}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "docker_action=INSTALL \
      docker_packages_state=present \
      docker_user_list=${BS_DEFAULT_USER_SERVER_SITES}"

if [ "$BS_SETUP_RKHUNTER" == Y  ]; then
  run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_RKHUNTER}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "rkhunter_action='INSTALL' \
      rkhunter_notification_email=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      rkhunter_ssh_permit_root_login=${BS_SSH_PERMIT_ROOT_LOGIN}"
fi

if [ "$BS_SETUP_MALDET" == Y  ]; then
  run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_MALDET}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "maldet_action='INSTALL' \
      maldet_email_addr=${BS_EMAIL_ADMIN_FOR_NOTIFY} \
      maldet_home_prefix=${BS_PATH_USER_HOME_PREFIX}"
fi

if [ "$BS_SETUP_SECURITY" == "Y" ]; then
  run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SECURITY}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
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
fi

if [ "$BS_DELETE_SNAPD" == "Y" ]; then
  run_ansible_playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_SNAPD}" "${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}" \
  -e "snapd_action=DELETE"
fi


# fix services
systemctl try-restart postfix.service
systemctl try-restart postfix@-.service
firewall-cmd --reload

# fix journald sizes
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/10-endebx.conf <<'EOF'
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=100M
EOF
systemctl restart systemd-journald

# remove compilers
apt remove build-essential gcc gcc-12 -y
apt autoremove -y

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

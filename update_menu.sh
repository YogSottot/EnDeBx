#!/usr/bin/env bash
set -euo pipefail

readonly BRANCH="feature/php-fpm"
readonly REPO_URL="https://github.com/YogSottot/DebianLikeBitrixVM.git"

readonly DIR_NAME="vm_menu"
readonly DEST_DIR="/root"
readonly BACKUP_DIR="${DEST_DIR}/backup_vm_menu"
readonly TMP_CLONE_DIR="${DEST_DIR}/DebianLikeBitrixVM"

readonly FULL_MENU_PATH="${DEST_DIR}/${DIR_NAME}/menu.sh"

log() {
    echo "[INFO] $*"
}

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

require_root() {
    [[ $EUID -eq 0 ]] || die "Run as root"
}

timestamp() {
    date "+%Y-%m-%d_%H-%M-%S"
}

backup_menu() {
    if [[ -d "${DEST_DIR}/${DIR_NAME}" ]]; then
        backup_path="${BACKUP_DIR}/$(timestamp)"
        mkdir -p "${backup_path}"
        mv "${DEST_DIR}/${DIR_NAME}" "${backup_path}/"
        log "Backup created: ${backup_path}"
    else
        log "No existing menu to backup"
    fi
}

clone_repo() {
    rm -rf "${TMP_CLONE_DIR}"

    git clone \
        --branch="${BRANCH}" \
        --depth=1 \
        --filter=blob:none \
        --sparse \
        "${REPO_URL}" \
        "${TMP_CLONE_DIR}"

    cd "${TMP_CLONE_DIR}"
    git sparse-checkout set "${DIR_NAME}"
}

deploy_menu() {
    rm -rf "${DEST_DIR:?}/${DIR_NAME:?}"
    mv "${TMP_CLONE_DIR}/${DIR_NAME}" "${DEST_DIR}/"
    chmod -R +x "${DEST_DIR}/${DIR_NAME}"
    rm -rf "${TMP_CLONE_DIR}"

    ln -sf "${FULL_MENU_PATH}" "${DEST_DIR}/menu.sh"
    cd "$DEST_DIR"
}

load_config() {
    # shellcheck source=/dev/null
    source "${DEST_DIR}/${DIR_NAME}/bash_scripts/config.sh"

    if [[ -f "${DEST_DIR}/.env.menu" ]]; then
        # shellcheck source=/dev/null
        source "${DEST_DIR}/.env.menu"
    fi
}

update_nginx() {
    cp -f \
        "${DEST_DIR}/${DIR_NAME}/ansible/playbooks/roles/geerlingguy.nginx_config/files/nginx/bx/conf/bitrix_general.conf" \
        "${BS_PATH_NGINX}/conf/bitrix_general.conf"

    cp -f \
        "${DEST_DIR}/${DIR_NAME}/ansible/playbooks/roles/geerlingguy.nginx_config/files/nginx/bx/conf_fpm/bitrix_general.conf" \
        "${BS_PATH_NGINX}/conf_fpm/bitrix_general.conf"

    "${BS_SERVICE_NGINX_NAME}" -t
    systemctl reload "${BS_SERVICE_NGINX_NAME}.service"
}

remove_zstd() {
    rm -f "/etc/${BS_SERVICE_NGINX_NAME}/custom_conf.d/section_http/zstd.conf"
    apt purge -y libnginx-mod-http-zstd || true
}

setup_ansible() {
    # check ansible installation
    # --- remove ansible if installed via apt ---
    if dpkg -s ansible >/dev/null 2>&1; then
        echo "Purging system ansible package..."
        apt purge -y ansible
        apt autoremove -y
    else
        echo "No apt ansible package installed."
    fi

    # Make sure pipx itself exists
    if ! command -v pipx >/dev/null 2>&1; then
        apt update && apt install -y pipx
        python3 -m pipx ensurepath
    fi
    if pipx list | grep -q "package ansible "; then
        ANSIBLE_INSTALLED_VERSION=$(pipx list | grep "package ansible " | awk '{print $3}' | tr -d ',')
        if [ "$ANSIBLE_INSTALLED_VERSION" != "$BS_ANSIBLE_REQUIRED_VERSION" ]; then
            echo "Reinstalling ansible $BS_ANSIBLE_REQUIRED_VERSION (found $BS_ANSIBLE_REQUIRED_VERSION)..."
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
}

run_a2dismod() {
    # make sure apache modules disabled
    a2dismod --force deflate filter negotiation ssl
}

apache_fix_site() {
    APACHE_SITE="/etc/apache2/sites-available/${BS_DEFAULT_SITE_NAME}.conf"
    # Удалить ServerName * и ServerAlias *
    sed -i -E '/^[[:space:]]*Server(Name|Alias)[[:space:]]+\*/d' "$APACHE_SITE"

    # Заменить *:8090 на 127.0.0.1:8091
    sed -i 's|\*:8090|127.0.0.1:8091|g' "$APACHE_SITE"
}

apache_fix_ports() {
    APACHE_PORTS="/etc/apache2/ports.conf"
    # Удалить Listen 127.0.0.1:*
    sed -i -E '/^[[:space:]]*Listen[[:space:]]+127\.0\.0\.1:.*/d' "$APACHE_PORTS"

    # Добавить Listen 127.0.0.1:8090 если нет
    grep -q '^Listen 127\.0\.0\.1:8090$' "$APACHE_PORTS" || \
        echo 'Listen 127.0.0.1:8090' >> "$APACHE_PORTS"

    # Добавить Listen 127.0.0.1:8091 если нет
    grep -q '^Listen 127\.0\.0\.1:8091$' "$APACHE_PORTS" || \
        echo 'Listen 127.0.0.1:8091' >> "$APACHE_PORTS"
}

apache_restart() {
    apache2ctl -t
    systemctl restart apache2.service
}

nginx_fix_site() {
    NGINX_SITE="${BS_PATH_NGINX_SITES_CONF}/${BS_DEFAULT_SITE_NAME}.conf"
    # Заменить 127.0.0.1:8090 на 127.0.0.1:8091
    sed -i 's|127\.0\.0\.1:8090|127.0.0.1:8091|g' "$NGINX_SITE"
}

nginx_reload() {
    "${BS_SERVICE_NGINX_NAME}" -t
    systemctl reload "${BS_SERVICE_NGINX_NAME}.service"
}

main() {
    require_root
    backup_menu
    clone_repo
    deploy_menu
    load_config
    update_nginx
    remove_zstd
    setup_ansible
    run_a2dismod
    apache_fix_site
    apache_fix_ports
    apache_restart
    nginx_fix_site
    nginx_reload

    log "Menu updated! Backup directory old menu: $backup_path";
}

main "$@"

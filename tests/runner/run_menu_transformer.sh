#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

TRANSFORMER_BASELINE_FILE=/var/tmp/endebx-transformer-baseline.json

show_remote_logs() {
  local action=$1

  remote_ssh "tail -n 120 /root/endebx-menu-transformer-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-transformer-${action}.trace || true" >&2 || true
}

run_menu_transformer_action() {
  local action=$1

  if ! remote_ssh TEST_MENU_TRANSFORMER_ACTION="$action" bash -s <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
expect /root/EnDeBx/tests/runner/menu_transformer.expect > "/root/endebx-menu-transformer-${TEST_MENU_TRANSFORMER_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_transformer.expect failed during ${action}; showing recent remote logs" >&2
    show_remote_logs "$action"
    exit 1
  fi
}

transformer_is_installed() {
  remote_ssh bash -s <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"

php_transformer_flag() {
  local php_check_script
  php_check_script=$(mktemp /tmp/endebx-transformer-installed-check.XXXXXX.php)

  cat > "$php_check_script" <<'PHP'
<?php
$docroot = $argv[1];
define("NO_KEEP_STATISTIC", "Y");
define("NO_AGENT_STATISTIC", "Y");
define("NOT_CHECK_PERMISSIONS", true);
define("DisableEventsCheck", true);
define("NO_AGENT_CHECK", true);
$_SERVER["DOCUMENT_ROOT"] = $docroot;
require_once $docroot . "/bitrix/modules/main/include/prolog_before.php";
echo (string)\Bitrix\Main\Config\Option::get("transformercontroller", "host", "", "");
PHP

  chmod 0644 "$php_check_script"
  su -s /bin/bash "$BS_USER_SERVER_SITES" -c "php \"$php_check_script\" \"$site_root\"" 2>/dev/null || true
  rm -f "$php_check_script"
}

test -f /etc/systemd/system/transformer.service
dpkg-query -W -f='${Status}' rabbitmq-server 2>/dev/null | grep -q 'ok installed'
test -n "$(php_transformer_flag)"
REMOTE
}

capture_transformer_install_baseline() {
  remote_ssh bash -s -- "$TRANSFORMER_BASELINE_FILE" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"
php_check_script="$(mktemp /tmp/endebx-transformer-baseline-install.XXXXXX.php)"
baseline_file=$1

cat > "$php_check_script" <<'PHP'
<?php
$docroot = $argv[1];
$baselineFile = $argv[2];

define('NO_KEEP_STATISTIC', 'Y');
define('NO_AGENT_STATISTIC', 'Y');
define('NOT_CHECK_PERMISSIONS', true);
define('DisableEventsCheck', true);
define('NO_AGENT_CHECK', true);

$_SERVER['DOCUMENT_ROOT'] = $docroot;
require_once $docroot . '/bitrix/modules/main/include/prolog_before.php';

function getDefaultTransformerControllerUrl(): string
{
    $domain = (new \Bitrix\Main\License\UrlProvider())->getTechDomain();

    if (\Bitrix\Main\Application::getInstance()->getLicense()->isCis())
    {
        $domain = 'transformer-ru-boxes.' . $domain;
    }
    else
    {
        $domain = 'transformer-de.' . $domain;
    }

    return 'https://' . $domain . '/bitrix/tools/transformercontroller/add_queue.php';
}

$siteId = defined('SITE_ID') && SITE_ID !== '' ? (string)SITE_ID : (string)\Bitrix\Main\Application::getInstance()->getContext()->getSite();
$defaultControllerUrl = getDefaultTransformerControllerUrl();
$state = [
    'portal_url' => \Bitrix\Main\Config\Option::get('transformer', 'portal_url'),
    'transformer_controller_url' => \Bitrix\Main\Config\Option::get(
        'transformer',
        'transformer_controller_url',
        $defaultControllerUrl,
        $siteId
    ),
];

file_put_contents($baselineFile, json_encode($state, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
PHP

chmod 0644 "$php_check_script"
su -s /bin/bash "$BS_USER_SERVER_SITES" -c "php \"$php_check_script\" \"$site_root\" \"$baseline_file\""
rm -f "$php_check_script"
REMOTE
}

prepare_transformer_delete_baseline() {
  remote_ssh bash -s -- "$TRANSFORMER_BASELINE_FILE" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"
php_check_script="$(mktemp /tmp/endebx-transformer-baseline-delete.XXXXXX.php)"
baseline_file=$1

if [ -f "$baseline_file" ]; then
  exit 0
fi

cat > "$php_check_script" <<'PHP'
<?php
$docroot = $argv[1];
$baselineFile = $argv[2];

define('NO_KEEP_STATISTIC', 'Y');
define('NO_AGENT_STATISTIC', 'Y');
define('NOT_CHECK_PERMISSIONS', true);
define('DisableEventsCheck', true);
define('NO_AGENT_CHECK', true);

$_SERVER['DOCUMENT_ROOT'] = $docroot;
require_once $docroot . '/bitrix/modules/main/include/prolog_before.php';

function getDefaultTransformerControllerUrl(): string
{
    $domain = (new \Bitrix\Main\License\UrlProvider())->getTechDomain();

    if (\Bitrix\Main\Application::getInstance()->getLicense()->isCis())
    {
        $domain = 'transformer-ru-boxes.' . $domain;
    }
    else
    {
        $domain = 'transformer-de.' . $domain;
    }

    return 'https://' . $domain . '/bitrix/tools/transformercontroller/add_queue.php';
}

$siteId = defined('SITE_ID') && SITE_ID !== '' ? (string)SITE_ID : (string)\Bitrix\Main\Application::getInstance()->getContext()->getSite();
$savedTransformerControllerUrl = \Bitrix\Main\Config\Option::get(
    'transformercontroller',
    'endebx_previous_transformer_controller_url'
);

if ($savedTransformerControllerUrl === '') {
    $savedTransformerControllerUrl = getDefaultTransformerControllerUrl();
}

$state = [
    'portal_url' => \Bitrix\Main\Config\Option::get('transformer', 'portal_url'),
    'transformer_controller_url' => $savedTransformerControllerUrl,
];

file_put_contents($baselineFile, json_encode($state, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
PHP

chmod 0644 "$php_check_script"
su -s /bin/bash "$BS_USER_SERVER_SITES" -c "php \"$php_check_script\" \"$site_root\" \"$baseline_file\""
rm -f "$php_check_script"
REMOTE
}

validate_transformer_installed() {
  remote_ssh bash -s -- "$TRANSFORMER_BASELINE_FILE" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"
domain="${TEST_MENU_DEFAULT_DOMAIN}"
php_check_script="$(mktemp /tmp/endebx-transformer-install-check.XXXXXX.php)"
baseline_file=$1

dpkg-query -W -f='${Status}' rabbitmq-server 2>/dev/null | grep -q 'ok installed'
systemctl is-active --quiet rabbitmq-server
systemctl is-enabled rabbitmq-server | grep -qx enabled
systemctl is-active --quiet transformer.service
systemctl is-enabled transformer.service | grep -qx enabled

test -f /etc/systemd/system/transformer.service
test -f /usr/local/bin/transformer-workerd
test -f /etc/tmpfiles.d/transformer.conf
test -f /etc/cron.d/bx_transformer
test -f /opt/cronscripts/bx_cleanup.sh
test -d /var/run/transformer
test -d /var/log/transformer
grep -q "/opt/cronscripts/bx_cleanup.sh ${site_root}" /etc/cron.d/bx_transformer

cat > "$php_check_script" <<'PHP'
<?php
$docroot = $argv[1];
$domain = $argv[2];
$userServerSites = $argv[3];
$baselineFile = $argv[4];

define('NO_KEEP_STATISTIC', 'Y');
define('NO_AGENT_STATISTIC', 'Y');
define('NOT_CHECK_PERMISSIONS', true);
define('DisableEventsCheck', true);
define('NO_AGENT_CHECK', true);

$_SERVER['DOCUMENT_ROOT'] = $docroot;
require_once $docroot . '/bitrix/modules/main/include/prolog_before.php';

$baseline = json_decode((string)file_get_contents($baselineFile), true);
$errors = [];
$siteId = defined('SITE_ID') && SITE_ID !== '' ? (string)SITE_ID : (string)\Bitrix\Main\Application::getInstance()->getContext()->getSite();

if (!is_array($baseline)) {
    $errors[] = 'Unable to decode transformer baseline state';
}

if (!\Bitrix\Main\ModuleManager::isModuleInstalled('transformer')) {
    $errors[] = 'Module transformer is not installed';
}

if (!\Bitrix\Main\ModuleManager::isModuleInstalled('transformercontroller')) {
    $errors[] = 'Module transformercontroller is not installed';
}

$portalUrl = \Bitrix\Main\Config\Option::get('transformer', 'portal_url');
$controllerUrl = \Bitrix\Main\Config\Option::get('transformer', 'transformer_controller_url', '', $siteId);
$login = \Bitrix\Main\Config\Option::get('transformercontroller', 'login', '', '');
$host = \Bitrix\Main\Config\Option::get('transformercontroller', 'host', '', '');
$port = \Bitrix\Main\Config\Option::get('transformercontroller', 'port', '', '');
$vhost = \Bitrix\Main\Config\Option::get('transformercontroller', 'vhost', '', '');
$libreofficePath = \Bitrix\Main\Config\Option::get('transformercontroller', 'libreoffice_path', '', '');
$allowedDomains = \Bitrix\Main\Config\Option::get('transformercontroller', 'allowed_domains', '', '');
$savedPreviousControllerUrl = \Bitrix\Main\Config\Option::get(
    'transformercontroller',
    'endebx_previous_transformer_controller_url',
    '',
    ''
);

if ($portalUrl !== (string)($baseline['portal_url'] ?? '')) {
    $errors[] = 'Unexpected transformer.portal_url: ' . $portalUrl;
}

if ($controllerUrl !== 'http://' . $domain . '/bitrix/tools/transformercontroller/add_queue.php') {
    $errors[] = 'Unexpected transformer.transformer_controller_url: ' . $controllerUrl;
}

if ($login !== $userServerSites) {
    $errors[] = 'Unexpected transformercontroller.login: ' . $login;
}

if ($host !== $domain) {
    $errors[] = 'Unexpected transformercontroller.host: ' . $host;
}

if ((string)$port !== '5672') {
    $errors[] = 'Unexpected transformercontroller.port: ' . $port;
}

if ($vhost !== '/') {
    $errors[] = 'Unexpected transformercontroller.vhost: ' . $vhost;
}

if ($libreofficePath !== '/usr/bin/libreoffice') {
    $errors[] = 'Unexpected transformercontroller.libreoffice_path: ' . $libreofficePath;
}

if (strpos($allowedDomains, '"' . $domain . '"') === false) {
    $errors[] = 'transformercontroller.allowed_domains does not contain test domain';
}

if ($savedPreviousControllerUrl !== (string)($baseline['transformer_controller_url'] ?? '')) {
    $errors[] = 'Unexpected saved transformer controller URL: ' . $savedPreviousControllerUrl;
}

if ($errors !== []) {
    fwrite(STDERR, implode("\n", $errors) . "\n");
    exit(1);
}
PHP

chmod 0644 "$php_check_script"
su -s /bin/bash "$BS_USER_SERVER_SITES" -c "php \"$php_check_script\" \"$site_root\" \"$domain\" \"$BS_USER_SERVER_SITES\" \"$baseline_file\""
rm -f "$php_check_script"
REMOTE
}

validate_transformer_removed() {
  remote_ssh bash -s -- "$TRANSFORMER_BASELINE_FILE" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"
php_check_script="$(mktemp /tmp/endebx-transformer-delete-check.XXXXXX.php)"
baseline_file=$1

! dpkg-query -W -f='${Status}' rabbitmq-server 2>/dev/null | grep -q 'ok installed'
! test -e /etc/systemd/system/transformer.service
! test -e /usr/local/bin/transformer-workerd
! test -e /etc/tmpfiles.d/transformer.conf
! test -e /etc/cron.d/bx_transformer
! test -e /opt/cronscripts/bx_cleanup.sh
! test -e /var/run/transformer
! test -e /var/log/transformer

cat > "$php_check_script" <<'PHP'
<?php
$docroot = $argv[1];
$baselineFile = $argv[2];

define('NO_KEEP_STATISTIC', 'Y');
define('NO_AGENT_STATISTIC', 'Y');
define('NOT_CHECK_PERMISSIONS', true);
define('DisableEventsCheck', true);
define('NO_AGENT_CHECK', true);

$_SERVER['DOCUMENT_ROOT'] = $docroot;
require_once $docroot . '/bitrix/modules/main/include/prolog_before.php';

$baseline = json_decode((string)file_get_contents($baselineFile), true);
$siteId = defined('SITE_ID') && SITE_ID !== '' ? (string)SITE_ID : (string)\Bitrix\Main\Application::getInstance()->getContext()->getSite();
$checks = [
    'transformercontroller.login' => \Bitrix\Main\Config\Option::get('transformercontroller', 'login', '', ''),
    'transformercontroller.password' => \Bitrix\Main\Config\Option::get('transformercontroller', 'password', '', ''),
    'transformercontroller.host' => \Bitrix\Main\Config\Option::get('transformercontroller', 'host', '', ''),
    'transformercontroller.vhost' => \Bitrix\Main\Config\Option::get('transformercontroller', 'vhost', '', ''),
    'transformercontroller.port' => \Bitrix\Main\Config\Option::get('transformercontroller', 'port', '', ''),
    'transformercontroller.libreoffice_path' => \Bitrix\Main\Config\Option::get('transformercontroller', 'libreoffice_path', '', ''),
    'transformercontroller.allowed_domains' => \Bitrix\Main\Config\Option::get('transformercontroller', 'allowed_domains', '', ''),
];

$errors = [];

if (!is_array($baseline)) {
    $errors[] = 'Unable to decode transformer baseline state';
}

$portalUrl = \Bitrix\Main\Config\Option::get('transformer', 'portal_url');
$controllerUrl = \Bitrix\Main\Config\Option::get('transformer', 'transformer_controller_url', '', $siteId);
$savedPreviousControllerUrl = \Bitrix\Main\Config\Option::get(
    'transformercontroller',
    'endebx_previous_transformer_controller_url',
    '',
    ''
);

if ($portalUrl !== (string)($baseline['portal_url'] ?? '')) {
    $errors[] = 'Unexpected restored transformer.portal_url: ' . $portalUrl;
}

if ($controllerUrl !== (string)($baseline['transformer_controller_url'] ?? '')) {
    $errors[] = 'Unexpected restored transformer.transformer_controller_url: ' . $controllerUrl;
}

if ($controllerUrl === '') {
    $errors[] = 'transformer.transformer_controller_url is empty after delete';
}

if ($savedPreviousControllerUrl !== '') {
    $errors[] = 'Saved transformer controller URL is not empty after delete: ' . $savedPreviousControllerUrl;
}

foreach ($checks as $name => $value) {
    if ($value !== '') {
        $errors[] = $name . ' is not empty: ' . $value;
    }
}

if ($errors !== []) {
    fwrite(STDERR, implode("\n", $errors) . "\n");
    exit(1);
}
PHP

chmod 0644 "$php_check_script"
su -s /bin/bash "$BS_USER_SERVER_SITES" -c "php \"$php_check_script\" \"$site_root\" \"$baseline_file\""
rm -f "$php_check_script"
rm -f "$baseline_file"
REMOTE
}

echo "Testing menu-managed transformer install/delete on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_transformer.expect" "/root/EnDeBx/tests/runner/menu_transformer.expect"

if transformer_is_installed; then
  echo "Existing transformer installation detected; running delete flow"
  prepare_transformer_delete_baseline
  run_menu_transformer_action delete

  echo "Validating removed transformer"
  validate_transformer_removed
else
  echo "No transformer installation detected; running install flow"
  capture_transformer_install_baseline
  run_menu_transformer_action install

  echo "Validating installed transformer"
  validate_transformer_installed

  echo "Transformer is installed on $(remote_fqdn)."
  echo "Run make menu-transformer again to delete it after manual verification."
fi

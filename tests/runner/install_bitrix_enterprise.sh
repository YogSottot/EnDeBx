#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

test_bitrix_run_stages="${TEST_BITRIX_RUN_STAGES:-}"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
require_command rsync
echo "Uploading vendored bitrix-cli-install helper"
remote_ssh "mkdir -p /root/EnDeBx/tests/vendor/bitrix-cli-install"
RSYNC_RSH="$(rsync_ssh_command)" rsync -az --delete \
  "$REPO_ROOT/tests/vendor/bitrix-cli-install/" \
  "$(remote_ssh_target):/root/EnDeBx/tests/vendor/bitrix-cli-install/"
remote_scp_to "$SCRIPT_DIR/bitrix_enterprise_stage1.yaml" "/root/EnDeBx/tests/runner/bitrix_enterprise_stage1.yaml"
remote_scp_to "$SCRIPT_DIR/bitrix_enterprise_stage2.yaml" "/root/EnDeBx/tests/runner/bitrix_enterprise_stage2.yaml"

echo "Installing Bitrix24 Enterprise on $(remote_fqdn)"
if ! remote_ssh TEST_BITRIX_RUN_STAGES="$test_bitrix_run_stages" bash -s <<'REMOTE'
set -euo pipefail

log_file=/root/endebx-bitrix-install.log
exec > >(tee "$log_file") 2>&1

source /root/vm_menu/bash_scripts/config.sh
if [ -f /root/.env.menu ]; then
  # shellcheck source=/dev/null
  source /root/.env.menu
fi

site_root="${TEST_BITRIX_TARGET_DIR:-$BS_PATH_DEFAULT_SITE}"
installer_dir="${TEST_BITRIX_CLI_INSTALL_DIR:-/root/EnDeBx/tests/vendor/bitrix-cli-install}"
composer_dir=/root/.cache/endebx
composer_bin="$composer_dir/composer.phar"
runner_dir=/root/EnDeBx/tests/runner
debug_root=/root/endebx-bitrix-install-debug
requested_stages="${TEST_BITRIX_RUN_STAGES:-stage1 stage2 stage3}"
stage1_config=bitrix_enterprise_stage1.yaml
stage2_config=bitrix_enterprise_stage2.yaml
db_settings_file="$site_root/bitrix/.settings.php"
dbconn_file="$site_root/bitrix/php_interface/dbconn.php"
db_settings_backup="${db_settings_file}.endebx-test.bak"
dbconn_backup="${dbconn_file}.endebx-test.bak"
default_domain="${TEST_MENU_DEFAULT_DOMAIN:-default.${TEST_VM_FQDN:-}}"
needs_stage1=0
needs_stage2=0
needs_stage1_or_stage2=0

case " ${requested_stages} " in
  *" stage1 "*) needs_stage1=1 ;;
esac

case " ${requested_stages} " in
  *" stage2 "*) needs_stage2=1 ;;
esac

if [ "$needs_stage1" -eq 1 ] || [ "$needs_stage2" -eq 1 ]; then
  needs_stage1_or_stage2=1
fi

if [ ! -d "$site_root" ]; then
  echo "Bitrix document root not found: $site_root" >&2
  exit 1
fi

if [ "$needs_stage1" -eq 1 ] && [ ! -f "$site_root/install.config" ]; then
  echo "Bitrix distributive is not prepared in $site_root" >&2
  exit 1
fi

if [ -z "$default_domain" ]; then
  echo "Unable to detect default test domain for Bitrix installation" >&2
  exit 1
fi

if [ "$needs_stage1_or_stage2" -eq 1 ] && [ ! -f "$installer_dir/composer.json" ] || \
   [ "$needs_stage1_or_stage2" -eq 1 ] && [ ! -x "$installer_dir/bin/bitrix-cli-install" ]; then
  echo "Vendored bitrix-cli-install helper not found in $installer_dir" >&2
  exit 1
fi

restore_db_settings() {
  if [ -f "$db_settings_backup" ]; then
    mv -f "$db_settings_backup" "$db_settings_file"
  fi

  if [ -f "$dbconn_backup" ]; then
    mv -f "$dbconn_backup" "$dbconn_file"
  fi
}

trap restore_db_settings EXIT

if [ "$needs_stage1_or_stage2" -eq 1 ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates git unzip

  if [ -f "$db_settings_file" ]; then
    cp -f "$db_settings_file" "$db_settings_backup"
    php -r '
    $settingsFile = $argv[1];
    $settings = require $settingsFile;
    if (!is_array($settings)) {
        fwrite(STDERR, "Unexpected Bitrix settings format\n");
        exit(1);
    }
    $settings["exception_handling"]["value"]["debug"] = true;
    $content = "<?php\nreturn " . var_export($settings, true) . ";\n";
    if (file_put_contents($settingsFile, $content) === false) {
        fwrite(STDERR, "Failed to write Bitrix settings\n");
        exit(1);
    }
    ' "$db_settings_file"
  fi

  if [ -f "$dbconn_file" ]; then
    cp -f "$dbconn_file" "$dbconn_backup"
    if ! grep -q "SHORT_INSTALL_CHECK" "$dbconn_file"; then
      perl -0pi -e "s/define\\('SHORT_INSTALL', true\\);/define('SHORT_INSTALL', true);\\ndefine('SHORT_INSTALL_CHECK', true);/" "$dbconn_file"
    fi
  fi

  mkdir -p "$composer_dir"
  if [ ! -f "$composer_bin" ] || ! php "$composer_bin" --version >/dev/null 2>&1; then
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
    php /tmp/composer-setup.php --quiet --install-dir "$composer_dir" --filename "$(basename "$composer_bin")"
    rm -f /tmp/composer-setup.php
  fi

  export COMPOSER_ALLOW_SUPERUSER=1
  php "$composer_bin" install --working-dir "$installer_dir" --no-interaction --prefer-dist --no-progress
fi

eval "$(
  php -r '
  $settingsFile = $argv[1];
  $dbconnFile = $argv[2];
  $vars = [];

  if (is_file($settingsFile)) {
      $settings = require $settingsFile;
      $conn = $settings["connections"]["value"]["default"] ?? [];
      if (is_array($conn) && $conn !== []) {
          $className = (string)($conn["className"] ?? "");
          $vars = [
              "BITRIX_DB_TYPE" => str_contains($className, "Pgsql") ? "pgsql" : "mysql",
              "BITRIX_DB_HOST" => (string)($conn["host"] ?? ""),
              "BITRIX_DB_NAME" => (string)($conn["database"] ?? ""),
              "BITRIX_DB_LOGIN" => (string)($conn["login"] ?? ""),
              "BITRIX_DB_PASSWORD" => (string)($conn["password"] ?? ""),
          ];
      }
  }

  if ($vars === [] && is_file($dbconnFile)) {
      $DBType = $DBHost = $DBName = $DBLogin = $DBPassword = "";
      include $dbconnFile;
      $vars = [
          "BITRIX_DB_TYPE" => (string)$DBType,
          "BITRIX_DB_HOST" => (string)$DBHost,
          "BITRIX_DB_NAME" => (string)$DBName,
          "BITRIX_DB_LOGIN" => (string)$DBLogin,
          "BITRIX_DB_PASSWORD" => (string)$DBPassword,
      ];
  }

  foreach ($vars as $name => $value) {
      printf("export %s=%s\n", $name, escapeshellarg($value));
  }
  ' "$db_settings_file" "$dbconn_file"
)"

: "${BITRIX_DB_TYPE:?Failed to detect Bitrix DB type}"

export BITRIX_ADMIN_LOGIN="${TEST_BITRIX_ADMIN_LOGIN:-admin}"
export BITRIX_ADMIN_PASSWORD="${TEST_BITRIX_ADMIN_PASSWORD:-}"
export BITRIX_ADMIN_EMAIL="${TEST_BITRIX_ADMIN_EMAIL:-admin@example.com}"
export BITRIX_ADMIN_FIRST_NAME="${TEST_BITRIX_ADMIN_FIRST_NAME:-Administrator}"
export BITRIX_ADMIN_LAST_NAME="${TEST_BITRIX_ADMIN_LAST_NAME:-portal}"
export BITRIX_LICENSE_CONTACT_FIRST_NAME="${TEST_BITRIX_LICENSE_CONTACT_FIRST_NAME:-$BITRIX_ADMIN_FIRST_NAME}"
export BITRIX_LICENSE_CONTACT_LAST_NAME="${TEST_BITRIX_LICENSE_CONTACT_LAST_NAME:-$BITRIX_ADMIN_LAST_NAME}"
export BITRIX_LICENSE_CONTACT_EMAIL="${TEST_BITRIX_LICENSE_CONTACT_EMAIL:-$BITRIX_ADMIN_EMAIL}"
export BITRIX_INSTALL_BASE_URI="http://${default_domain}"
export BITRIX_INSTALL_VERIFY_TLS=1
export BITRIX_INSTALL_DEBUG_STEPS=1

: "${BITRIX_ADMIN_LOGIN:?Bitrix admin login is required}"
: "${BITRIX_ADMIN_PASSWORD:?Bitrix admin password is required}"
: "${BITRIX_ADMIN_EMAIL:?Bitrix admin email is required}"
: "${BITRIX_LICENSE_CONTACT_FIRST_NAME:?Bitrix license contact first name is required}"
: "${BITRIX_LICENSE_CONTACT_LAST_NAME:?Bitrix license contact last name is required}"
: "${BITRIX_LICENSE_CONTACT_EMAIL:?Bitrix license contact email is required}"

cd "$runner_dir"

run_installer_stage() {
  local stage_name=$1
  local wizard_config=$2
  local stage_log="/root/endebx-bitrix-${stage_name}.stage.log"
  local stage_debug_dir="${debug_root}/${stage_name}"
  local rc=0

  rm -rf "$stage_debug_dir"
  mkdir -p "$stage_debug_dir"
  export BITRIX_INSTALL_DEBUG_DIR="$stage_debug_dir"
  export BITRIX_INSTALL_SKIP_DISTRIBUTIVE_PREPARATION=0
  unset BITRIX_INSTALL_AUTH_LOGIN BITRIX_INSTALL_AUTH_PASSWORD

  if [ "$stage_name" = stage2 ]; then
    export BITRIX_INSTALL_SKIP_DISTRIBUTIVE_PREPARATION=1
    export BITRIX_INSTALL_AUTH_LOGIN="$BITRIX_ADMIN_LOGIN"
    export BITRIX_INSTALL_AUTH_PASSWORD="$BITRIX_ADMIN_PASSWORD"
  fi

  echo "+ php \"$installer_dir/bin/bitrix-cli-install\" bitrix:install \"$site_root\" \"$site_root\" --wizard-config \"$wizard_config\""

  set +e
  php "$installer_dir/bin/bitrix-cli-install" \
    bitrix:install "$site_root" "$site_root" \
    --wizard-config "$wizard_config" 2>&1 | tee "$stage_log"
  rc=${PIPESTATUS[0]}
  set -e

  if [ "$rc" -ne 0 ]; then
    echo "Bitrix installer command failed for stage ${stage_name} with rc=${rc}" >&2
    exit "$rc"
  fi

  if grep -Eq '(^|[[:space:]])\[ERROR\]' "$stage_log"; then
    echo "Bitrix installer reported an internal error during stage ${stage_name}" >&2
    exit 1
  fi
}

run_post_install_stage3() {
  local stage_log="/root/endebx-bitrix-stage3.stage.log"
  local stage_script
  local stage_output_file
  local option_value
  local rc=0

  stage_script="$(mktemp /tmp/endebx-bitrix-stage3.XXXXXX.php)"
  cat > "$stage_script" <<'PHP'
<?php
$dbType = $argv[1];
$dbHostRaw = $argv[2];
$dbName = $argv[3];
$dbLogin = $argv[4];
$dbPassword = $argv[5];

$host = $dbHostRaw;
$port = null;

if (preg_match('/^\[(.+)\]:(\d+)$/', $dbHostRaw, $matches)) {
    $host = $matches[1];
    $port = (int)$matches[2];
} elseif (substr_count($dbHostRaw, ':') === 1 && preg_match('/^(.+):(\d+)$/', $dbHostRaw, $matches)) {
    $host = $matches[1];
    $port = (int)$matches[2];
}

if ($dbType === 'pgsql') {
    $connectParts = [
        'host=' . $host,
        'dbname=' . $dbName,
        'user=' . $dbLogin,
        'password=' . $dbPassword,
    ];
    if ($port !== null) {
        $connectParts[] = 'port=' . $port;
    }

    $connection = pg_connect(implode(' ', $connectParts));
    if ($connection === false) {
        fwrite(STDERR, "Failed to connect to PostgreSQL\n");
        exit(1);
    }

    pg_query_params(
        $connection,
        'UPDATE b_option SET VALUE = $1 WHERE MODULE_ID = $2 AND NAME = $3',
        ['Y', 'main', 'x_accel_redirect']
    );

    $result = pg_query_params(
        $connection,
        'SELECT VALUE FROM b_option WHERE MODULE_ID = $1 AND NAME = $2',
        ['main', 'x_accel_redirect']
    );

    $row = $result ? pg_fetch_assoc($result) : false;
    if ($row === false) {
        pg_query_params(
            $connection,
            'INSERT INTO b_option (MODULE_ID, NAME, VALUE) VALUES ($1, $2, $3)',
            ['main', 'x_accel_redirect', 'Y']
        );
        $row = ['value' => 'Y'];
    }

    echo trim((string)($row['value'] ?? $row['VALUE'] ?? ''));
    exit(0);
}

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$connection = mysqli_init();
$connection->real_connect($host, $dbLogin, $dbPassword, $dbName, $port ?? 3306);
$connection->set_charset('utf8mb4');

$update = $connection->prepare(
    'UPDATE b_option SET VALUE = ? WHERE MODULE_ID = ? AND NAME = ?'
);
$value = 'Y';
$moduleId = 'main';
$name = 'x_accel_redirect';
$update->bind_param('sss', $value, $moduleId, $name);
$update->execute();
$update->close();

$select = $connection->prepare(
    'SELECT VALUE FROM b_option WHERE MODULE_ID = ? AND NAME = ?'
);
$select->bind_param('ss', $moduleId, $name);
$select->execute();
$select->bind_result($storedValue);
$found = $select->fetch();
$select->close();

if (!$found) {
    $insert = $connection->prepare(
        'INSERT INTO b_option (MODULE_ID, NAME, VALUE) VALUES (?, ?, ?)'
    );
    $insert->bind_param('sss', $moduleId, $name, $value);
    $insert->execute();
    $insert->close();
    $storedValue = 'Y';
}

echo trim((string)$storedValue);
PHP

  echo "+ php \"$stage_script\" ... update b_option set x_accel_redirect=Y ..."

  stage_output_file="$(mktemp /tmp/endebx-bitrix-stage3-output.XXXXXX)"
  set +e
  php "$stage_script" \
    "$BITRIX_DB_TYPE" \
    "$BITRIX_DB_HOST" \
    "$BITRIX_DB_NAME" \
    "$BITRIX_DB_LOGIN" \
    "$BITRIX_DB_PASSWORD" 2>&1 | tee "$stage_log" > "$stage_output_file"
  rc=${PIPESTATUS[0]}
  set -e

  option_value="$(cat "$stage_output_file")"
  rm -f "$stage_script"
  rm -f "$stage_output_file"

  if [ "$rc" -ne 0 ]; then
    echo "Bitrix post-install stage3 failed with rc=${rc}" >&2
    exit "$rc"
  fi

  if ! grep -qx 'Y' <<<"$option_value"; then
    echo "Failed to enable Bitrix x_accel_redirect option" >&2
    exit 1
  fi
}

case " ${requested_stages} " in
  *" stage1 "*) run_installer_stage stage1 "$stage1_config" ;;
esac

case " ${requested_stages} " in
  *" stage2 "*) run_installer_stage stage2 "$stage2_config" ;;
esac

case " ${requested_stages} " in
  *" stage3 "*) run_post_install_stage3 ;;
esac

curl -fsSL "http://${default_domain}/" -o /tmp/endebx-bitrix-homepage.html
if grep -qi '__wizard_form\|Я принимаю лицензионное соглашение' /tmp/endebx-bitrix-homepage.html; then
  echo "Bitrix installation wizard is still shown on the homepage" >&2
  exit 1
fi
REMOTE
then
  echo "install_bitrix_enterprise.sh failed; showing recent remote logs" >&2
  remote_ssh bash -s <<'REMOTE' >&2 || true
set -euo pipefail
tail -n 200 /root/endebx-bitrix-install.log
printf '\n--- debug files ---\n'
find /root/endebx-bitrix-install-debug -maxdepth 2 -type f | sort | tail -n 60 || true
latest_exception=$(find /root/endebx-bitrix-install-debug -type f -name '*.exception.txt' | sort | tail -n 1 || true)
if [ -n "$latest_exception" ]; then
  printf '\n--- latest exception ---\n'
  cat "$latest_exception"
fi
REMOTE
  exit 1
fi

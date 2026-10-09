#!/usr/bin/env bash
set -exuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

show_remote_logs() {
  local feature=$1
  local action=$2

  remote_ssh "tail -n 120 /root/endebx-menu-extensions-${feature}-${action}.log || true" >&2 || true
  remote_ssh "tail -n 120 /tmp/endebx-menu-extensions-${feature}-${action}.trace || true" >&2 || true
}

run_extension_action() {
  local feature=$1
  local action=$2
  local push_remove_redis=${3:-Y}

  if ! remote_ssh \
    TEST_MENU_EXTENSION="$feature" \
    TEST_MENU_EXTENSION_ACTION="$action" \
    TEST_MENU_PUSH_REMOVE_REDIS="$push_remove_redis" \
    TEST_MENU_OPENSEARCH_DASHBOARDS="${TEST_MENU_OPENSEARCH_DASHBOARDS:-Y}" \
    bash -s -- "${TEST_MENU_OPENSEARCH_DASHBOARDS:-Y}" <<'REMOTE'
set -euo pipefail
set -a
source /root/vm_menu/bash_scripts/config.sh
source /root/.env.menu
set +a
export TEST_MENU_OPENSEARCH_DASHBOARDS="$1"
expect /root/EnDeBx/tests/runner/menu_extensions.expect > "/root/endebx-menu-extensions-${TEST_MENU_EXTENSION}-${TEST_MENU_EXTENSION_ACTION}.log" 2>&1
REMOTE
  then
    echo "menu_extensions.expect failed during ${feature}/${action}; showing recent remote logs" >&2
    show_remote_logs "$feature" "$action"
    exit 1
  fi
}

extension_state() {
  local feature=$1

  remote_ssh bash -s -- "$feature" <<'REMOTE'
set -euo pipefail
source /root/vm_menu/bash_scripts/config.sh
if [ -f /root/.env.menu ]; then
  source /root/.env.menu
fi

feature=$1

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

case "$feature" in
  memcached)
    if package_installed memcached || command -v memcached >/dev/null 2>&1; then
      echo installed
    else
      echo absent
    fi
    ;;
  push)
    if [ -f "$BS_PUSH_SERVER_CONFIG" ] || [ -f /etc/systemd/system/push-server.service ] || [ -e /usr/local/bin/push-server-multi ]; then
      echo installed
    else
      echo absent
    fi
    ;;
  sphinx)
    if package_installed sphinxsearch; then
      echo installed
    else
      echo absent
    fi
    ;;
  opensearch)
    if package_installed opensearch || [ -x /usr/share/opensearch/bin/opensearch ]; then
      echo installed
    else
      echo absent
    fi
    ;;
  netdata)
    if command -v netdata >/dev/null 2>&1 || [ -x /usr/sbin/netdata ] || [ -d /etc/netdata ] || package_installed netdata; then
      echo installed
    else
      echo absent
    fi
    ;;
  docker)
    if command -v docker >/dev/null 2>&1 || package_installed docker-ce; then
      echo installed
    else
      echo absent
    fi
    ;;
  mydumper)
    if command -v mydumper >/dev/null 2>&1 || package_installed mydumper; then
      echo installed
    else
      echo absent
    fi
    ;;
  *)
    echo "Unsupported extension state request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

validate_extension_state() {
  local feature=$1
  local expected_state=$2

  remote_ssh bash -s -- "$feature" "$expected_state" "${TEST_MENU_OPENSEARCH_DASHBOARDS:-Y}" <<'REMOTE'
set -Eeuo pipefail
trap 'rc=$?; printf "Extension validation failed: feature=%s state=%s line=%s rc=%s command=%.200s\n" "${feature:-$1}" "${expected_state:-$2}" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit "$rc"' ERR
source /root/vm_menu/bash_scripts/config.sh
if [ -f /root/.env.menu ]; then
  source /root/.env.menu
fi

feature=$1
expected_state=$2
opensearch_dashboards_expected=${3^^}

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

service_is_enabled() {
  systemctl is-enabled "$1" 2>/dev/null | grep -qx enabled
}

service_is_active_any() {
  local service_name

  for service_name in "$@"; do
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
      return 0
    fi
  done

  return 1
}

validate_bitrix_opensearch() {
  local expected_state=$1
  local site_path="${BS_PATH_DEFAULT_SITE}"

  if [ ! -f "$site_path/bitrix/modules/main/include/prolog_before.php" ]; then
    echo "Bitrix core not found in $site_path; skipping Bitrix OpenSearch option validation" >&2
    return 0
  fi

  php -d short_open_tag=1 -r '
    $docroot = $argv[1];
    $expected = $argv[2];
    define("NO_KEEP_STATISTIC", "Y");
    define("NO_AGENT_STATISTIC", "Y");
    define("NOT_CHECK_PERMISSIONS", true);
    define("DisableEventsCheck", true);
    define("NO_AGENT_CHECK", true);
    $_SERVER["DOCUMENT_ROOT"] = $docroot;
    $_SERVER["SERVER_NAME"] = "localhost";
    require_once $docroot . "/bitrix/modules/main/include/prolog_before.php";
    if (!\Bitrix\Main\Loader::includeModule("search")) {
      fwrite(STDERR, "search module is not installed\n");
      exit(2);
    }
    $engine = (string)COption::GetOptionString("search", "full_text_engine");
    if ($expected === "installed") {
      $connection = (string)COption::GetOptionString("search", "opensearch_connection");
      $user = (string)COption::GetOptionString("search", "opensearch_user");
      $index = (string)COption::GetOptionString("search", "opensearch_index");
      if ($engine !== "opensearch" || $connection !== "https://127.0.0.1:9200" || $user !== "bitrix_search" || $index !== "bitrix") {
        fwrite(STDERR, "unexpected OpenSearch options: engine=$engine connection=$connection user=$user index=$index\n");
        exit(3);
      }
    } elseif ($engine === "opensearch") {
      fwrite(STDERR, "OpenSearch engine is still enabled after delete\n");
      exit(4);
    }
  ' "$site_path" "$expected_state"
}

validate_opensearch_access() (
  local test_index="${OPENSEARCH_BITRIX_INDEX}-endebx-test-$(date +%s)-$$"
  local bitrix_auth="${OPENSEARCH_BITRIX_USER}:${OPENSEARCH_BITRIX_PASSWORD}"

  curl -fksS -u "$bitrix_auth" -X PUT "${OPENSEARCH_CONNECTION}/${test_index}" >/dev/null
  trap 'curl -fksS -u "${OPENSEARCH_ADMIN_USER}:${OPENSEARCH_ADMIN_PASSWORD}" -X DELETE "${OPENSEARCH_CONNECTION}/${test_index}" >/dev/null' EXIT

  # Bulk HTTP 200 responses can still contain per-document permission errors.
  printf '{"index":{"_index":"%s","_id":"endebx"}}\n{"title":"EnDeBx OpenSearch smoke test"}\n{"update":{"_index":"%s","_id":"endebx"}}\n{"doc":{"title":"EnDeBx OpenSearch updated"}}\n' "$test_index" "$test_index" |
    curl -fksS -u "$bitrix_auth" -H 'Content-Type: application/x-ndjson' \
      --data-binary @- "${OPENSEARCH_CONNECTION}/_bulk?refresh=true" |
    php -r '
      $result = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
      if (($result["errors"] ?? true) !== false || count($result["items"] ?? []) !== 2) {
        fwrite(STDERR, "OpenSearch bulk indexing failed: " . json_encode($result) . "\n");
        exit(1);
      }
      if (($result["items"][0]["index"]["status"] ?? 0) !== 201 || ($result["items"][1]["update"]["status"] ?? 0) !== 200) {
        fwrite(STDERR, "Unexpected OpenSearch bulk results: " . json_encode($result) . "\n");
        exit(1);
      }
    '

  curl -fksS -u "$bitrix_auth" "${OPENSEARCH_CONNECTION}/${test_index}/_search" |
    php -r '
      $result = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
      $hits = $result["hits"]["hits"] ?? [];
      if (count($hits) !== 1 || ($hits[0]["_source"]["title"] ?? "") !== "EnDeBx OpenSearch updated") {
        fwrite(STDERR, "OpenSearch search after bulk update failed: " . json_encode($result) . "\n");
        exit(1);
      }
    '

  curl -fksS -u "$bitrix_auth" -X DELETE "${OPENSEARCH_CONNECTION}/${test_index}" >/dev/null
  trap - EXIT
)

validate_opensearch_dashboards() {
  local nginx_config="/etc/${BS_SERVICE_NGINX_NAME}/custom_conf.d/section_listen_http_and_https/opensearch.conf"

  if [ "$opensearch_dashboards_expected" = Y ]; then
    package_installed opensearch-dashboards
    test "$(dpkg-query -W -f='${Version}' opensearch-dashboards)" = "$(dpkg-query -W -f='${Version}' opensearch)"
    test -f /etc/apt/sources.list.d/opensearch-dashboards.sources
    test -f "$nginx_config"
    grep -q 'location \^~ /opensearch/' "$nginx_config"
    grep -q 'server.host: "127.0.0.1"' /etc/opensearch-dashboards/opensearch_dashboards.yml
    grep -q 'server.basePath: "/opensearch"' /etc/opensearch-dashboards/opensearch_dashboards.yml
    grep -q 'server.rewriteBasePath: true' /etc/opensearch-dashboards/opensearch_dashboards.yml
    test -n "${OPENSEARCH_DASHBOARDS_PASSWORD}"
    systemctl is-active --quiet opensearch-dashboards
    service_is_enabled opensearch-dashboards
    "${BS_SERVICE_NGINX_NAME}" -t
    curl -fksS -u "${OPENSEARCH_DASHBOARDS_USER}:${OPENSEARCH_DASHBOARDS_PASSWORD}" \
      "${OPENSEARCH_CONNECTION}/_plugins/_security/authinfo" |
      php -r '
        $result = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
        if (!in_array($argv[1], $result["roles"] ?? [], true)) {
          fwrite(STDERR, "Dashboards service user is missing its service role\n");
          exit(1);
        }
      ' "$OPENSEARCH_DASHBOARDS_USER"
    curl -fksS -u "${OPENSEARCH_ADMIN_USER}:${OPENSEARCH_ADMIN_PASSWORD}" \
      "${OPENSEARCH_CONNECTION}/_plugins/_security/api/roles" |
      php -r '
        $roles = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
        $serviceRole = $roles[$argv[1]] ?? [];
        $builtinRole = $roles["kibana_server"] ?? [];
        if (($serviceRole["reserved"] ?? true) || ($serviceRole["static"] ?? true)) {
          fwrite(STDERR, "Dashboards service role must not be reserved or static\n");
          exit(1);
        }
        foreach (["cluster_permissions", "index_permissions", "tenant_permissions"] as $permission) {
          if (!isset($serviceRole[$permission], $builtinRole[$permission]) || $serviceRole[$permission] !== $builtinRole[$permission]) {
            fwrite(STDERR, "Dashboards service role differs from kibana_server: $permission\n");
            exit(1);
          }
        }
      ' "$OPENSEARCH_DASHBOARDS_USER"
    curl -fksS -u "${OPENSEARCH_ADMIN_USER}:${OPENSEARCH_ADMIN_PASSWORD}" \
      'http://127.0.0.1:5601/opensearch/api/status' >/dev/null
    curl -fksS -u "${OPENSEARCH_ADMIN_USER}:${OPENSEARCH_ADMIN_PASSWORD}" \
      'https://127.0.0.1/opensearch/api/status' |
      php -r '
        $result = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
        if (!isset($result["status"])) {
          fwrite(STDERR, "Unexpected Dashboards response through nginx\n");
          exit(1);
        }
      '
    curl -fksS 'https://127.0.0.1/opensearch/app/login' >/dev/null
  else
    ! package_installed opensearch-dashboards
    test ! -e "$nginx_config"
    test ! -e /etc/apt/sources.list.d/opensearch-dashboards.sources
    ! systemctl is-active --quiet opensearch-dashboards
  fi
}

mydumper_repo_exists() {
  local repo_file

  repo_file="$(find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*mydumper*.sources' -print -quit)"
  [ -n "$repo_file" ] && grep -q "mydumper.github.io/mydumper/repo/apt" "$repo_file"
}

case "$feature" in
  memcached)
    if [ "$expected_state" = installed ]; then
      package_installed memcached
      command -v memcached >/dev/null 2>&1
      test -f /etc/memcached.conf
      systemctl is-active --quiet memcached
      service_is_enabled memcached
    else
      ! package_installed memcached
      ! command -v memcached >/dev/null 2>&1
      ! systemctl is-active --quiet memcached
    fi
    ;;
  push)
    if [ "$expected_state" = installed ]; then
      test -f "$BS_PUSH_SERVER_CONFIG"
      test -f /etc/systemd/system/push-server.service
      test -x /usr/local/bin/push-server-multi
      test -L /etc/push-server
      test -L /opt/push-server
      test -d /opt/node_modules/push-server
      test -f /etc/tmpfiles.d/push-server.conf
      test -f /etc/logrotate.d/push-server
      test -d /var/log/push-server
      systemctl is-active --quiet push-server
      service_is_enabled push-server
      package_installed redis-server
      service_is_active_any redis-server redis
    else
      test ! -e "$BS_PUSH_SERVER_CONFIG"
      test ! -e /etc/systemd/system/push-server.service
      test ! -e /usr/local/bin/push-server-multi
      test ! -e /etc/push-server
      test ! -e /opt/push-server
      test ! -e /opt/node_modules/push-server
      test ! -e /etc/tmpfiles.d/push-server.conf
      test ! -e /etc/logrotate.d/push-server
      test ! -e /var/log/push-server
      ! systemctl is-active --quiet push-server
      ! package_installed redis-server
      ! service_is_active_any redis-server redis
    fi
    ;;
  sphinx)
    if [ "$expected_state" = installed ]; then
      package_installed sphinxsearch
      test -f /etc/sphinxsearch/sphinx.conf
      test -f /etc/tmpfiles.d/sphinx.conf
      grep -q "listen.*9312" /etc/sphinxsearch/sphinx.conf
      systemctl is-active --quiet sphinxsearch
      service_is_enabled sphinxsearch
    else
      ! package_installed sphinxsearch
      ! systemctl is-active --quiet sphinxsearch
    fi
    ;;
  opensearch)
    if [ "$expected_state" = installed ]; then
      package_installed opensearch
      test -f /etc/apt/sources.list.d/opensearch.sources
      test -f /etc/apt/keyrings/opensearch.gpg
      test -f /root/opensearch.txt
      grep -q '^OPENSEARCH_ADMIN_PASSWORD=' /root/opensearch.txt
      grep -q '^OPENSEARCH_BITRIX_PASSWORD=' /root/opensearch.txt
      # shellcheck disable=SC1091
      source /root/opensearch.txt
      curl -fksS -u "${OPENSEARCH_ADMIN_USER}:${OPENSEARCH_ADMIN_PASSWORD}" "${OPENSEARCH_CONNECTION}/_cluster/health" >/dev/null
      systemctl is-active --quiet opensearch
      service_is_enabled opensearch
      validate_opensearch_access
      validate_opensearch_dashboards
      validate_bitrix_opensearch installed
    else
      ! package_installed opensearch
      ! systemctl is-active --quiet opensearch
      test ! -e /etc/apt/sources.list.d/opensearch.sources
      test ! -e /etc/apt/keyrings/opensearch.gpg
      test ! -e /root/opensearch.txt
      ! package_installed opensearch-dashboards
      ! systemctl is-active --quiet opensearch-dashboards
      test ! -e /etc/opensearch-dashboards
      test ! -e /usr/share/opensearch-dashboards
      test ! -e /etc/apt/sources.list.d/opensearch-dashboards.sources
      test ! -e "/etc/${BS_SERVICE_NGINX_NAME}/custom_conf.d/section_listen_http_and_https/opensearch.conf"
      validate_bitrix_opensearch absent
    fi
    ;;
  netdata)
    if [ "$expected_state" = installed ]; then
      command -v netdata >/dev/null 2>&1 || test -x /usr/sbin/netdata
      package_installed netdata
      package_installed netdata-plugin-chartsd
      package_installed netdata-plugin-pythond
      test "$(dpkg-query -W -f='${Version}' netdata)" = "$(dpkg-query -W -f='${Version}' netdata-plugin-chartsd)"
      test "$(dpkg-query -W -f='${Version}' netdata)" = "$(dpkg-query -W -f='${Version}' netdata-plugin-pythond)"
      test -d /etc/netdata
      test -f /etc/apt/sources.list.d/netdata.list || test -f /etc/apt/sources.list.d/netdata.sources
      test ! -e /etc/apt/sources.list.d/netdata-temp.sources
      test -f /etc/apt/keyrings/netdata-archive-keyring.asc
      test -f /etc/nginx/custom_conf.d/section_http/upstream_netdata.conf
      test -f /etc/nginx/custom_conf.d/section_listen_http_and_https/netdata.conf
      test -s /etc/nginx/netdata_passwds
      grep -q "upstream netdata" /etc/nginx/custom_conf.d/section_http/upstream_netdata.conf
      grep -q "proxy_pass http://netdata/" /etc/nginx/custom_conf.d/section_listen_http_and_https/netdata.conf
      systemctl is-active --quiet netdata
      service_is_enabled netdata
    else
      ! command -v netdata >/dev/null 2>&1
      ! package_installed netdata
      test ! -e /usr/sbin/netdata
      test ! -e /etc/netdata
      test ! -e /etc/apt/sources.list.d/netdata.list
      test ! -e /etc/apt/sources.list.d/netdata.sources
      test ! -e /etc/apt/sources.list.d/netdata-temp.sources
      test ! -e /etc/apt/keyrings/netdata-archive-keyring.asc
      test ! -e /etc/nginx/custom_conf.d/section_http/upstream_netdata.conf
      test ! -e /etc/nginx/custom_conf.d/section_listen_http_and_https/netdata.conf
      ! systemctl is-active --quiet netdata
    fi
    ;;
  docker)
    if [ "$expected_state" = installed ]; then
      command -v docker >/dev/null 2>&1
      package_installed docker-ce
      package_installed docker-ce-cli
      test -f /etc/apt/sources.list.d/docker.list || test -f /etc/apt/sources.list.d/docker.sources
      systemctl is-active --quiet docker
      service_is_enabled docker
      getent group docker >/dev/null
    else
      ! command -v docker >/dev/null 2>&1
      ! package_installed docker-ce
      ! package_installed docker-ce-cli
      ! systemctl is-active --quiet docker
    fi
    ;;
  mydumper)
    if [ "$expected_state" = installed ]; then
      command -v mydumper >/dev/null 2>&1
      package_installed mydumper
      test -f /etc/apt/keyrings/mydumper.asc
      mydumper_repo_exists
    else
      ! command -v mydumper >/dev/null 2>&1
      ! package_installed mydumper
      test ! -e /etc/apt/keyrings/mydumper.asc
      ! mydumper_repo_exists
    fi
    ;;
  *)
    echo "Unsupported extension validation request: $feature" >&2
    exit 1
    ;;
esac
REMOTE
}

normalize_to_absent() {
  local feature=$1
  local current_state

  current_state="$(extension_state "$feature")"
  if [ "$current_state" = installed ]; then
    if [ "$feature" = push ]; then
      run_extension_action "$feature" delete Y
    else
      run_extension_action "$feature" delete
    fi
    validate_extension_state "$feature" absent
  fi
}

test_extension_install_delete() {
  local feature=$1

  normalize_to_absent "$feature"
  run_extension_action "$feature" install
  validate_extension_state "$feature" installed

  if [ "$feature" = push ]; then
    run_extension_action "$feature" delete Y
  else
    run_extension_action "$feature" delete
  fi

  validate_extension_state "$feature" absent
}

echo "Testing menu-managed extensions on $(remote_fqdn)"
generated_env_menu=$("$SCRIPT_DIR/render_env.sh")
if [ -z "${TEST_MENU_OPENSEARCH_DASHBOARDS:-}" ]; then
  TEST_MENU_OPENSEARCH_DASHBOARDS=$(
    set +x
    # shellcheck source=/dev/null
    source "$generated_env_menu"
    printf '%s' "${TEST_MENU_OPENSEARCH_DASHBOARDS:-Y}"
  )
fi
TEST_MENU_OPENSEARCH_DASHBOARDS=${TEST_MENU_OPENSEARCH_DASHBOARDS^^}
case "$TEST_MENU_OPENSEARCH_DASHBOARDS" in
  Y|N) ;;
  *) echo "TEST_MENU_OPENSEARCH_DASHBOARDS must be Y or N" >&2; exit 1 ;;
esac
echo "OpenSearch Dashboards test selection: $TEST_MENU_OPENSEARCH_DASHBOARDS"
echo "Uploading generated /root/.env.menu"
remote_scp_to "$generated_env_menu" "/root/.env.menu"
remote_ssh "mkdir -p /root/EnDeBx/tests/runner"
remote_scp_to "$SCRIPT_DIR/menu_extensions.expect" "/root/EnDeBx/tests/runner/menu_extensions.expect"

echo "Testing Memcached install/delete"
test_extension_install_delete memcached

#echo "Testing Push server install/delete"
#test_extension_install_delete push

echo "Testing Sphinx install/delete"
test_extension_install_delete sphinx

if remote_ssh "source /root/vm_menu/bash_scripts/config.sh; [ -f /root/.env.menu ] && source /root/.env.menu; test -f \"\$BS_PATH_DEFAULT_SITE/bitrix/modules/main/include/prolog_before.php\""; then
  echo "Testing OpenSearch install/delete"
  test_extension_install_delete opensearch
else
  echo "Skipping OpenSearch install/delete because the default Bitrix site is not installed"
fi

echo "Testing Netdata install/delete"
test_extension_install_delete netdata

echo "Testing Docker install/delete"
test_extension_install_delete docker

echo "Testing mydumper install/delete"
test_extension_install_delete mydumper

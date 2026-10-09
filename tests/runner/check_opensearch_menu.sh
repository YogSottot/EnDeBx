#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/vm_menu/bash_scripts/config.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/vm_menu/bash_scripts/functions.sh"
trap - ERR

clear() { :; }
list_sites() { :; }
press_any_key_to_return_menu() { :; }
dpkg-query() {
  if [ "$TEST_OPENSEARCH_INSTALLED" = Y ]; then
    printf '%s\n' 'install ok installed'
  else
    return 1
  fi
}
run_ansible_playbook() { printf 'PLAYBOOK %s\n' "$*"; }
read() {
  local previous=""
  local arg
  for arg in "$@"; do
    if [ "$previous" = -p ]; then
      printf '%s' "$arg"
    fi
    previous=$arg
  done
  builtin read -r "$@"
}

check_case() {
  local installed=$1
  local default_dashboards=$2
  local input=$3
  local expected=$4
  local output

  TEST_OPENSEARCH_INSTALLED=$installed
  export BS_INSTALL_OPENSEARCH_DASHBOARDS=$default_dashboards
  export BS_SERVICE_NGINX_NAME=angie
  output=$(install_opensearch <<< "$input")

  if [ "$expected" = cancelled ]; then
    [[ "$output" != *PLAYBOOK* && "$output" != *'Install OpenSearch Dashboards?'* ]]
  else
    [[ "$output" = *"opensearch_install_dashboards=${expected}"* ]]
    [[ "$output" = *'service_nginx_name=angie'* ]]
    if [ "$installed" = Y ]; then
      [[ "$output" = *'opensearch_action=DELETE'* && "$output" != *'Install OpenSearch Dashboards?'* ]]
    else
      [[ "$output" = *'OpenSearch? (Y/N): '*'Install OpenSearch Dashboards?'* ]]
      [[ "$output" = *'opensearch_action=INSTALL'* ]]
    fi
  fi
  printf 'PASS: installed=%s default=%s expected=%s\n' "$installed" "$default_dashboards" "$expected"
}

check_case N N $'\nY\nY' true
check_case N Y $'\nY\nN' false
check_case N Y $'\nY\n' true
check_case N N $'\nY\n' false
check_case N N $'\nY\ninvalid\ny' true
check_case N N $'\nY\ninvalid\n' false
check_case N Y $'\nN' cancelled
check_case Y Y $'\nY' false

#!/bin/bash
dir="$(dirname "$(readlink -f "$0")")"
dir_helpers="$dir/helpers"

source "$dir/bash_scripts/config.sh"

# shellcheck source=/dev/null
if [ -e /root/.env.menu ]; then
    source /root/.env.menu
fi

source "$dir/bash_scripts/functions.sh"

main_menu;















#!/usr/bin/env python3
"""Exercise installer guards and menu version selection without installing packages."""
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
installer = (ROOT / "install_full_environment_fpm.sh").read_text()
guards = installer[installer.index('if [ "${BS_INSTALL_DATABASE}" = "mysql" ] &&'):installer.index('POSTGRESQL_VERSION_EFFECTIVE=""')]
functions = (ROOT / "vm_menu/bash_scripts/functions.sh").read_text()
menu = functions[functions.index("function install_mysql() {"):functions.index("function delete_mysql() {")]

for ubuntu, debian in [("22", ""), ("24", ""), ("26", ""), ("28", ""), ("", "12"), ("", "13")]:
    for version in ("5.7", "8.0", "8.4"):
        blocked = (debian == "13" and version != "8.4") or (
            bool(ubuntu) and ((int(ubuntu) >= 24 and version == "5.7") or
                              (int(ubuntu) >= 26 and version == "8.0")))
        for database, flavor in [("mysql", "percona"), ("mysql", "mariadb"), ("pgsql", "percona")]:
            setup = (f'BS_INSTALL_DATABASE={database}; BS_DB_FLAVOR={flavor}; '
                     f'BS_DB_VERSION={version}; UBUNTU_MAJOR_VERSION="{ubuntu}"; '
                     f'DEBIAN_MAJOR_VERSION="{debian}";\n')
            result = subprocess.run(["bash", "-c", setup + guards], capture_output=True, text=True)
            expected = int(bool(blocked and database == "mysql" and flavor == "percona"))
            assert result.returncode == expected, (setup, result)
            if expected and ubuntu and int(ubuntu) >= 26:
                assert "Use Percona 8.4 or MariaDB." in result.stdout

        stubs = f'''
clear() {{ :; }}
get_debian_major_version() {{ printf '%s' '{debian}'; }}
get_ubuntu_major_version() {{ printf '%s' '{ubuntu}'; }}
read_by_def() {{ IFS= read -r "$2"; }}
action_install_mysql() {{ echo "SELECTED:$BS_DB_VERSION"; }}
'''
        answers = ["percona", version] + (["8.4"] if blocked else []) + ["utf8mb4", "utf8mb4_unicode_ci", "Y"]
        result = subprocess.run(["bash", "-c", menu + stubs + "\ninstall_mysql"],
                                input="\n".join(answers) + "\n", capture_output=True, text=True, timeout=5)
        assert result.returncode == 0, result
        assert f'SELECTED:{"8.4" if blocked else version}' in result.stdout, result.stdout
        assert ("is not available" in result.stdout) == bool(blocked), result.stdout
        print(f"PASS: ubuntu={ubuntu or '-'} debian={debian or '-'} percona={version}")

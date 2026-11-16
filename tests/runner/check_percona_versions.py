#!/usr/bin/env python3
"""Exercise installer guards and menu version selection without installing packages."""
from pathlib import Path
import subprocess
import tempfile

import yaml


ROOT = Path(__file__).resolve().parents[2]
installer = (ROOT / "install_full_environment_fpm.sh").read_text()
guards = installer[installer.index('if [ "${BS_INSTALL_DATABASE}" = "mysql" ] &&'):installer.index('POSTGRESQL_VERSION_EFFECTIVE=""')]
functions = (ROOT / "vm_menu/bash_scripts/functions.sh").read_text()
menu = functions[functions.index("function install_mysql() {"):functions.index("function delete_mysql() {")]

for ubuntu, debian in [("22", ""), ("24", ""), ("26", ""), ("28", ""), ("", "12"), ("", "13")]:
    for version in ("5.7", "8.0", "8.4"):
        blocked = version == "8.0" and (debian == "13" or (bool(ubuntu) and int(ubuntu) >= 26))
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

# The minimal tarball client does not print "Percona" in its version output.
detect = functions[functions.index('detect_mysql_version() {'):functions.index('get_debian_major_version() {')]
mysql_menu = functions[functions.index('menu_mysql(){'):functions.index('# Function to sanitize')]
with tempfile.TemporaryDirectory() as directory:
    marker = Path(directory) / 'mysql.tarball'
    for binary in (False, True):
        if binary:
            marker.touch()
        code = (detect + mysql_menu).replace('/usr/local/percona-5.7/mysql.tarball', str(marker))
        stubs = '''
clear() { :; }
mysql() { echo 'mysql Ver 14.14 Distrib 5.7.44-48, for Linux (x86_64) using 6.2'; }
main_menu() { :; }
re-generate_mysql_config() { echo RECONFIGURE; }
delete_mysql() { echo DELETE; }
upgrade_percona_5.7_to_8.0() { echo UPGRADE; }
'''
        result = subprocess.run(['bash', '-c', code + stubs + '\nmenu_mysql'],
                                input='1\n2\n0\n', capture_output=True, text=True, timeout=5)
        assert result.returncode == 0, result
        assert 'RECONFIGURE' in result.stdout and 'DELETE' in result.stdout, result.stdout
        assert 'UPGRADE' not in result.stdout, result.stdout
        assert ('Installed: Percona 5.7.44' in result.stdout) == binary, result.stdout
        assert 'Upgrade percona 5.7 to 8.0' not in result.stdout, result.stdout
        print(f'PASS: minimal client detection and menu, tarball={binary}')

    marker.unlink()
    code = (detect + mysql_menu).replace('/usr/local/percona-5.7/mysql.tarball', str(marker))
    stubs = stubs.replace('using 6.2', 'Percona Server (GPL), Release 48')
    result = subprocess.run(['bash', '-c', code + stubs + '\nmenu_mysql'],
                            input='2\n3\n0\n', capture_output=True, text=True, timeout=5)
    assert result.returncode == 0, result
    assert 'UPGRADE' in result.stdout and 'DELETE' in result.stdout, result.stdout
    print('PASS: package Percona retains upgrade and delete options')

role = ROOT / 'vm_menu/ansible/playbooks/roles/geerlingguy.mysql/tasks'
tasks = yaml.safe_load((role / 'percona-5.7.yml').read_text())
initialize = next(task for task in tasks if task['name'] == 'Initialize Percona system tables')
assert initialize['args']['creates'] == '{{ mysql_datadir }}/mysql'
assert '--initialize-insecure' in initialize['ansible.builtin.command']
download = next(task for task in tasks if task['name'] == 'Download Percona 5.7 archive')
assert download['ansible.builtin.get_url']['checksum'].startswith('sha256:')
print('PASS: guarded initialization and pinned archive checksum')

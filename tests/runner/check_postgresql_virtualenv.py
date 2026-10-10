#!/usr/bin/env python3
import copy
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys
import pwd

import yaml


REPO_ROOT = Path(__file__).resolve().parents[2]
TASKS = REPO_ROOT / "vm_menu/ansible/playbooks/roles/claranet.postgresql/tasks/install.yml"


def main():
    certbot = '--certbot' in sys.argv[1:]
    role = REPO_ROOT / "vm_menu/ansible/playbooks/roles/get_lets_encrypt_certificate/tasks"
    tasks = yaml.safe_load((role / "install_Astra Linux.yml" if certbot else TASKS).read_text())
    start = next(i for i, task in enumerate(tasks)
                 if task["name"] == ("Get system Python version" if certbot else
                                     "Ensure PostgreSQL virtual env is owned by PostgreSQL user"))
    end = next(i for i, task in enumerate(tasks)
               if task["name"] == ("Upgrade pip in virtual environment" if certbot
                                    else "Upgrade pip in PostgreSQL virtual env"))
    checks = copy.deepcopy(tasks[start:end])
    for task in checks:
        task.pop("become_user", None)
        task.pop("become_method", None)
        task.pop("become", None)

    with tempfile.TemporaryDirectory(prefix="endebx-postgresql-venv-") as tmp:
        root = Path(tmp)
        venv = root / "venv"
        if certbot:
            checks = yaml.safe_load(yaml.safe_dump(checks).replace('/opt/certbot', str(venv)))
        env = {**os.environ, "ANSIBLE_LOCAL_TEMP": tmp + "/local",
               "ANSIBLE_REMOTE_TEMP": tmp + "/remote", "ANSIBLE_NOCOLOR": "1"}

        def run(label, expected_change, mismatch=False, expect_failure=False):
            selected = copy.deepcopy(checks)
            if mismatch:
                selected.insert(2 if certbot else 3, {
                    "name": "Simulate an older virtualenv Python version",
                    "ansible.builtin.set_fact": {
                        ("_certbot_virtualenv_python_version" if certbot
                         else "_postgresql_virtualenv_python_version"): {
                            "rc": 0, "stdout": "0.0"}},
                })
            selected[-1]["register"] = "virtualenv_upgrade"
            if not expect_failure:
                selected += [{
                    "name": "Verify whether virtualenv was upgraded",
                    "ansible.builtin.assert": {"that": [
                        "virtualenv_upgrade is changed" if expected_change
                        else "virtualenv_upgrade is not changed"]},
                }, {
                    "name": "Verify the pip3 entry point",
                    "ansible.builtin.command": {
                        "argv": [str(venv / "bin/pip3"), "--version"]},
                    "changed_when": False,
                }]
            play = [{"name": label, "hosts": "localhost", "gather_facts": False,
                     "vars": {"_postgresql_virtualenv_path": str(venv),
                              "postgresql_user": pwd.getpwuid(os.getuid()).pw_name,
                              "_postgresql_general_proxy_env": {},
                              "_postgresql_pythonized_path": os.environ["PATH"]},
                     "tasks": selected}]
            path = root / "test.yml"
            path.write_text(yaml.safe_dump(play))
            result = subprocess.run(
                ["ansible-playbook", "-i", "localhost,", "-c", "local", str(path)],
                env=env, capture_output=True, text=True)
            output = result.stdout + result.stderr
            if expect_failure:
                task_name = "Create or upgrade Certbot virtual env" if certbot else "Create or upgrade PostgreSQL virtual env"
                assert result.returncode != 0 and "FAILED!" in output, output
                assert task_name in output or (not certbot and
                    "Ensure PostgreSQL virtual env is owned by PostgreSQL user" in output), output
            else:
                assert result.returncode == 0, output
            print(f"PASS: {label}", flush=True)

        run("new virtualenv", True)
        system_python = (venv / "bin/python3").resolve()
        system_python_owner = system_python.stat().st_uid
        run("healthy virtualenv", False)
        assert system_python.stat().st_uid == system_python_owner
        if not certbot:
            metadata = venv / "lib" / "ownership-fixture"
            metadata.write_text("ownership check\n")
            run("virtualenv with nested files", False)
            assert metadata.stat().st_uid == os.getuid()
        for site_packages in venv.glob("lib/python*/site-packages"):
            for package in site_packages.glob("pip*"):
                shutil.rmtree(package)
        run("missing pip with existing pip3 script", True)
        run("repeated execution after pip repair", False)
        python = venv / "bin/python3"
        python_target = python.readlink()
        python.unlink()
        python.symlink_to(root / "removed-python")
        run("unrepairable interpreter errors remain fatal", True, expect_failure=True)
        python.unlink()
        python.symlink_to(python_target)
        run("Python version mismatch (simulated)", True, mismatch=True)
        run("repeated execution after Python upgrade", False)
        shutil.rmtree(venv)
        venv.write_text("not a directory\n")
        run("virtualenv creation errors remain fatal", True, expect_failure=True)

        if certbot:
            parent_tasks = yaml.safe_load((role / "main.yml").read_text())
            include = copy.deepcopy(next(task for task in parent_tasks
                                         if task["name"] == "Include task for astra"))
            stub = root / "included.yml"
            stub.write_text(yaml.safe_dump([{
                "name": "Record virtualenv installation check",
                "ansible.builtin.set_fact": {"virtualenv_checked": True},
            }]))
            include["ansible.builtin.include_tasks"] = str(stub)
            plays = []
            for label, stat, expected in [
                ("missing Certbot", {"exists": False}, True),
                ("existing virtualenv Certbot", {"exists": True,
                 "lnk_source": "/opt/certbot/bin/certbot"}, True),
                ("system Certbot", {"exists": True}, False),
                ("unrelated Certbot symlink", {"exists": True,
                 "lnk_source": "/usr/local/bin/certbot"}, False),
            ]:
                plays.append({"name": label, "hosts": "localhost", "gather_facts": False,
                              "vars": {"certbot_symlink": {"stat": stat},
                                       "virtualenv_checked": False},
                              "tasks": [include, {
                                  "name": "Verify virtualenv installation selection",
                                  "ansible.builtin.assert": {"that": [
                                      "virtualenv_checked" if expected else "not virtualenv_checked"]},
                              }, {"name": "Reset selection result",
                                  "ansible.builtin.set_fact": {"virtualenv_checked": False}}]})
            path = root / "selection.yml"
            path.write_text(yaml.safe_dump(plays))
            result = subprocess.run(
                ["ansible-playbook", "-i", "localhost,", "-c", "local", str(path)],
                env=env, capture_output=True, text=True)
            assert result.returncode == 0, result.stdout + result.stderr
            print("PASS: Certbot installation selection (4 cases)", flush=True)


if __name__ == "__main__":
    main()

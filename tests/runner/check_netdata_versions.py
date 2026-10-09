#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile

import yaml


REPO_ROOT = Path(__file__).resolve().parents[2]
ROLE = REPO_ROOT / "vm_menu/ansible/playbooks/roles/install_or_delete_netdata/tasks/main.yml"


def main():
    tasks = yaml.safe_load(ROLE.read_text())[0]["block"]
    start = next(i for i, task in enumerate(tasks)
                 if task["name"] == "Find common Netdata package versions")
    end = next(i for i, task in enumerate(tasks)
               if task["name"] == "Install Netdata packages")
    cases = [
        ("repository mismatch", [["2.12.0"], ["2.12.1", "2.12.0"],
                                 ["2.12.1", "2.12.0"]], "2.12.0"),
        ("numeric ordering", [["2.9.0", "2.12.0"]] * 3, "2.12.0"),
        ("Debian epoch", [["1:2.0", "2.12.0"]] * 3, "1:2.0"),
        ("missing common version", [["2.12.0"], ["2.12.1"], ["2.12.0"]], None),
        ("empty package list", [["2.12.0"], [], ["2.12.0"]], None),
    ]
    with tempfile.TemporaryDirectory(prefix="endebx-netdata-") as tmp:
        for label, versions, expected in cases:
            results = [{"stdout": "\n".join(
                f"  package |   {version}  | http://repository/ Packages"
                for version in package_versions)} for package_versions in versions]
            checks = tasks[start:end]
            if expected is not None:
                checks = checks + [{
                    "name": "Verify selected version and package specifications",
                    "ansible.builtin.assert": {"that": [
                        "netdata_selected_version.stdout == expected_version",
                        "package_specs == expected_specs",
                    ]},
                }]
            play = [{"name": label, "hosts": "localhost", "gather_facts": False,
                     "vars": {"netdata_available_versions": {"results": results},
                              "expected_version": expected,
                              "package_specs": tasks[end]["ansible.builtin.apt"]["name"],
                              "expected_specs": [f"{package}={expected}" for package in
                                                 ("netdata", "netdata-plugin-chartsd",
                                                  "netdata-plugin-pythond")]},
                     "tasks": checks}]
            path = Path(tmp) / "test.yml"
            path.write_text(yaml.safe_dump(play))
            result = subprocess.run(
                ["ansible-playbook", "-i", "localhost,", "-c", "local", str(path)],
                env={**os.environ, "ANSIBLE_LOCAL_TEMP": tmp + "/local",
                     "ANSIBLE_REMOTE_TEMP": tmp + "/remote", "ANSIBLE_NOCOLOR": "1"},
                capture_output=True, text=True)
            output = result.stdout + result.stderr
            if expected is None:
                assert result.returncode != 0 and "No common version is available" in output, output
            else:
                assert result.returncode == 0, output
            print(f"PASS: {label}")


if __name__ == "__main__":
    main()

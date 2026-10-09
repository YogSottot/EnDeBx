#!/usr/bin/env python3
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile


REPO_ROOT = Path(__file__).resolve().parents[2]


def remote_fixture():
    arguments = sys.argv[2:]
    payload = sys.stdin.read()
    fixture = Path(os.environ["CHECK_FIXTURE"])
    environment = dict(os.environ)
    if arguments[0].startswith("TEST_MENU_EXTENSION="):
        while arguments and arguments[0] != "bash":
            key, value = arguments.pop(0).split("=", 1)
            environment[key] = value
    else:
        # Run the real validator's setup without requiring installed services.
        payload = payload.split("\npackage_installed() {", 1)[0]
        payload += '\nprintf "VALIDATE %s\\n" "$opensearch_dashboards_expected" >> "$CHECK_RESULTS"\n'
        if environment.get("CHECK_FORCE_FAILURE") == "1":
            payload += 'missing_config() { test -f "$CHECK_FIXTURE/missing-config"; }\nmissing_config\n'
    payload = payload.replace("/root/vm_menu/bash_scripts/config.sh", str(fixture / "config.sh"))
    payload = payload.replace("/root/.env.menu", str(fixture / "env.menu"))
    payload = payload.replace("/root/EnDeBx/tests/runner/menu_extensions.expect", str(fixture / "fake.expect"))
    payload = payload.replace("/root/endebx-menu-extensions-", str(fixture / "menu-extensions-"))
    arguments[1:1] = ["--noprofile", "--norc"]
    return subprocess.run(arguments, input=payload, text=True, env=environment).returncode


def main():
    runner = (REPO_ROOT / "tests/runner/run_menu_extensions.sh").read_text()
    functions = []
    for name, following in (
        ("run_extension_action", "extension_state"),
        ("validate_extension_state", "normalize_to_absent"),
    ):
        start = runner.index(f"\n{name}() {{")
        end = runner.index(f"\n{following}() {{", start)
        functions.append(runner[start:end])
    configuration = re.search(
        r'^generated_env_menu=.*?(?=^echo "Uploading generated)', runner, re.M | re.S,
    )
    assert configuration is not None
    body = "\n".join([
        'SCRIPT_DIR="$CHECK_FIXTURE"',
        f'remote_ssh() {{ {shlex.quote(sys.executable)} {shlex.quote(str(Path(__file__).resolve()))} --remote-fixture "$@"; }}',
        'show_remote_logs() { :; }',
        *functions,
        configuration.group(),
        'run_extension_action opensearch install',
        'validate_extension_state opensearch installed',
    ])
    with tempfile.TemporaryDirectory(prefix="endebx-extensions-config-") as directory:
        fixture = Path(directory)
        (fixture / "config.sh").write_text("BS_INSTALL_OPENSEARCH_DASHBOARDS=N\n")
        renderer = fixture / "render_env.sh"
        renderer.write_text('#!/bin/sh\nprintf "%s\\n" "$CHECK_FIXTURE/env.menu"\n')
        renderer.chmod(0o755)
        (fixture / "fake.expect").write_text(
            '#!/bin/sh\nprintf "EXPECT %s\\n" "$TEST_MENU_OPENSEARCH_DASHBOARDS" >> "$CHECK_RESULTS"\n'
        )
        expect = fixture / "expect"
        expect.write_text('#!/bin/sh\nexec sh "$1"\n')
        expect.chmod(0o755)
        cases = (
            ("file disables Dashboards", "N", None, "N", False),
            ("file enables Dashboards", "Y", None, "Y", False),
            ("default enables Dashboards", None, None, "Y", False),
            ("CLI enables over file N", "N", "Y", "Y", False),
            ("CLI disables over file Y", "Y", "N", "N", False),
            ("lowercase file", "n", None, "N", False),
            ("lowercase CLI", "N", "y", "Y", False),
            ("empty CLI uses file", "N", "", "N", False),
            ("invalid file", "invalid", None, None, False),
            ("invalid CLI", "N", "invalid", None, False),
            ("failed validation diagnostic", "N", None, "N", True),
        )
        for name, configured, override, expected, failure in cases:
            env_menu = 'TEST_SECRET="fixture_secret_not_for_logs"\n'
            if configured is not None:
                env_menu += f"TEST_MENU_OPENSEARCH_DASHBOARDS={shlex.quote(configured)}\n"
            (fixture / "env.menu").write_text(env_menu)
            results = fixture / "results"
            results.write_text("")
            environment = dict(
                os.environ, HOME=directory, CHECK_FIXTURE=directory, CHECK_RESULTS=str(results),
                CHECK_FORCE_FAILURE="1" if failure else "0",
                PATH=f"{fixture}:{os.environ['PATH']}",
            )
            environment.pop("TEST_MENU_OPENSEARCH_DASHBOARDS", None)
            environment.pop("BASH_ENV", None)
            if override is not None:
                environment["TEST_MENU_OPENSEARCH_DASHBOARDS"] = override
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-exuo", "pipefail", "-c", body],
                env=environment, capture_output=True, text=True,
            )
            output = result.stdout + result.stderr
            assert "fixture_secret_not_for_logs" not in output, output
            assert (result.returncode != 0) == (expected is None or failure), output
            if expected is None:
                assert results.read_text() == "", output
                assert "TEST_MENU_OPENSEARCH_DASHBOARDS must be Y or N" in output, output
            else:
                assert results.read_text() == f"EXPECT {expected}\nVALIDATE {expected}\n", output
            if failure:
                assert "Extension validation failed: feature=opensearch state=installed" in output, output
                assert 'command=test -f "$CHECK_FIXTURE/missing-config"' in output, output
            print(f"PASS: {name}")
    return 0


if __name__ == "__main__":
    sys.exit(remote_fixture() if len(sys.argv) > 1 and sys.argv[1] == "--remote-fixture" else main())

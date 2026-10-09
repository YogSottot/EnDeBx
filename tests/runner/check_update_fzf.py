#!/usr/bin/env python3
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile


repo = Path(__file__).resolve().parents[2]
script = (repo / "update_menu.sh").read_text()
function = re.search(r"^fix_fzf_key_bindings\(\) \{\n.*?^\}", script, re.M | re.S)
assert function is not None
assert re.search(r"load_config\s+fix_fzf_key_bindings", script)
original = "source /usr/share/doc/fzf/examples/key-bindings.bash"
guarded = "[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && " + original

with tempfile.TemporaryDirectory(prefix="endebx-fzf-") as directory:
    base = Path(directory)
    root = base / "root/.bashrc"
    skel = base / "skel/.bashrc"
    homes = base / "user homes"
    user = homes / "user one/.bashrc"
    unchanged = homes / "other/.bashrc"
    for path in (root, skel, user, unchanged):
        path.parent.mkdir(parents=True, exist_ok=True)
    (homes / "missing").mkdir()
    root.write_text(original + "\n")
    skel.write_text("  " + original + "  \n")
    user.write_text(original + "\n" + guarded + "\n")
    untouched = "# " + original + "\n" + original + ".backup\n"
    unchanged.write_text(untouched)
    body = function.group().replace("/root/.bashrc", shlex.quote(str(root)))
    body = body.replace("/etc/skel/.bashrc", shlex.quote(str(skel)))

    def run():
        subprocess.run(
            ["bash", "-euo", "pipefail", "-c", body + "\nfix_fzf_key_bindings"],
            env={**os.environ, "BS_PATH_USER_HOME_PREFIX": str(homes)},
            check=True,
        )

    run()
    assert root.read_text() == guarded + "\n"
    assert skel.read_text() == "  " + guarded + "\n"
    assert user.read_text() == (guarded + "\n") * 2
    assert unchanged.read_text() == untouched
    before = {path: path.read_bytes() for path in (root, skel, user, unchanged)}
    run()
    assert all(path.read_bytes() == data for path, data in before.items())
    for path in before:
        path.unlink()
    run()

print("PASS: fzf guards, custom home prefix, missing files and repeated execution")

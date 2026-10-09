#!/usr/bin/env python3
import base64
import copy
import http.server
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import threading

import yaml


REPO_ROOT = Path(__file__).resolve().parents[2]
PERMISSIONS = {
    "cluster_permissions": ["cluster_monitor", "cluster_composite_ops", "manage_point_in_time"],
    "index_permissions": [{
        "index_patterns": [".kibana*", ".opensearch_dashboards*"],
        "allowed_actions": ["indices_all"],
        "dls": "",
        "fls": [],
        "masked_fields": [],
    }],
    "tenant_permissions": [{
        "tenant_patterns": ["fixture_tenant"],
        "allowed_actions": ["kibana_all_write"],
    }],
}
BUILTIN_ROLE = dict(PERMISSIONS, reserved=True, static=True, hidden=False)
BUILTIN_MAPPING = {"reserved": True, "users": ["kibanaserver"]}
INITIAL_CONFIG = {"config": {"dynamic": {
    "kibana": {"server_username": "kibanaserver", "index": ".kibana", "private_tenant_enabled": True},
    "http": {"anonymous_auth_enabled": False},
}}}
INITIAL_SETTINGS = {
    "defaults": {
        "cluster.blocks.create_index": "false",
        "cluster.blocks.create_index.auto_release": "true",
        "cluster.routing.allocation.disk.watermark.high": "90%",
    },
    "persistent": {},
    "transient": {},
}
FILESYSTEM_USAGE = {"nodes": {"fixture_node": {
    "name": "fixture_node",
    "fs": {"data": [{
        "path": "/var/lib/opensearch/nodes/0",
        "mount": "/",
        "total_in_bytes": 100 * 1024**3,
        "available_in_bytes": 5 * 1024**3,
    }]},
}}}
roles = {"kibana_server": copy.deepcopy(BUILTIN_ROLE)}
users = {}
config = copy.deepcopy(INITIAL_CONFIG)
cluster_settings = copy.deepcopy(INITIAL_SETTINGS)
requests = []
health_status = 200
block_on_health_request = False
login_status = 200
login_requests = []
service_user = "endebx_dashboards_test"


class SecurityAPI(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def respond(self, status, body, content_type="application/json"):
        content = body.encode() if isinstance(body, str) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def handle_request(self):
        if self.command == "GET" and self.path == "/opensearch/app/login":
            login_requests.append((self.path, self.headers.get("Authorization"), self.headers.get("Cookie")))
            self.respond(login_status, "<!doctype html><html><body>Login</body></html>", "text/html; charset=utf-8")
            return
        expected_auth = "Basic " + base64.b64encode(b"admin:fixture_admin_password").decode()
        if self.headers.get("Authorization") != expected_auth:
            self.respond(401, {"status": "UNAUTHORIZED"})
            return
        requests.append((self.command, self.path))
        body = None
        if self.command != "GET":
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        if self.command == "GET" and self.path == "/":
            self.respond(200, {"version": {"number": "3.9.0"}})
        elif self.command == "GET" and self.path == "/_cluster/settings?include_defaults=true&flat_settings=true":
            self.respond(200, cluster_settings)
        elif self.command == "GET" and self.path.startswith("/_nodes/stats/fs?"):
            self.respond(200, FILESYSTEM_USAGE)
        elif self.command == "GET" and self.path == "/opensearch/api/status":
            if block_on_health_request:
                cluster_settings["persistent"]["cluster.blocks.create_index"] = "true"
            self.respond(health_status, {"status": "available" if health_status == 200 else "unavailable"})
        elif self.command == "GET" and self.path == "/_plugins/_security/api/roles/kibana_server":
            self.respond(200, {"kibana_server": roles["kibana_server"]})
        elif self.command == "PUT" and self.path == f"/_plugins/_security/api/roles/{service_user}":
            if any(field in body for field in ("reserved", "hidden", "static")):
                self.respond(400, {"message": "Role metadata must not be copied"})
                return
            created = service_user not in roles
            roles[service_user] = body
            self.respond(201 if created else 200, {"status": "CREATED" if created else "OK"})
        elif self.command == "PUT" and self.path == f"/_plugins/_security/api/internalusers/{service_user}":
            for role in body.get("opendistro_security_roles", []):
                # OpenSearch 3.9 rejects assignments through reserved role mappings.
                if role == "kibana_server" and BUILTIN_MAPPING["reserved"]:
                    self.respond(403, {"status": "FORBIDDEN", "message": "Resource 'kibana_server' is reserved."})
                    return
                if role not in roles:
                    self.respond(404, {"message": "Assigned role does not exist"})
                    return
            users[service_user] = body
            self.respond(200, {"status": "OK"})
        elif self.command == "GET" and self.path == "/_plugins/_security/api/securityconfig":
            self.respond(200, config)
        elif self.command == "PATCH" and self.path == "/_plugins/_security/api/securityconfig":
            if len(body) != 1 or body[0]["op"] != "add" or body[0]["path"] != "/config/dynamic/kibana":
                self.respond(400, {"message": "Unexpected configuration patch"})
                return
            config["config"]["dynamic"]["kibana"] = body[0]["value"]
            self.respond(200, {"status": "OK"})
        else:
            self.respond(404, {"message": "Unexpected API request"})

    do_GET = handle_request
    do_PUT = handle_request
    do_PATCH = handle_request


def expand_task_imports(tasks, tasks_dir):
    expanded = []
    for task in tasks:
        if "ansible.builtin.import_tasks" in task:
            imported = tasks_dir / task["ansible.builtin.import_tasks"]
            expanded.extend(expand_task_imports(yaml.safe_load(imported.read_text()), tasks_dir))
        else:
            task = copy.deepcopy(task)
            for section in ("block", "rescue", "always"):
                if section in task:
                    task[section] = expand_task_imports(task[section], tasks_dir)
            expanded.append(task)
    return expanded


def check_login_probe(server_port, temp_dir):
    global login_status
    runner = (REPO_ROOT / "tests/runner/run_menu_extensions.sh").read_text()
    probe = re.search(r"^    curl -fksS 'https://127\.0\.0\.1/opensearch/[a-z]+/login' >/dev/null$", runner, re.M)
    assert probe is not None, "Missing anonymous Dashboards login page probe"
    command = probe.group().replace("https://127.0.0.1", f"http://127.0.0.1:{server_port}")
    environment = dict(os.environ, HOME=temp_dir)
    environment.pop("BASH_ENV", None)
    for status in (200, 401, 503):
        login_status = status
        login_requests.clear()
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", "-euo", "pipefail", "-c", command],
            env=environment, capture_output=True, text=True,
        )
        assert (result.returncode == 0) == (status == 200), result.stdout + result.stderr
        assert login_requests == [("/opensearch/app/login", None, None)], login_requests
        print(f"PASS: anonymous browser login page, HTTP {status}")


def main():
    global cluster_settings, health_status, block_on_health_request
    ansible = shutil.which("ansible-playbook")
    if not ansible:
        raise RuntimeError("ansible-playbook is required")
    tasks_file = REPO_ROOT / "vm_menu/ansible/playbooks/opensearch/roles/linux/opensearch/tasks/dashboards.yml"
    tasks = yaml.safe_load(tasks_file.read_text())
    api_tasks = [task for task in tasks if (
        "opensearch_connection" in task.get("ansible.builtin.uri", {}).get("url", "")
        or task.get("ansible.builtin.import_tasks") == "check_index_creation.yml"
    )]
    assert any("ansible.builtin.import_tasks" in task for task in api_tasks), "Missing index creation preflight"
    guard_tasks = yaml.safe_load((tasks_file.parent / "check_index_creation.yml").read_text())
    readiness = next(task for task in tasks if task["name"] == "Check OpenSearch Dashboards readiness")
    readiness = expand_task_imports([readiness], tasks_file.parent)
    readiness[0]["block"][0].update(retries=1, delay=0)
    with http.server.ThreadingHTTPServer(("127.0.0.1", 0), SecurityAPI) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory(prefix="endebx-dashboards-security-") as temp_dir:
                check_login_probe(server.server_port, temp_dir)
                playbook = [{
                    "name": "Check Dashboards reserved role compatibility",
                    "hosts": "localhost",
                    "connection": "local",
                    "gather_facts": False,
                    "vars": {
                        "ansible_python_interpreter": sys.executable,
                        "opensearch_connection": f"http://127.0.0.1:{server.server_port}",
                        "opensearch_admin_user": "admin",
                        "opensearch_admin_password": "fixture_admin_password",
                        "opensearch_dashboards_user": service_user,
                        "opensearch_dashboards_password": "fixture_service_password",
                        "opensearch_dashboards_port": server.server_port,
                    },
                    "tasks": expand_task_imports(api_tasks, tasks_file.parent),
                }]
                playbook_file = Path(temp_dir) / "check.json"
                fixture_bin = Path(temp_dir) / "bin"
                fixture_bin.mkdir()
                journal = fixture_bin / "journalctl"
                journal.write_text(
                    "#!/bin/sh\n"
                    '[ "$*" = "--unit=opensearch-dashboards --no-pager --lines=40" ] || exit 1\n'
                    "printf '%s\\n' 'fixture migration error'\n"
                )
                journal.chmod(0o755)
                environment = dict(
                    os.environ, ANSIBLE_LOCAL_TEMP=temp_dir, ANSIBLE_REMOTE_TEMP=temp_dir,
                    PATH=f"{fixture_bin}:{os.environ['PATH']}",
                )

                def run_tasks(selected_tasks):
                    playbook[0]["tasks"] = selected_tasks
                    playbook_file.write_text(json.dumps(playbook))
                    return subprocess.run(
                        [ansible, "-i", "localhost,", str(playbook_file)],
                        env=environment, capture_output=True, text=True,
                    )

                for attempt in range(2):
                    result = run_tasks(expand_task_imports(api_tasks, tasks_file.parent))
                    if result.returncode:
                        sys.stderr.write(result.stdout + result.stderr)
                        return result.returncode
                    assigned_roles = users[service_user]["opendistro_security_roles"]
                    assert assigned_roles == [service_user], assigned_roles
                    assert {field: roles[service_user][field] for field in PERMISSIONS} == PERMISSIONS
                    assert roles["kibana_server"] == BUILTIN_ROLE
                    expected_config = copy.deepcopy(INITIAL_CONFIG)
                    expected_config["config"]["dynamic"]["kibana"]["server_username"] = service_user
                    assert config == expected_config
                    print(f"PASS: REST security tasks, reserved mapping, copied permissions, preserved config, run={attempt + 1}")

                for name, overrides, blocked in (
                    ("default block", {"defaults": {"cluster.blocks.create_index": "true"}}, True),
                    ("persistent block", {"persistent": {"cluster.blocks.create_index": "true"}}, True),
                    ("boolean block", {"persistent": {"cluster.blocks.create_index": True}}, True),
                    ("transient block", {
                        "persistent": {"cluster.blocks.create_index": "false"},
                        "transient": {"cluster.blocks.create_index": "true"},
                    }, True),
                    ("transient override", {
                        "persistent": {"cluster.blocks.create_index": "true"},
                        "transient": {"cluster.blocks.create_index": "false"},
                    }, False),
                ):
                    cluster_settings = copy.deepcopy(INITIAL_SETTINGS)
                    for scope, values in overrides.items():
                        cluster_settings[scope].update(values)
                    original_settings = copy.deepcopy(cluster_settings)
                    requests.clear()
                    result = run_tasks(guard_tasks)
                    output = result.stdout + result.stderr
                    assert (result.returncode != 0) == blocked, output
                    assert all(method == "GET" for method, _ in requests), requests
                    assert cluster_settings == original_settings
                    assert any(path.startswith("/_nodes/stats/fs?") for _, path in requests) == blocked, requests
                    if blocked:
                        assert "OpenSearch blocks index creation" in output, output
                        assert "/var/lib/opensearch/nodes/0" in output, output
                        assert "90%" in output, output
                    print(f"PASS: index creation check, {name}, no settings mutation")

                for name, status, late_block, expected_error in (
                    ("ready", 200, False, None),
                    ("block during migration", 503, True, "OpenSearch blocks index creation"),
                    ("other startup failure", 503, False, "fixture migration error"),
                ):
                    cluster_settings = copy.deepcopy(INITIAL_SETTINGS)
                    health_status = status
                    block_on_health_request = late_block
                    requests.clear()
                    result = run_tasks(guard_tasks + readiness)
                    output = result.stdout + result.stderr
                    assert (result.returncode != 0) == (expected_error is not None), output
                    assert all(method == "GET" for method, _ in requests), requests
                    if expected_error:
                        assert expected_error in output, output
                    if status != 200:
                        assert sum(path.startswith("/_cluster/settings?") for _, path in requests) == 2, requests
                    print(f"PASS: Dashboards readiness, {name}")
        finally:
            server.shutdown()
            thread.join(timeout=5)
    return 0


if __name__ == "__main__":
    sys.exit(main())

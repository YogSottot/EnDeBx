#!/usr/bin/env python3
import copy
import hashlib
import http.server
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import time

import yaml


ROOT = Path(__file__).resolve().parents[2]
ROLE = ROOT / 'vm_menu/ansible/playbooks/roles/bx_push_server'
ARCHIVE = ROLE / 'files/push-server-0.4.0.tgz'
PAYLOAD = ARCHIVE.read_bytes()


class ArchiveServer(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path == '/timeout':
            time.sleep(2)
            return
        if self.path == '/error':
            self.send_error(503)
            return
        self.send_response(200)
        self.send_header('Content-Length', str(len(PAYLOAD)))
        self.end_headers()
        self.wfile.write(PAYLOAD)


def main():
    tasks = yaml.safe_load((ROLE / 'tasks/install.yml').read_text())[4:7]
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), ArchiveServer)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with tempfile.TemporaryDirectory(prefix='endebx-push-') as directory:
            base = Path(directory)
            for name, endpoint, installed, upgrade, checksum, expected in [
                ('timeout', 'timeout', False, False, True, True),
                ('http-error', 'error', False, False, True, True),
                ('success', 'ok', False, False, True, True),
                ('force-upgrade', 'ok', True, True, True, True),
                ('installed', 'error', True, False, True, True),
                ('bad-checksum', 'error', False, False, False, False),
                ('missing-archive', 'error', False, False, True, False),
            ]:
                destination = base / name
                selected = copy.deepcopy(tasks)
                selected[0]['ansible.builtin.get_url'].update(dest=str(destination), timeout=1)
                selected[1]['ansible.builtin.copy'].update(src=str(ARCHIVE), dest=str(destination))
                selected[1]['register'] = 'fallback_result'
                selected[2]['ansible.builtin.stat']['path'] = str(destination)
                if name == 'missing-archive':
                    selected = selected[2:]
                fallback = endpoint in ('timeout', 'error') and (not installed or upgrade)
                selected.append({
                    'name': 'Check fallback selection',
                    'ansible.builtin.assert': {'that': [
                        f'(download_result is failed) == {fallback}',
                        f'(fallback_result is skipped) == {not fallback}',
                    ]},
                })
                playbook = base / 'check.yml'
                playbook.write_text(yaml.safe_dump([{
                    'hosts': 'localhost', 'gather_facts': False,
                    'vars': {
                        'bx_push_server_installed': {'stat': {'exists': installed}},
                        'bx_push_server_force_upgrade': upgrade,
                        'bx_push_server_archive_url': f'http://127.0.0.1:{server.server_port}/{endpoint}',
                        'bx_push_server_archive_sha256': hashlib.sha256(PAYLOAD).hexdigest() if checksum else '0' * 64,
                        'bx_push_server_user': str(os.getuid()),
                        'bx_push_server_group': str(os.getgid()),
                    },
                    'tasks': selected,
                }]))
                env = dict(os.environ, ANSIBLE_LOCAL_TEMP=str(base / 'local'),
                           ANSIBLE_REMOTE_TEMP=str(base / 'remote'))
                result = subprocess.run(
                    ['ansible-playbook', '-i', 'localhost,', '-c', 'local', str(playbook)],
                    env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                )
                if (result.returncode == 0) != expected:
                    raise AssertionError(f'{name}:\n{result.stdout}')
                if expected and (not installed or upgrade):
                    assert destination.read_bytes() == PAYLOAD, name
                if installed and not upgrade:
                    assert not destination.exists(), name
                if not expected:
                    assert 'Verify local archive checksum' in result.stdout
                    assert "has no attribute" not in result.stdout
                print(f'{name}: OK')
    finally:
        server.shutdown()
        server.server_close()


if __name__ == '__main__':
    main()

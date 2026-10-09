# Test Scaffolding

Use `make check-push-archive` to test the Push server archive tasks locally:
download timeout, HTTP error, successful download, forced upgrade, an already
installed server, missing archive and invalid checksum. Requires Python 3, PyYAML and
`ansible-playbook`; uses a local HTTP fixture and temporary directories, no VM.

This directory contains a local `OpenTofu + SSH` scaffold for EnDeBx test stands in VMmanager.

Use `make check-update-fzf` to check the updater's fzf guards locally.
It requires Python 3 and Bash, uses temporary files, and checks root/skel/user
bashrc files, a custom home prefix, missing files and repeated execution.

Most test targets automatically call `make upload-repo` first so the remote
host uses the current local repository contents. The full `make e2e` flow does
one upload once and skips repeated rsync calls for subsequent steps.
For Ubuntu stands, the runner also rewrites `/etc/apt/sources.list.d/ubuntu.sources`
to `ru.archive.ubuntu.com` before bootstrap and environment installation.

Cloudflare records created by the scaffold:

- `<vm>.<suffix>.<zone>`
- `*.<vm>.<suffix>.<zone>`

The `menu-sites` runner configures a Let's Encrypt certificate for
`default.<vm>.<suffix>.<zone>` on the default site and then creates:

- `link-default.<vm>.<suffix>.<zone>`
- `full.<vm>.<suffix>.<zone>`
- `link-full.<vm>.<suffix>.<zone>`

Use `make menu-certs` to issue or re-issue certificates for these four
domains on an already prepared stand without recreating the sites.
Use `make menu-php-version` to install the latest available PHP version on the
stand and set it as the global default through menu.sh.
Use `make menu-site-options` to test menu-driven toggles for redirect HTTP to
HTTPS, block/unblock access by IP, Basic Auth in nginx, and Bot Blocker on the
full test site.
Use `make menu-ftp` to create and delete a Pure-FTPd virtual user on the
default site directory through menu.sh.
Use `make menu-smtp` to configure SMTP for the default site through menu.sh
and verify `mail()` delivery under the `bitrix` user by checking a new
`msmtp_default.log` entry.
Use `make menu-ntlm` for a manual two-step NTLM flow. The first run points
`/etc/resolv.conf` to the configured AD DNS server, configures NTLM for the
selected site through menu.sh, and intentionally leaves the resolver on the AD
DNS server for manual browser verification. It also registers an AD DNS `A`
record for `$(hostname -s).<ntlm fqdn>` with the detected LAN IP. Run
`make menu-ntlm` a second time to remove that DNS record, delete NTLM settings,
and restore the original resolver.

Use `make prepare-bitrix` to download and unpack the Enterprise distributive
to the default site, then `make bitrix-install` to run the Bitrix24
installation flow on the already prepared files: stage1 wizard, stage2
Bitrix24 setup wizard, and stage3 enabling `main.x_accel_redirect=Y`.
Use `make menu-transformer` after that in a two-step flow. The first run
installs File Conversion Server (`transformer`) on the default Bitrix site and
leaves it in place for manual verification. Run `make menu-transformer` a
second time to delete it and validate cleanup.
Use `make menu-extensions` to test menu-driven install and delete of
Memcached, Push server, Sphinx, OpenSearch, Netdata, Docker and mydumper.
The Netdata check requires installed chartsd and pythond plugins with the
same package version as Netdata.
The OpenSearch check validates bulk document indexing and updating, search,
and temporary index cleanup using the Bitrix user's credentials. It also
checks individual bulk results, since HTTP 200 can contain document errors,
and validates Bitrix search module options when the default site is installed.
By default, this flow also installs Dashboards, checks the matching package
version, service account, authenticated API and anonymous browser login page
at `/opensearch/app/login` through nginx, then verifies
that deletion removes Dashboards and its nginx configuration. Set
`TEST_MENU_OPENSEARCH_DASHBOARDS=N` in `.env.test` to test installation without
Dashboards. An explicit environment value, for example
`TEST_MENU_OPENSEARCH_DASHBOARDS=N make menu-extensions`, takes precedence over
the file. The resolved value is used for both the menu answer and the
installed-state checks. A failed check reports the feature, expected state,
line and command without enabling password-bearing remote shell traces.
Use `make check-menu-extensions-config` for local regression tests of file
settings, defaults, CLI overrides, lowercase/invalid values and failed-check
diagnostics. This target requires Python 3 and Bash, not SSH or a VM.
Use `make check-opensearch-menu` for local tests of the confirmation order,
Dashboards selection and defaults, cancellation, and deletion without the
Dashboards question. This target does not require a VM.
Use `make check-opensearch-dashboards` to execute the role's REST security
and readiness tasks against a local HTTP fixture with a reserved
`kibana_server` mapping. It checks copied service permissions, preservation
of the built-in role and security configuration, and repeated execution.
It also checks index creation blocks in default, persistent and transient
settings, their precedence, disk usage diagnostics without settings changes,
a block appearing during migration, and journal diagnostics for other `503`
startup failures. Only the fixture's readiness retries are shortened; the
role's timeout is unchanged. It also executes the runner's anonymous login
page probe against the fixture: HTTP 200 succeeds, while HTTP 401 and 503
still fail. The `/auth/login` session API is not treated as a browser page.
This target requires `ansible-playbook`, curl, Bash, Python 3 and PyYAML,
but does not require a VM or installed OpenSearch.
Use `make menu-snapd` to test menu-driven install and delete of Snapd.
Use `make menu-security-settings` to apply and validate `Security settings ->
SSH/Updates`.
Use `make menu-security-tools` to test menu-driven install and delete of
Crowdsec, Rkhunter, Linux Malware Detect and AIDE.
Use `make menu-firewall` to add and delete a test firewalld port rule.
Use `make menu-security` to run the full security menu coverage.
Use `make menu-timezone` to switch the server timezone to an alternate value
through menu.sh and restore the original timezone afterwards.
The runner uses the vendored `tests/vendor/bitrix-cli-install` helper and
leaves step-by-step request and response dumps in
`/root/endebx-bitrix-install-debug/` on failure.

## Files

- `opentofu/` - VMmanager and Cloudflare resources.
- `runner/` - shell scripts for `ssh`, `rsync`, install, smoke checks, Bitrix install and log collection.

## Quick start

1. Copy `tests/opentofu/terraform.tfvars.example` to `tests/opentofu/terraform.tfvars`.
2. Copy `.env.test.example` to `.env.test`.
3. Export `CLOUDFLARE_API_TOKEN` or set `cloudflare_api_token` in `terraform.tfvars`.
4. Run `make e2e DISTRO=debian12`.

The stand is not destroyed automatically. Use `make tofu-destroy` only after manual verification.

Machine-specific files are intentionally local and ignored by git:

- `tests/opentofu/terraform.tfvars`
- `.env.test`

# Test Scaffolding

This directory contains a local `OpenTofu + SSH` scaffold for EnDeBx test stands in VMmanager.

Most test targets automatically call `make upload-repo` first so the remote
host uses the current local repository contents. The full `make e2e` flow does
one upload once and skips repeated rsync calls for subsequent steps.

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
Memcached, Push server, Sphinx, Netdata and Docker.
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

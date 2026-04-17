.PHONY: help tofu-init tofu-plan tofu-apply tofu-output tofu-destroy \
	wait-ssh bootstrap-host upload-repo install-env smoke menu-sites menu-certs \
	menu-php-version menu-site-options menu-ftp menu-smtp prepare-bitrix bitrix-install menu-transformer \
	menu-extensions menu-snapd menu-ntlm menu-security-settings menu-security-tools \
	menu-firewall menu-security menu-timezone collect-logs e2e ensure-upload-repo

TOFU ?= tofu
TOFU_DIR := tests/opentofu
RUNNER_DIR := tests/runner
DISTRO ?= debian12
RUN_ID ?= $(shell date +%Y%m%d-%H%M%S)

help:
	@printf '%s\n' \
	'Targets:' \
	'  tofu-init       - initialize OpenTofu in tests/opentofu' \
	'  tofu-plan       - show plan for DISTRO=$(DISTRO) RUN_ID=$(RUN_ID)' \
	'  tofu-apply      - create VM and DNS record' \
	'  tofu-output     - print current OpenTofu outputs' \
	'  wait-ssh        - wait until root SSH becomes available' \
	'  bootstrap-host  - install minimal remote packages needed by the runner' \
	'  upload-repo     - rsync current repository to the test VM' \
	'  install-env     - render .env.test and run install_full_environment_fpm.sh remotely' \
	'  smoke           - run basic post-install smoke checks' \
	'  menu-php-version - set the latest available PHP version as global default through menu.sh' \
	'  menu-sites      - configure default cert and create link/full/link sites through menu.sh' \
	'  menu-certs      - configure certs for default/link-default/full/link-full on existing sites' \
	'  menu-site-options - toggle redirect/IP block/basic auth/bot blocker through menu.sh' \
	'  menu-ftp        - create and delete an FTP user through menu.sh' \
	'  menu-smtp       - configure SMTP for the default site and verify mail() delivery through msmtp' \
	'  menu-ntlm       - first run configures NTLM and registers AD DNS, second run removes AD DNS and restores resolver' \
	'  prepare-bitrix  - download Bitrix Enterprise files to the default site' \
	'  bitrix-install  - run Bitrix24 Enterprise install plus post-install nginx accel option' \
	'  menu-transformer - first run installs transformer, second run deletes it' \
	'  menu-extensions - install and delete Memcached, Push server, Sphinx, Netdata and Docker through menu.sh' \
	'  menu-snapd      - install and delete Snapd through menu.sh' \
	'  menu-security-settings - apply SSH/Updates security settings through menu.sh and validate them' \
	'  menu-security-tools - install and delete Crowdsec, Rkhunter, Maldet and AIDE through menu.sh' \
	'  menu-firewall   - add and delete a test firewalld port rule through menu.sh' \
	'  menu-security   - run all security menu tests' \
	'  menu-timezone   - change server timezone through menu.sh and restore it' \
	'  collect-logs    - fetch logs and basic diagnostics from the VM' \
	'  tofu-destroy    - destroy current VM and DNS record manually' \
	'  e2e             - full flow without auto-destroy'

tofu-init:
	$(TOFU) -chdir=$(TOFU_DIR) init

tofu-plan:
	$(TOFU) -chdir=$(TOFU_DIR) plan -var="distro=$(DISTRO)" -var="run_id=$(RUN_ID)"

tofu-apply:
	$(TOFU) -chdir=$(TOFU_DIR) apply -var="distro=$(DISTRO)" -var="run_id=$(RUN_ID)"

tofu-output:
	$(TOFU) -chdir=$(TOFU_DIR) output

tofu-destroy:
	$(TOFU) -chdir=$(TOFU_DIR) destroy

wait-ssh:
	$(RUNNER_DIR)/wait_ssh.sh

bootstrap-host:
	$(RUNNER_DIR)/bootstrap_host.sh

upload-repo:
	$(RUNNER_DIR)/upload_repo.sh

ensure-upload-repo:
	@if [ "$(SKIP_UPLOAD_REPO)" != "1" ]; then $(MAKE) upload-repo; fi

install-env:
	$(RUNNER_DIR)/run_install.sh

smoke:
	$(RUNNER_DIR)/run_smoke.sh

menu-php-version:
	$(RUNNER_DIR)/run_menu_php_version.sh

menu-sites:
	$(RUNNER_DIR)/run_menu_create_sites.sh

menu-certs:
	$(RUNNER_DIR)/run_menu_certs.sh

menu-site-options:
	$(RUNNER_DIR)/run_menu_site_options.sh

menu-ftp:
	$(RUNNER_DIR)/run_menu_ftp.sh

menu-smtp:
	$(RUNNER_DIR)/run_menu_smtp.sh

menu-ntlm:
	$(RUNNER_DIR)/run_menu_ntlm.sh

prepare-bitrix:
	$(RUNNER_DIR)/prepare_bitrix_enterprise.sh

bitrix-install:
	$(RUNNER_DIR)/install_bitrix_enterprise.sh

menu-transformer:
	$(RUNNER_DIR)/run_menu_transformer.sh

menu-extensions:
	$(RUNNER_DIR)/run_menu_extensions.sh

menu-snapd:
	$(RUNNER_DIR)/run_menu_snapd.sh

menu-security-settings:
	$(RUNNER_DIR)/run_menu_security_settings.sh

menu-security-tools:
	$(RUNNER_DIR)/run_menu_security_tools.sh

menu-firewall:
	$(RUNNER_DIR)/run_menu_firewall.sh

menu-security:
	$(RUNNER_DIR)/run_menu_security.sh

menu-timezone:
	$(RUNNER_DIR)/run_menu_timezone.sh

collect-logs:
	$(RUNNER_DIR)/collect_logs.sh

install-env smoke menu-php-version menu-sites menu-certs menu-site-options \
menu-ftp menu-smtp menu-ntlm prepare-bitrix bitrix-install menu-transformer menu-extensions \
menu-snapd menu-security-settings menu-security-tools menu-firewall \
menu-security menu-timezone: ensure-upload-repo

e2e:
	$(MAKE) tofu-init DISTRO=$(DISTRO) RUN_ID=$(RUN_ID)
	$(MAKE) tofu-apply DISTRO=$(DISTRO) RUN_ID=$(RUN_ID)
	$(MAKE) wait-ssh
	$(MAKE) bootstrap-host
	$(MAKE) upload-repo
	$(MAKE) install-env SKIP_UPLOAD_REPO=1
	$(MAKE) smoke SKIP_UPLOAD_REPO=1
	$(MAKE) menu-sites SKIP_UPLOAD_REPO=1
	$(MAKE) prepare-bitrix SKIP_UPLOAD_REPO=1
	$(MAKE) bitrix-install SKIP_UPLOAD_REPO=1
	$(MAKE) menu-transformer SKIP_UPLOAD_REPO=1
	$(MAKE) menu-site-options SKIP_UPLOAD_REPO=1
	$(MAKE) menu-ftp SKIP_UPLOAD_REPO=1
	$(MAKE) menu-extensions SKIP_UPLOAD_REPO=1
	$(MAKE) menu-security SKIP_UPLOAD_REPO=1
	$(MAKE) menu-timezone SKIP_UPLOAD_REPO=1
	$(MAKE) menu-smtp SKIP_UPLOAD_REPO=1
	$(MAKE) collect-logs

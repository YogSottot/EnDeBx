Cloudweeb Maldet
=========

[![Build Status](https://travis-ci.com/cloudweeb/cloudweeb.maldet.svg?branch=master)](https://travis-ci.com/cloudweeb/cloudweeb.maldet)

Install and manage Linux Malware Detection.

Requirements
------------

None

Role Variables
--------------

```YAML
# Maldet version that wants to be installed
maldet_version: '1.6.3'

# Enable maldet monitoring service
# maldet_default_monitor_mode required to be set
maldet_service_enabled: false

# Maldet General Options
# ----------------------

# Enable or disable e-mail alerts
# [0 = disabled, 1 = enabled]
maldet_email_alert: false

# The destination e-mail addresses for automated/manual scan reports
maldet_email_addr:
  - root@{{ ansible_fqdn }}

# Maldet Scan Options
# -------------------

# The maximum directory depth that the scanner will search.
maldet_scan_max_depth: '15'

# The minimum file size in bytes for a file to be included in LMD scans.
maldet_scan_min_filesize: '24'

# The maximum file size for a file to be included in LMD scans.
maldet_scan_max_filesize: '2048k'

# Use ClamAV clamscan binary as default scan engine.
maldet_scan_clamscan: false

# Process CPU scheduling (nice) priority level for scan operations.
maldet_scan_cpunice: '19'

# Process IO scheduling (ionice) priority levels for scan operations.
maldet_scan_ionice: '6'

# Maldet Quarantine Options
# -------------------------

# The default quarantine action for malware hits
maldet_quarantine_hits: false

# Try to clean string based malware injections
# maldet_quarantine_hits must be set true
maldet_quarantine_clean: false

# The default suspend action for users wih hits
# Cpanel suspend or set shell /bin/false on non-Cpanel
# maldet_quarantine_hits must be set true
maldet_quarantine_suspend_user: false

# The minimum userid value that can be suspended
maldet_quarantine_suspend_user_minuid: 500

# Maldet Monitoring Options
# -------------------------

# The default startup option for monitor mode, either 'users' or path to line
# spaced file containing local paths to monitor.
maldet_default_monitor_mode: ''

# When this option is set, users will only have the docroot monitored
maldet_inotify_docroot:
  - public_html
  - public_ftp

# Process CPU scheduling (nice) priority level for scan operations.
maldet_inotify_cpunice: '18'

# Process IO scheduling (ionice) priority levels for scan operations.
inotify_ionice: '6'
```

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: servers

      vars:
        maldet_default_monitor_mode: users
        maldet_service_enabled: true

      roles:
         - role: cloudweeb.maldet

License
-------

MIT

Author Information
------------------

Agnesius Santo Naibaho

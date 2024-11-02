pgbouncer ansible role
=========

This is not independent role but pgbouncer is used not only postgres hosts. It is used on same hosts with haproxy or isolated host(s).

Copyright (C) 2023  Mikhail Shurutov

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

Requirements
------------

This role requires python v3 because python v2 is out of live.

Role Variables
--------------

### Files and directories
`pgbouncer_files_dir` is directory for files;
`pgbouncer_templates_dir` is directory for templates;
`pgbouncer_vars_dir` is directory for defining variables;
`pgbouncer_config_dir` is config directory;
`pgbouncer_config_file` is config file;
`pgbouncer_user_file` is auth file;

### Parameters
The configuration file uses the `pgbouncer_params` variable. It is built from `pgbouncer_params_default`, which is defined by default, `pgbouncer_params_group_all`, `pgbouncer_params_group`, which will be defined for all pgbouncers and for a separate group, respectively, `pgbouncer_params_host`, which is defined for each specific host.
By default, only two parameters are defined: `pool_mode` and `auth_file`.
They are defined in the `pgbouncer_params_default` variable.
```
pgbouncer_params_default:
  - name: "pool_mode"
    value: "transaction"
  - name: "auth_file"
    value: "{{ pgbouncer_user_file }}"
```

Dependencies
------------

This role is used with mshurutov.postgres role.

Using a Role
----------------

### Variables Used

* `ANSIBLE_ROOT_DIR` is path for static content: roles,configs,etc, for example: /data/ansible
* `ANSIBLE_ROOT_ROLE_DIR` is path in `roles_path` config variable, for example: /data/ansible/roles  
Content of my ~/.ansible.cfg:
```
...
# additional paths to search for roles in, colon separated
#roles_path    = /etc/ansible/roles
roles_path    = /data/ansible/roles
...
```

### Install role
#### GIT repo

    user@host ~ $ cd $ANSIBLE_ROOT_ROLE_DIR
    user@host roles $ git clone https://git.code.sf.net/p/pgbouncer/code pgbouncer

#### Ansible galaxy
##### Installation from command

    user@host ~ $ cd $ANSIBLE_ROOT_DIR
    user@host ansible $ ansible-galaxy role install mshurutov.pgbouncer -p roles

##### Installation from requirements.yml

    user@host ~ $ cd $ANSIBLE_ROOT_DIR
    user@host ansible $ grep pgbouncer requirements.yml
    - name: mshurutov.pgbouncer
    user@host ansible $ ansible-galaxy role install -r requirements.yml -p roles

### Example Playbook

#### Role installed from git repo

    ...
    - hosts: pgbouncer_group
      roles:
         - role: pgbouncer
    ...

#### Role installed from ansible galaxy

    ...
    - hosts: pgbouncer_group
      roles:
         - role: mshurutov.pgbouncer
    ...

### Deploying pgbouncer using this role

This example uses playbook.yml to deploy pgbouncer. Inventory file is defined in ansible configuration.

#### Tags

* `pgbouncer` is used for full deploy;
* `pgbouncer_install` is used for install pgbouncer;
* `pgbouncer_config` is used for configuration pgbouncer.

#### Full deploy

```
user@host ~ $ ansible-playbook playbook.yml -t pgbouncer [-l pgbouncer_group]
```

#### install pgbouncer 

```
user@host ~ $ ansible-playbook playbook.yml -t pgbouncer_install [-l pgbouncer_group]
```

#### configure pgbouncer

```
user@host ~ $ ansible-playbook playbook.yml -t pgbouncer_config [-l pgbouncer_group]
```

License
-------

[GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt)

Author Information
------------------

My name is Mikhail Shurutov, I'm an operations engineer since 1997.

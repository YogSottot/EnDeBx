# Файл `.env.menu`

`/root/.env.menu` - это основной способ подстроить окружение под ваш сервер без прямого редактирования `config.sh`.

## Откуда брать шаблон

Шаблон лежит в репозитории:

```text
.env.menu.example
```

Его обычно копируют в `/root/.env.menu`, после чего меняют только нужные значения.

## Как работает переопределение

Порядок такой:

1. загружается `vm_menu/bash_scripts/config.sh`;
2. если существует `/root/.env.menu`, его значения переопределяют дефолты.

Это значит, что править `config.sh` на сервере обычно не нужно.

## Самые важные группы переменных

### Пути и пользователи

- `BS_PATH_USER_HOME_PREFIX` - корневой путь для пользовательских каталогов, обычно `/var/www`;
- `BS_PATH_USER_HOME` - пользователь по умолчанию для основного сайта;
- `BS_DEFAULT_SITE_NAME` - имя основного сайта;
- `BS_SITE_LINKS_RESOURCES` - какие каталоги симлинковать у сайтов режима `link`.

### PHP и веб-стек

- `BX_PHP_DEFAULT_VERSION` - PHP по умолчанию;
- `BS_HTACCESS_SUPPORT` - нужен ли Apache для `.htaccess`;
- `BX_ADDITIONAL_PHP_EXTENSIONS` - дополнительные PHP-расширения.

### MySQL и PostgreSQL

- `BS_INSTALL_DATABASE` - какая БД ставится при первичной установке: `mysql` или `pgsql`;
- `BS_DB_FLAVOR`, `BS_DB_VERSION` - flavor и версия MySQL;
- `BS_DB_CHARACTER_SET_SERVER`, `BS_DB_COLLATION` - кодировка и collation;
- `BS_POSTGRESQL_REPOSITORY_SOURCE`, `BS_POSTGRESQL_VERSION` - источник и версия PostgreSQL;
- `BS_INSTALL_PGBOUNCER` - ставить ли `pgbouncer` сразу.

### Уведомления и внешние сервисы

- `BS_EMAIL_ADMIN_FOR_NOTIFY` - адрес для Let's Encrypt и security-инструментов;
- `BS_INSTALL_PUSH_SERVER`, `BS_PUSH_SERVER_BX_SETTINGS` - локальный push-сервер;
- `BS_INSTALL_CROWDSEC`, `BS_INSTALL_CROWDSEC_APPSEC`, `BS_CROWDSEC_*` - установка CrowdSec, его базовой AppSec-конфигурации и сопутствующих параметров.
- `BS_SETUP_MALDET`, `BS_SETUP_MALDET_MONITORING_SERVICE` - установка `Maldet` и включение его постоянного мониторинга при первичной установке.

### Безопасность и SSH

- `BS_SETUP_SECURITY` - применять ли security-блок при первичной установке;
- `BS_SSH_PORT`, `BS_SSH_PERMIT_ROOT_LOGIN`, `BS_SSH_PASSWORD_AUTHENTICATION`;
- `BS_SSH_ADMIN_USER`, `BS_SSH_ADMIN_USER_PASSWORDLESS_SUDO`;
- `BS_AUTOUPDATE_ENABLED`, `BS_AUTOUPDATE_REBOOT_ENABLE`, `BS_AUTOUPDATE_REBOOT_TIME`;
- `BS_SECRITY_HIDEPID`, `BS_SECRITY_HIDEPID_MONITORING_USER`.

## На что обратить внимание

!!! note "Значения по умолчанию могут отличаться"
    Значения в репозитории, в `.env.menu.example` и на уже установленном сервере могут быть разными. Всегда ориентируйтесь на фактический `/root/.env.menu` вашей машины.

## Минимальный набор перед первичной установкой

Чаще всего достаточно проверить и осознанно выставить:

- тип БД и ее версию;
- PHP по умолчанию;
- `BS_HTACCESS_SUPPORT`;
- email администратора;
- поведение SSH и security-обновлений;
- установку `push-server`, `CrowdSec`, `swap`.

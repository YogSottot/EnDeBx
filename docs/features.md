# Возможности EnDeBx

## Поддерживаемые ОС { #supported-os }

- Debian 12
- Debian 13
- Ubuntu 24.04
- Astra Linux 1.8 (с подключением репозиториев из Debian)

## Базовое окружение

- Полная установка окружения на Debian-like дистрибутивах с разворачиванием меню, зависимостей и базовых сервисов: [Установка окружения](getting-started/installation.md).
- Стек `php-fpm` + `mpm_event` вместо классической схемы `libphp` + `mod_prefork`.
- Раздельные системные пользователи для `full`-сайтов.
- Автоматический перевод Bitrix agents на `CRON` для полноценных сайтов.
- Поддержка `Brotli`, `nginx-composite from files` и дополнительных include-конфигов для Nginx.
- Обновление самого меню через `update_menu` и показ уведомления о новой версии: [Обновление меню](getting-started/update-menu.md).

## Сайты и веб-уровень

- [List of sites dirs](menu/1-list-sites.md) - быстрый обзор каталогов сайтов.
- [Add site](menu/2-site-management/add-site.md) - создание `full` и `link`-сайтов, выбор PHP, `xdebug`, `.htaccess`, Let's Encrypt-сертификата, редиректа HTTP -> HTTPS, а также выбор MySQL или PostgreSQL для нового проекта.
- [Edit existing website](menu/2-site-management/edit-site.md) - смена PHP, `xdebug`, `.htaccess`, `nginx-composite from files`, повторная настройка Let's Encrypt и редиректа.
- [Delete site](menu/2-site-management/delete-site.md) - удаление `full` и `link`-сайтов.
- [Configure Let's Encrypt certificate](menu/2-site-management/lets-encrypt.md) - выпуск или перевыпуск сертификата отдельно от сценария создания сайта.
- [Enable/Disable redirect HTTP to HTTPS](menu/2-site-management/http-to-https.md) - отдельное управление редиректом.
- [Block/Unblock access by IP](menu/2-site-management/ip-blocking.md) - закрытие прямого доступа к серверу по IP.
- [Enable/Disable Basic Auth in nginx](menu/2-site-management/basic-auth.md) - базовая авторизация на уровне фронта.
- [Enable/Disable Bot Blocker in nginx](menu/2-site-management/bot-blocker.md) - per-site интеграция с `nginx-ultimate-bad-bot-blocker`.
- [Configure NTLM auth for sites](menu/2-site-management/ntlm.md) - настройка NTLM через Apache, Samba/winbind и Bitrix LDAP-модуль.

## Доступы, PHP, SMTP и runtime

- [Add/Remove FTP user](menu/3-ftp.md) - создание и удаление FTP-пользователей через `pure-ftpd`.
- [Add/Change global PHP version](menu/4-php.md) - установка новой глобальной ветки PHP и смена default-версии.
- Per-site переключение PHP и `xdebug` доступно прямо в сценариях создания и редактирования сайта.
- [Settings SMTP sites](menu/5-smtp.md) - настройка `msmtp` для default-аккаунта или для конкретного сайта.
- [Change server timezone](menu/10-timezone.md) - смена системной таймзоны.

## Базы данных

- [MySQL](menu/6-mysql.md) - установка `MariaDB` или `Percona`, регенерация конфига, upgrade `Percona 5.7 -> 8.0 -> 8.4`, удаление сервера БД.
- [PostgreSQL](menu/7-postgresql.md) - установка, удаление и major-upgrade PostgreSQL, создание и удаление пользователей и БД, а также установка `pgbouncer`.
- При создании `full`-сайта меню умеет использовать MySQL или PostgreSQL, если на сервере доступны обе БД.

## Дополнительные сервисы и расширения

- [Memcached](menu/8-extensions/services.md) - install/delete.
- [Push server](menu/8-extensions/services.md) - install/delete, при удалении можно отдельно решить судьбу `Redis`.
- [Sphinx](menu/8-extensions/services.md) - install/delete полнотекстового поиска.
- [File Conversion Server](menu/8-extensions/services.md) - install/delete локального transformer-сервера для Bitrix.
- [Netdata](menu/8-extensions/services.md) - install/delete мониторинга с генерацией учетных данных.
- [Docker](menu/8-extensions/services.md) - install/delete Docker и добавление default-пользователя сайтов в группу Docker.
- [Snapd](menu/8-extensions/system-tools.md) - install/delete.
- [Deadsnakes PPA](menu/8-extensions/system-tools.md) - install/delete только на Ubuntu.
- [Debian repo on Astra Linux](menu/8-extensions/system-tools.md) - подключение стандартного Debian-репозитория только на Astra Linux.

## Безопасность

- [SSH/Updates](menu/9-security/ssh-updates.md) - изменение SSH-порта, `PermitRootLogin`, sudo-пользователя, `PasswordAuthentication`, unattended security updates, autoreboot и `hidepid` для `/proc`.
- [Firewall management](menu/9-security/firewall-management.md) - просмотр активных правил `firewalld`, управление портами, сервисами и blocklist по IP/CIDR.
- [CrowdSec](menu/9-security/security-tools.md) - install/delete с whitelist и cloud-console enroll key.
- [Rkhunter](menu/9-security/security-tools.md) - install/delete host-based аудита руткитов.
- [Linux Malware Detect](menu/9-security/security-tools.md) - install/delete проверки пользовательских каталогов на вредоносный код с автоматической установкой `YARA-X CLI` и weekly update.
- Отдельные защитные переключатели на уровне сайтов тоже входят в проект: IP blocking, Basic Auth, Bot Blocker.

## Системное обслуживание

- [Update server](menu/11-update-server.md) - запуск `apt update` и `apt upgrade`.
- [R - перезагрузка сервера](menu/rp-power.md) - явный reboot из главного меню.
- [Upgrade дистрибутивов](upgrades/index.md) - практические руководства для major-upgrade ОС.
- [Changelog](changelog.md) - журнал версий и новых возможностей.

# Debian 12 -> 13

Ниже приведен практический сценарий обновления сервера с Debian 12 до Debian 13 поверх установленного окружения EnDeBx.

!!! warning "Перед началом"
    Если у вас используется Percona MySQL, для Debian 13 доступна только ветка `8.4`. Перейдите с `8.0` на `8.4` до upgrade ОС.

## Подготовка

- сначала проверьте upgrade на тестовой копии;
- используйте терминальный мультиплексор на случай потери ssh-соединения (screen/tmux/byobu/zellij);
- обновите меню;
- обновите пакеты текущего релиза.

```bash
apt update && apt -y upgrade && apt -y autoremove
apt install apt-forktracer apt-listchanges
```

## Переключение репозиториев

```bash
find /etc/apt/sources.list* -type f -print0 | xargs -0 sed -i 's/bookworm/trixie/g'
```

Если у вас подключены дополнительные внешние репозитории, заранее убедитесь, что у них есть пакеты под новый релиз.

## Первый этап обновления

```bash
apt update && apt -y upgrade --without-new-pkgs
```

Во время процесса полезно читать changelog и вопросы maintainer scripts, а не подтверждать их автоматически.

## Правка Nginx-конфигов под новый синтаксис HTTP/2

```bash
find /etc/nginx/bx/site_avaliable/ -type f -print0 |
xargs -0 perl -0777 -i -pe '
  s/^\s*http2 on;\s*\n//mg;
  s/(\blisten[^\n]*443[^\n]*ssl[^\n]*)\s+http2\b/\1/mg;
  s/((?:^[^\n]*listen[^\n]*443[^\n]*ssl[^\n]*\n)+)(?!.*^[^\n]*listen[^\n]*443[^\n]*ssl\b)/$1    http2 on;\n/ms;
'
```

## Второй этап обновления

```bash
apt full-upgrade -y && apt autoremove -y && apt clean
```

Перезагружаем сервер

```bash
reboot
```

После перезагрузки:

```bash
apt list '~o'
apt purge '~o'
```

## Дополнительные действия после upgrade

### Обновить источники в deb822

Опционально:

```bash
apt modernize-sources
```

### Поставить `eza` для стандартных alias

```bash
apt install -y eza
```

### Почистить устаревшие MySQL-параметры

Вместо этого можно [перегенерировать конфиг](../menu/6-mysql.md#re-generate-mysql-config) через меню

```bash
sed -i '/innodb_file_per_table/d' /etc/mysql/mariadb.conf.d/x_server.cnf
sed -i '/innodb_flush_method/d' /etc/mysql/mariadb.conf.d/x_server.cnf
```

### При необходимости сменить collation

```bash
sed -i 's/utf8mb4_unicode_ci/utf8mb4_0900_ai_ci/g' /etc/mysql/mariadb.conf.d/x_server.cnf
sed -i 's/utf8mb4_unicode_ci/utf8mb4_0900_ai_ci/g' /root/.env.menu
```

После правок:

```bash
systemctl restart mysql
```

### При необходимости сконвертировать БД после смены collation

Если вы меняли `collation`, можно дополнительно сконвертировать базы через скрипт `busconvert`. Делать это нужно отдельно для каждого ядра.

Инструкция:

- [Busconvert для utf8mb4](busconvert.md)
- [Скачать `busconvert_11.php`](https://github.com/YogSottot/EnDeBx/raw/refs/heads/main/repositories/bitrix-gt/busconvert_11.php)

Не забудьте скорректировать в самом скрипте требуемые значения:

```php
$charset = 'utf8mb4';
$collate = 'utf8mb4_unicode_ci';
```

### Переустановить Ansible под новый Python

```bash
export BS_ANSIBLE_REQUIRED_VERSION=$(grep '^BS_ANSIBLE_REQUIRED_VERSION=' /root/vm_menu/bash_scripts/config.sh | awk -F'"' '{print $2}')
pipx reinstall-all
```

Если `pipx reinstall-all` не сработал, можно установить `ansible` заново вручную:

```bash
rm -f ~/.local/bin/ansible* && rm -rf ~/.local/pipx/
pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
pipx inject ansible jmespath passlib python-debian
```

### Отключить новое tmpfs-поведение для `/tmp`

```bash
systemctl mask tmp.mount
```

## После завершения

После upgrade проверьте:

- запуск сайтов;
- работу PHP-FPM;
- MySQL/PostgreSQL;
- выпуск SSL и редиректы;
- запуск меню и `ansible-playbook`.

## Полезные ссылки

- [Debian release notes](https://www.debian.org/releases/trixie/release-notes/upgrading.en.html)
- [Справка по сопутствующему сценарию](../menu/6-mysql.md)

# Ubuntu 24.04 -> 26.04

Ниже приведен практический сценарий обновления сервера с Ubuntu 24.04 до Ubuntu 26.04 поверх установленного окружения EnDeBx.

!!! warning "Перед началом"
    Рекомендуется дождаться выхода 26.04.1

!!! warning "PHP missing"
    [PPA for PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php) пока что не имеет пакетов для resolute

!!! warning "Percona MySQL"
    Если у вас используется Percona MySQL, для Ubuntu 26.04 пока что нет пакетов в репозитории

## Подготовка

- изучите [Ubuntu 26.04 LTS summary](https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/)
- изучите [инструкцию по обновлению](https://documentation.ubuntu.com/desktop/en/latest/how-to/upgrade-ubuntu-desktop/)
- сначала проверьте upgrade на тестовой копии;
- используйте терминальный мультиплексор на случай потери ssh-соединения (screen/tmux/byobu/zellij);
- обновите меню;
- обновите пакеты текущего релиза.
- если у вас подключены дополнительные внешние репозитории, заранее убедитесь, что у них есть пакеты под новый релиз.

```bash
apt update && apt -y upgrade && apt -y autoremove
apt install apt-forktracer apt-listchanges
```

- если у вас установлен rabbitmq, то следуйте [инструкции по ссылке](https://discourse.ubuntu.com/t/ubuntu-server-gazette-issue-12-upgrading-rabbitmq-across-ubuntu-releases/77271#p-199978-h-2404-lts-noble-to-2604-lts-resolute-6) или просто удалите `File Conversion Server (transformer)` через меню, после обновления его можно установить обратно

## Первый этап обновления

  ```bash
  do-release-upgrade -d
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

Перезагружаем сервер

```bash
reboot
```

## Дополнительные действия после upgrade

### Переключение сторонних репозиториев

```bash
find /etc/apt/sources.list* -type f -print0 | xargs -0 sed -i 's/noble/resolute/g'
```

### Включаем обратно sury ppa

```bash
mv /etc/apt/sources.list.d/ppa_launchpad_net_ondrej_php_ubuntu.list.disabled /etc/apt/sources.list.d/ppa_launchpad_net_ondrej_php_ubuntu.list
```

### Включаем остальные репозитории:

```bash
find /etc/apt/sources.list* -type f -print0 | xargs -0 sed -i 's/Enabled\:\ no/Enabled\:\ yes/g'
```

### Установка удалённого при обновлении

```bash
apt install -y libnginx-mod-http-zip
```

### Чистим остатки

Пока не обновился ppa php этот шаг можно пропустить

```bash
apt list '~o'
apt purge '~o'
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

### Почистить устаревшие MySQL-параметры

Просто [перегенерируйте конфиг](../menu/6-mysql.md#re-generate-mysql-config) через меню

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

## После завершения

После upgrade проверьте:

- запуск сайтов;
- работу PHP-FPM;
- MySQL/PostgreSQL;
- выпуск SSL и редиректы;
- запуск меню и `ansible-playbook`.

## Полезные ссылки

- [Ubuntu release notes](https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/)

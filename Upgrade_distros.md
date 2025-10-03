# Обновление мажорной версии дистрибутивов

## Debian 12 до Debian 13

### ВНИМАНИЕ: Если у вас используется Percona MySQL, то пока не обновляйтесь. Пакеты для debian 13 пока что не добавлены в репозиторий percona

https://gist.github.com/yorickdowne/3cecc7b424ce241b173510e36754af47
https://www.debian.org/releases/trixie/release-notes/upgrading.en.html

- Рекомендую сначала проверить на тестовой копии вашего сервера
- Используйте терминальный мультиплексор на случай потери ssh-соединения (screen/tmux/byobu)
- Обновляем меню
- Обновляем пакеты: `apt update && apt -y upgrade && apt -y autoremove && apt install apt-forktracer apt-listchanges`
- Меняем репозитории на новый релиз: `find /etc/apt/sources.list* -type f -print0 | xargs -0 sed -i 's/bookworm/trixie/g'`
- Если у вас подключены репозитории помимо тех, что подключаются в меню, убедитесь, что они предоставляют пакеты для нового релиза
- Первый шаг обновления: `apt update && apt -y upgrade --without-new-pkgs`. Читаем changelogs и нажимаем `q`
- Обновляем конфиг nginx под новую версию

  ```bash
    find /etc/nginx/bx/site_avaliable/ -type f -print0 |
    xargs -0 perl -0777 -i -pe '
      s/^\s*http2 on;\s*\n//mg;                                 # remove any standalone "http2 on;"
      s/(\blisten[^\n]*443[^\n]*ssl[^\n]*)\s+http2\b/\1/mg;     # strip "http2" from listen lines (v4+v6)
      s/((?:^[^\n]*listen[^\n]*443[^\n]*ssl[^\n]*\n)+)(?!.*^[^\n]*listen[^\n]*443[^\n]*ssl\b)/$1    http2 on;\n/ms;  # add one after the last 443 ssl listen block
    '
  ```

  - Опционально: для надёжности можно остановить бд. Второй шаг обновления: `apt full-upgrade -y && apt autoremove -y && apt clean`
  - Перезагружаем сервер `reboot`
  - Удаляем остатки: `apt list '~o' && apt purge '~o'`. Смотрим список и подтверждаем
  - Опционально: меняем репозитории в формат deb822 `apt modernize-sources`
  - Устанавливаем зависимость для стандартных .bash_aliases `apt install -y eza`
  - Удаляем [устаревшие параметры](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_flush_method) из конфига mysql.

    ```bash
    sed -i '/innodb_file_per_table/d' /etc/mysql/mariadb.conf.d/x_server.cnf
    sed -i '/innodb_flush_method/d' /etc/mysql/mariadb.conf.d/x_server.cnf
    ```

  - Опционально: меняем collation на рекомендуемый битриксом. Если у вас был другой, например `utf8mb4_general_ci`, то используйте его в `sed`.

    ```bash
    sed -i 's/utf8mb4_unicode_ci/utf8mb4_0900_ai_ci/g' /etc/mysql/mariadb.conf.d/x_server.cnf
    sed -i 's/utf8mb4_unicode_ci/utf8mb4_0900_ai_ci/g' /root/.env.menu
    ```

  - После изменений в конфигах, перезапускаем mysql `systemctl restart mysql`
  - Если меняли collation, то можно сконвертировать бд [через скрипт по инструкции](repositories/bitrix-gt/busconvert.md) Не забываем изменить в скрипте этот блок на требуемый. Конвертируется каждое ядро отдельно

  ```php
    $charset = 'utf8mb4';
    $collate = 'utf8mb4_unicode_ci';
  ```

  - Переустанавливаем ansible под новую версию python `pipx reinstall-all`. Если возникают ошибки, то удаляем вручную `rm -f ~/.local/bin/ansible && rm -rf ~/.local/pipx/` и устанавливаем

  ```bash
     export BS_ANSIBLE_REQUIRED_VERSION=$(grep '^BS_ANSIBLE_REQUIRED_VERSION='/root/vm_menu/bash_scripts/config.sh | awk -F'"' '{print $2}')
     pipx install --include-deps "ansible==$BS_ANSIBLE_REQUIRED_VERSION"
     pipx inject ansible jmespath passlib
  ```

  - Отключаем [новое поведение](https://www.debian.org/releases/trixie/release-notes/issues.en.html#the-temporary-files-directory-tmp-is-now-stored-in-a-tmpfs) для tmp

  ```bash
  systemctl mask tmp.mount
  ```

  - Обновление завершено. Проверяйте работу сайтов

# Установка окружения

Первичная установка выполняется скриптом `install_full_environment_fpm.sh`. Он рассчитан на запуск **от `root`** на чистой системе.

## Что подготовить заранее

- чистую [поддерживаемую ОС](../features.md#supported-os);
- доступ в интернет;
- пользователя `root` или полноценный root-shell;
- заполненный `/root/.env.menu`.

!!! warning "Важно"
    Скрипт установки меняет пакеты, репозитории, таймзону, службы и конфигурацию веб-стека. На уже рабочей машине это делать рискованно.

## Базовый сценарий установки

```bash
apt install wget -y
wget https://raw.githubusercontent.com/YogSottot/EnDeBx/main/.env.menu.example -O /root/.env.menu
nano /root/.env.menu
bash <(wget -qO- https://raw.githubusercontent.com/YogSottot/EnDeBx/main/install_full_environment_fpm.sh)
```

## Что делает скрипт

Во время установки скрипт:

- обновляет пакеты системы;
- ставит `pipx`, `git`, `python3-debian`, `locales-all`;
- клонирует только каталог `vm_menu` из ветки `main`;
- размещает меню в `/root/vm_menu` и создает ссылку `/root/menu.sh`;
- ставит или переустанавливает `ansible` нужной версии через `pipx`;
- применяет таймзону, опционально swap, системные репозитории и security-настройки;
- устанавливает и настраивает окружение в соответствии с `/root/.env.menu`.

## Важные ограничения по БД

Во время первичной установки скрипт валидирует некоторые сочетания ОС и MySQL-веток:

- на Debian 13 `Percona 5.7` и `Percona 8.0` недоступны;
- на Ubuntu 24.04+ `Percona 5.7` недоступна;
- для PostgreSQL можно выбрать `distro`-репозиторий или `official`.

Если выбрана PostgreSQL-установка, итоговая версия может определяться автоматически из репозитория дистрибутива.

## Что настроить в `.env.menu` в первую очередь

Обычно до первого запуска имеет смысл проверить:

- `BS_INSTALL_DATABASE` и связанные переменные MySQL/PostgreSQL;
- `BX_PHP_DEFAULT_VERSION`;
- `BS_HTACCESS_SUPPORT`;
- `BS_EMAIL_ADMIN_FOR_NOTIFY`;
- `BS_INSTALL_PUSH_SERVER`, `BS_INSTALL_CROWDSEC`, `BS_SETUP_SECURITY`;
- `BS_SSH_*`, если вы хотите сразу ужесточить SSH-политику.

Подробный разбор переменных есть в разделе [Файл .env.menu](../configuration/env-file.md).

## После установки

После успешного завершения доступны стандартные точки входа:

- `/root/menu.sh`;
- `/root/vm_menu/menu.sh`.

Если `BS_ADD_MENU_IN_BASH_PROFILE=Y`, меню будет запускаться автоматически при SSH-входе в root-shell.

## Если установка прервалась

Скрипт обычно можно запустить повторно после исправления причины ошибки. Перед повторным запуском полезно проверить:

- корректность `/root/.env.menu`;
- доступность репозиториев и DNS;
- состояние `ansible` в `pipx`.

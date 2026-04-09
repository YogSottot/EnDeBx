# `CrowdSec`, `Rkhunter`, `Linux Malware Detect`

![security](../../images/menu_security.jpg)

Оставшиеся пункты подменю безопасности работают как переключатели install/delete.

## `Install/Delete Crowdsec`

Установка [crowdsec](https://github.com/crowdsecurity/crowdsec). Это бесплатный open source-инструмент для выявления и блокировки вредоносных IP-адресов на основе шаблонов их поведения. Аналог fail2ban на языке Go.

Значения берутся из `.env.menu`

Меню передает в playbook:

- whitelist IP;
- whitelist CIDR;
- список коллекций;
- список сценариев;
- enroll key для cloud console, если он задан — ключ для подключения к [облачной консоли](https://app.crowdsec.net);
- ответ на отдельный вопрос про AppSec; default для него берется из `BS_INSTALL_CROWDSEC_APPSEC`.

После установки выводится подсказка про web-console и restart `crowdsec`, если используется enroll key.

Если `BS_INSTALL_CROWDSEC_APPSEC=Y`, дополнительно выполняется базовая AppSec-настройка:

- ставятся пакеты `crowdsec-nginx-bouncer` и `lua-cjson`;
- создается `/etc/crowdsec/acquis.d/appsec.yaml`;
- создается `/etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf.local` с `APPSEC_URL=http://127.0.0.1:7422`;
- создается symlink `/etc/nginx/bx/maps/crowdsec_nginx.conf` -> `/etc/nginx/conf.d/crowdsec_nginx.conf`;
- роль перезапускает `crowdsec` и делает `reload nginx`.

В меню и при первичной установке включается только базовая AppSec-конфигурация. Для более тонкой настройки правил и режимов работы ориентируйтесь на официальную документацию: [CrowdSec AppSec quickstart](https://docs.crowdsec.net/docs/appsec/quickstart/general_setup).

## `Install/Delete Rkhunter`

Установка [rkhunter](https://rkhunter.sourceforge.net/)

Playbook получает:

- email для уведомлений — используется значение переменной `BS_EMAIL_ADMIN_FOR_NOTIFY`;
- текущее значение `PermitRootLogin`.

После установки основной локальный конфиг лежит в:

```text
/etc/rkhunter.conf.local
```

## `Install/Delete Linux Malware Detect`

Установка [maldet](https://github.com/rfxn/linux-malware-detect).

Playbook получает:

- email для уведомлений — используется значение переменной `BS_EMAIL_ADMIN_FOR_NOTIFY`;
- корневой путь пользовательских каталогов.
- при установке из меню можно отдельно включить постоянный inotify мониторинг; default для вопроса берется из `BS_SETUP_MALDET_MONITORING_SERVICE`;
- при `Y` playbook получает `maldet_default_monitor_mode=/usr/local/maldetect/monitor_paths` и `maldet_service_enabled=true`;
- та же переменная `BS_SETUP_MALDET_MONITORING_SERVICE` используется и при первичной установке, если `BS_SETUP_MALDET=Y`.

Во время установки вместе с `Maldet` автоматически устанавливается актуальный `YARA-X CLI` из релизов `VirusTotal/yara-x`:

- бинарник `yr` кладется в `/usr/local/bin/yr`;
- weekly updater ставится в `/etc/cron.weekly/update-yara-x`;
- текущую версию можно проверить командой `yr --version`.
- посмотреть логи в `/usr/local/maldetect/logs/`

Во время установки также заполняются списки исключений:

- `/usr/local/maldetect/ignore_paths`;
- `/usr/local/maldetect/ignore_file_ext`;
- `/usr/local/maldetect/ignore_inotify`.

После установки основной конфиг находится в:

```text
/usr/local/maldetect/conf.maldet
```

## Когда имеет смысл включать эти инструменты

- `CrowdSec` - если нужен сетевой поведенческий бан и обработка логов;
- `Rkhunter` - если нужен host-based аудит руткитов;
- `Maldet` - если вы хотите регулярную проверку пользовательских каталогов на вредоносный код и `YARA-X CLI` для дополнительных сигнатурных проверок.

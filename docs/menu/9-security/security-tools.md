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
- enroll key для cloud console, если он задан — ключ для подключения к [облачной консоли](https://app.crowdsec.net)

После установки выводится подсказка про web-console и restart `crowdsec`, если используется enroll key.

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

После установки основной конфиг находится в:

```text
/usr/local/maldetect/conf.maldet
```

## Когда имеет смысл включать эти инструменты

- `CrowdSec` - если нужен сетевой поведенческий бан и обработка логов;
- `Rkhunter` - если нужен host-based аудит руткитов;
- `Maldet` - если вы хотите регулярную проверку пользовательских каталогов на вредоносный код.

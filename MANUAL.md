# Описание пунктов меню

Список доступных для настройками переменных можно посмотреть в файлах `vm_menu/bash_scripts/config.sh` и `.env.menu.example`  
Скопируйте `.env.menu.example` в `/root/.env.menu` и измените настройки согласно своим требованиям.

1) `List of sites dirs`
   Вывести список сайтов. Сайты разбиты по пользователям.  

2) `Add/Change site`
   Вход в отдельное меню для управления сайтами.  

   `1) Add site` — Добавить сайт  
      - `Enter site domain (example: example.com):` Введите домен создаваемого сайта
      - `Enter site mode link or full:` Введите тип сайта.  
        `full` — сайт на новом ядре.  
        `link` — сайт симлинк на full сайт.  
        Список директорий для которых создаются симлинки можно настроить в переменной `$BS_SITE_LINKS_RESOURCES`  
      Для сайта link:
      - `Enter path to links site (default: /var/www/bitrix/default):` — указать пусть к сайту full. По умолчанию подставляется сайт default.  
      - `Do you want to use xdebug? (Y/N) [N]:` — использовать ли php-fpm с подключённым xdebug для сайта.  
        `systemctl status php8.3-fpm-xdebug.service` — это xdebug версия  
        `systemctl status php8.3-fpm.service` — это обычная версия  
      - `Do you want htaccess support? (Y/N) [default: N]:` — нужна ли поддержка htaccess (apache). Значение по умолчанию управляется переменной `$BS_HTACCESS_SUPPORT`  
      - `Enter Y or N for setting SSL Let's Encrypt site (default: N):` — создать сертификат для сайта.  
      Для сайта full:
      - `Enter PHP version for site from installed (default: 8.3):` — указать версию php для сайта. **Внимание!** Указывать можно только версию php из списка `All installed PHP versions:`. Меню не даст ввести другую версию. Установить дополнительные версии можно из главного меню `6) Add/Change global PHP version`
      - `Do you want to add local push-server config to /bitrix/.setting.php? (Y/N) [Y]:` — добавить блок настроек push-сервер в `bitrix/.setting.php`. Если это не б24, то он там не нужен.
      - `Enter username for the site user:` — имя системного пользователя в домашней директории которого будет создан сайт.
      - `Enter database name:` — имя бд
      - `Enter database user:` — имя пользователя бд
      - `Enter database password:` — пароль пользователя бд
         Для этих четырёх пунктов можно оставить автосгенерированные значения.  
      - `Do you really want to create a website? (Y/N):` Будет выведен список выбранных настроек и предложено подтвердить создание сайта.  

   `2) Edit existing website` — отредактировать уже созданный сайт.
      - `Enter existing path to site` — ввести путь к директории сайта  
      - `Enter PHP version for site from installed` — указать версию php. **Внимание!** Указывать нужно только версию php из списка `All installed PHP versions:`. Меню не даст ввести другую версию. Установить дополнительные версии можно из главного меню `6) Add/Change global PHP version`
      - `Do you want to use xdebug? (Y/N) [N]:` — использовать php-fpm с подключённым xdebug для сайта
      - `Do you want htaccess support? (Y/N) [default: N]:` — включить поддержку htaccess (apache).
      - `Do you want nginx-composite from files support? (Y/N) [default: N]:` — включение и обновление
настроек NGINX для композита. (Хранение композита в файлах). Предварительно нужно включить композит в админке сайта.  
      - `Enter Y or N for setting SSL Let`s Encrypt site (default: N):` — создать сертификат для сайта.  

   `3) Delete site` — удаление сайта  
      - `Enter path to site:` — ввести путь к директории сайта. Директория сайта будет удалена безвозвратно. База данных и пользователь бд будут удалены безвозвратно. Введите сгенерированный код для продолжения.  

   `4) Block/Unblock access by ip` — блокировать доступ к nginx по ip-адресу сервера. То есть, если ввести в браузере `http://ip-сервера`, то сайт по умолчанию не откроется. (будет добавлен `/etc/nginx/bx/site_enabled/bx_ext_ip.conf`)  
      Без блокировки будет открываться сайт по умолчанию.  

   `5) Enable/Disable Basic Auth in nginx` — включить/выключить базовую авторизацию в nginx для сайта. Логи и пароль можно задать в меню или использовать переменные `BS_NGINX_BASIC_AUTH_LOGIN` `BS_NGINX_BASIC_AUTH_PASSWORD`  

   `6) Enable/Disable Bot Blocker in nginx` — скачать и установить [mitchellkrogza/nginx-ultimate-bad-bot-blocker](https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker). Подключается для каждого сайта отдельно.  Изучите документация по ссылке для более тонкой настройки. Конфигурационные файлы в `/etc/nginx/bots.d/`.  

1) `Configure Let's Encrypt certificate` — создать сертификат для сайта. Конфигурационный файл в `/etc/nginx/bx/site_settings/домен/ssl.conf`. Конфигурация вынесена в отдельный файл, чтобы не затиралась при редактировании сайта через пункт меню `Edit existing website`.  
2) `Enable or Disable redirect HTTP to HTTPS` — помещает файл `.htsecure` в корень выбранного сайта. Это приводит к включению редиректа с http на https.  
3) `Add/Remove FTP user` — создать или удалить пользователя ftp. Используется pureftpd. Конфигурационные файлы в `/etc/pure-ftpd/  
4) `Add/Change global PHP version`. — Добавление новой версии php.  
   `Set this version of php as the default version? All sites on bitrix that use the default version will be switched to this version.` — установить новую версию php как версию php по умолчанию. То есть `/usr/bin/php` будет использовать новую версию.
   Это затрагивает только сайты пользователя по умолчанию (www-data или bitrix).  
5) `Settings SMTP sites` — по умолчанию на сервер устанавливается postfix. Отправка почты идёт прямо с сервера без аккаунта.  Если сервер за анти-ддос панелью, то такая отправка приводит к утечке ip-адреса сервера. Поэтому, для отправки почты нужно настроить использование стороннего smtp-сервера. Этот пункт меню позволяет создать конфиг для msmtp. Конфигурационный файл в `/etc/msmtprc`.  
   - `Enter site dir` — введите имя директории сайта. Для создания конфига для сайта `example.com` нужно ввести `example.com`.  
   - `Enter From email address` — адрес отправителя.  
   - `Enter SMTP server address` — доменное имя или ip-адрес smtp-сервера.  
   - `Enter SMTP server port` — порт smtp-сервера. (обычно 25 или 465).  
   - `Enter Y or N for to use SMTP authentication` — использовать аутентификацию. Если не уверены, то отвечайте `Y`.  
   - `Enter login` — почтовый логин. Обычно это имя вашего почтового ящика.  
   - `Enter password:` — пароль от почтового ящика. На большинстве сервисов нужно создать специальный пароль для приложения. [yandex](https://yandex.ru/support/id/ru/authorization/app-passwords), [mail.ru](https://help.mail.ru/mail/security/protection/external/), [gmail](https://support.google.com/accounts/answer/185833?hl=ru).  
   - `Enter SMTP authentication method` — в большинстве случаев можно использовать `auto`.
   - `Enter Y or N to enable TLS` — использовать TLS. Если выбрали порт 465, то ответ `Y`.  
   Первый созданный аккаунт станет аккаунтом по умолчанию. Все сайты на сервере будут использовать его. Если хотите, чтобы какие-то сайты продолжали использовать локальный `postfix` просто добавьте для них аккаунт с ip 127.0.0.1 и портом 25.  
   Если сервер не за анти-ддосом, то рекомендую использовать локальный `postfix`, так как большинство почтовых сервисов имеют лимиты на отправку почты. Типичный интернет-магазин вполне легко может превысить эти лимиты при большом количестве заказов.  
   Если грамотно настроить dns-записи (spf / rDNS), то письма будут доходить до получателей не попадая в спам. Убедитесь только, что ip-сервера нет в чёрных списках. Для проверки настроек можно использовать [сервис](https://www.mail-tester.com/). Или используйте собственный почтовый сервер, например [mailcow](https://mailcow.email/), [mailu](https://mailu.io/).  

6) `Installing Extensions` — меню для установки дополнительного ПО  
   `1) Install/Delete Sphinx` — установка sphinx.  

   `2) Install/Delete File Conversion Server (transformer)` — модуль конвертации файлов. Только для лицензии Энтерпрайз. Меню самостоятельно произведёт все настройки битрикса для использования локального модуля.  

   `3) Install/Delete Netdata` — установка системы мониторинга [Netdata](https://www.netdata.cloud/)  

   `4) Install/Delete Crowdsec` — Установка [crowdsec](https://github.com/crowdsecurity/crowdsec). Это бесплатный open source-инструмент для выявления и блокировки вредоносных IP-адресов на основе шаблонов их поведения. Аналог fail2ban на языке Go. Меню установит парсер логов nginx подходящих по формату к логам этого окружения. В .env.menu есть несколько переменных относящихся к данному пункту меню.  
      `BS_CROWDSEC_ENROLL_KEY` — ключ для подключения к облачной консоли https://app.crowdsec.net (опционально)
      `BS_CROWDESC_WHITELIST_IP` — белый список ip для crowdsec, измените на свои ip, через запятую (например zabbix-server и gitlab-runner).  
      `BS_CROWDSEC_COLLECTION_INSTALL` — устанавливаемые по умолчанию коллекции crowdsec, через запятую.  
      `BS_CROWDSEC_SCENARIOS_INSTALL` — устанавливаемые по умолчанию сценарии crowdsec, через запятую.  

   `5) Install/Delete Rkhunter` — установка [rkhunter](https://rkhunter.sourceforge.net/). Конфиг в `/etc/rkhunter.conf.local`. В качестве почты для уведомлений используется значение переменной `BS_EMAIL_ADMIN_FOR_NOTIFY`  

   `6) Install/Delete Linux Malware Detect` — установка [maldet](https://github.com/rfxn/linux-malware-detect). Конфиги в `/usr/local/maldetect/`. В качестве почты для уведомлений используется значение переменной `BS_EMAIL_ADMIN_FOR_NOTIFY`  

   `7) Install/Delete Memcached` — установка memcached. Конфиг в `/etc/memcached.conf`. Сокет в `/tmp/memcached.sock`  

   `8) Install/Delete Deadsnakes PPA` — подключение [Deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa) содержащего более свежие версии python. Не рекомендуется использовать ppa в debian. (Меню поддерживает и ubuntu).  

   `9) Install/Delete Docker` — установка свежей версии докера из официальных репозиториев. Роль меняет log-driver c json на local, так как json очень сильно забивает место на диске.  

   `10) PostgreSQL` — меню для управления postgresql.  

       `1) Install PostgreSQL` — установка разных версии postgresql из официальных репозиториев.  

       `2) Delete PostgreSQL` — удаление выбранной версии postgresql. **Внимание!** Будут удалены все базы данных этой версии.  

       `3) Add user and db in PostgreSQL` — создать пользователя и бд для выбранной версии. Если установлен `pgbouncer`, то в него будет добавлен конфиг для этой бд.пользователя.

       `4) Remove user and db from PostgreSQL` — удалить пользователя и бд.  

       `5) Install/Delete Pgbouncer` — установить или удалить `pgbouncer`  

`9) Update server` — Обновление пакетов. Запуск `apt update -y; apt upgrade -y`.  

`R) Restart the server` — перезагрузка сервера. Запуск команды `reboot`.  

`P) Turn off the server` — выключение сервера. Запуск команды `poweroff`.  

`0) Exit` — выход из меню

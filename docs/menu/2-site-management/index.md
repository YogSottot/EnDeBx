# 2. `Add/Change site`

Это центральное подменю для работы с сайтами. Отсюда создаются новые сайты, выпускаются сертификаты, переключается HTTP -> HTTPS, меняется PHP-конфигурация, включается Basic Auth, Bot Blocker и NTLM, а также выполняется удаление.

## Что входит в раздел

- `Add site`
- `Edit existing website`
- `Delete site`
- `Configure Let's Encrypt certificate`
- `Enable/Disable redirect HTTP to HTTPS`
- `Block/Unblock access by IP`
- `Enable/Disable Basic Auth in nginx`
- `Enable/Disable Bot Blocker in nginx`
- `Configure NTLM auth for sites`

## Как мыслить о двух типах сайтов

Подменю постоянно опирается на два режима:

- `full` - полноценный сайт на отдельном ядре и, как правило, с собственным системным пользователем;
- `link` - сайт на симлинках к существующему `full`-ядру.

Из-за этого логика вопросов в `Add site` заметно меняется в зависимости от выбранного режима.

## Перед началом

Перед любыми изменениями полезно:

- открыть `List of sites dirs`;
- убедиться, что вы понимаете, какой путь относится к какому сайту;
- проверить, какие PHP и БД уже установлены на сервере.

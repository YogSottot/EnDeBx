# 8. `Installing Extensions`

![ext](../../images/menu_ext.jpg)

Это подменю собирает дополнительные компоненты, которые ставятся или удаляются по требованию.

## Что внутри

- `Memcached`
- `Push server`
- `Sphinx`
- `File Conversion Server`
- `Netdata`
- `Docker`
- `Snapd`
- `Deadsnakes PPA` только для Ubuntu
- `Debian repo on Astra Linux` только для Astra Linux

## Общая логика

Почти каждый пункт работает как переключатель:

- если компонент не найден, действие будет `INSTALL`;
- если компонент уже установлен, меню предложит `DELETE`.

Для баз данных и репозиториев логика сложнее, поэтому они вынесены на отдельные страницы.

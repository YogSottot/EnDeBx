# Busconvert для utf8mb4

Эта страница переносит в основную документацию инструкцию по использованию `busconvert` для конвертации базы 1C-Bitrix из `utf8` в `utf8mb4`.

## Что это за скрипт

`busconvert_11.php` - это внешний PHP-скрипт, который последовательно конвертирует таблицы и поля текущей базы сайта в `utf8mb4`.

Полезные ссылки:

- [Скачать `busconvert_11.php`](https://github.com/YogSottot/EnDeBx/raw/refs/heads/feature/php-fpm/repositories/bitrix-gt/busconvert_11.php)
- [Оригинальная markdown-инструкция в репозитории](https://github.com/YogSottot/EnDeBx/blob/feature/php-fpm/repositories/bitrix-gt/busconvert.md)
- [Источник, откуда был взят скрипт](https://tuning-soft.ru/articles/bitrix/busconvert-conversion-of-1c-bitrix-database-from-utf8-to-utf8mb4.html)

## Когда это использовать

Обычно к `busconvert` обращаются после смены `collation` в MySQL-конфиге и в `.env.menu`, если нужно не только поменять настройки подключения, но и реально переконвертировать уже существующие базы.

!!! warning "Делайте отдельно для каждого ядра"
    Если на сервере несколько отдельных ядер Bitrix, конвертацию нужно запускать отдельно для каждого ядра и каждой базы.

## Как работает скрипт

Перед запуском конвертации скрипт показывает текущие значения кодировки и сравнения. После старта он проходит по всей базе и в конце выводит:

- итоговое состояние после конвертации;
- лог SQL-операций;
- количество затронутых таблиц;
- новую кодировку базы, если операция завершилась успешно.

## Что нужно поправить в самом скрипте

Если вы меняете целевые параметры, скорректируйте в начале скрипта:

```php
$charset = 'utf8mb4';
$collate = 'utf8mb4_unicode_ci';
```

## Что сделать после успешной конвертации

После конвертации нужно проверить настройки подключения к базе в двух файлах и заменить `utf8` на `utf8mb4`:

```php
// bitrix/php_interface/after_connect.php
$DB->Query("SET NAMES 'utf8mb4'");
$DB->Query('SET collation_connection = "utf8mb4_unicode_ci"');

// bitrix/php_interface/after_connect_d7.php
$connection = \Bitrix\Main\Application::getConnection();
$connection->queryExecute("SET NAMES 'utf8mb4'");
$connection->queryExecute('SET collation_connection = "utf8mb4_unicode_ci"');
```

Также проверьте `/bitrix/.settings.php`:

```php
'utf_mode' => [
    'value' => true,
    'readonly' => true,
],
```

После этого желательно сбросить кэш сайта, например очистив:

```text
bitrix/cache/
bitrix/managed_cache/
bitrix/stack_cache/
bitrix/html_pages/example.com
```

## Практические замечания автора скрипта

### Скрипт можно не держать в открытом браузере

Процесс не обрывается только из-за закрытия окна браузера. Наблюдать за ходом можно так:

```bash
mysqladmin -i 1 processlist | grep -i ALTER
```

### Скрипт рассчитан на базы в `utf8`

По заметке автора, сценарий тестировался для конвертации именно из `utf8`. Для `cp1251` он не считается готовым.

### Запуск можно повторять

Если часть шагов пришлось исправлять вручную, скрипт допускает повторный запуск.

## На что смотреть после конвертации

Автор отдельно советует проверять через инструменты Bitrix:

- `Настройки -> Инструменты -> Проверка системы`
- `Кодировка соединения`
- `Структура базы данных`

Особенно полезно заранее знать, не было ли отклонений в структуре таблиц еще до запуска конвертации.

## Типовая проблема с длиной индексов

При переходе на `utf8mb4` часть полей `varchar(255)` может упереться в лимит длины индекса. В таком случае встречаются ошибки наподобие:

```sql
Specified key was too long; max key length is 767 bytes
```

Один из рабочих путей - уменьшить проблемные indexed-поля до `varchar(191)`.

Идея такая:

```sql
utf8     VARCHAR(255)
utf8mb4  VARCHAR(191)
```

## Отдельная проблема на MariaDB 10.11

По заметке из репозитория, `busconvert_11.php` уверенно работает на `Percona MySQL 5.7` и `8.0`, но на `MariaDB 10.11` на свежем портале может упасть на изменении `b_lang.LID` из-за внешних ключей.

Типичный сценарий:

1. временно удалить проблемные foreign keys;
2. выполнить `ALTER TABLE` для `b_lang`;
3. привести зависимые поля к той же кодировке;
4. создать ключи заново.

Пример удаления ключей:

```sql
ALTER TABLE `b_learn_course_site` DROP FOREIGN KEY `b_learn_course_site_ibfk_2`;
ALTER TABLE `b_list_rubric` DROP FOREIGN KEY `b_list_rubric_ibfk_1`;
ALTER TABLE `b_xdi_lf_scheme` DROP FOREIGN KEY `b_xdi_lf_scheme_ibfk_1`;
```

Пример модификации:

```sql
ALTER TABLE `b_lang` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
```

Пример возврата ключей:

```sql
CREATE INDEX idx_b_lang_LID ON `b_lang` (`LID`);
ALTER TABLE `b_learn_course_site` MODIFY `SITE_ID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_learn_course_site` ADD CONSTRAINT `b_learn_course_site_ibfk_2` FOREIGN KEY (`SITE_ID`) REFERENCES `b_lang` (`LID`);

ALTER TABLE `b_list_rubric` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_list_rubric` ADD CONSTRAINT `b_list_rubric_ibfk_1` FOREIGN KEY (`LID`) REFERENCES `b_lang` (`LID`);

ALTER TABLE `b_xdi_lf_scheme` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_xdi_lf_scheme` ADD CONSTRAINT `b_xdi_lf_scheme_ibfk_1` FOREIGN KEY (`LID`) REFERENCES `b_lang` (`LID`);
```

!!! warning "Проверяйте на копии"
    Этот сценарий затрагивает структуру таблиц и индексов. Для production-сайтов сначала проверяйте конвертацию на копии и держите актуальный backup.

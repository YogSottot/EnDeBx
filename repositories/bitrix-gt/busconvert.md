### Скрипт конвертации базы данных 1С Битрикса из UTF8 в UTF8MB4

Скрипт взят [отсюда](https://tuning-soft.ru/articles/bitrix/busconvert-conversion-of-1c-bitrix-database-from-utf8-to-utf8mb4.html)  

Копия инструкции по ссылке:  

Сначала скрипт выводит текущие значения кодировки и сравнения до конвертации.  

После нажатия на кнопку **Начать конвертацию** скрипт начнет конвертировать всю текущую базу сайта.

По окончании работы выводит результаты **После конвертации** и **Лог конвертации**, а также количество затронутых таблиц  и новую кодировку базы, если все прошло успешно.

В таблице лога выводится новая кодировка и все SQL-запросы, которые совершал скрипт над данными полей каждой таблицы.

После успешной конвертации остается поменять настройки соединения с базой в 2-х файлах.
Здесь в запросах заменяем utf8 на utf8mb4

```php
//bitrix/php_interface/after_connect.php$DB->Query("SET NAMES 'utf8mb4'");$DB->Query('SET collation_connection = "utf8mb4_unicode_ci"');

//bitrix/php_interface/after_connect_d7.php$connection = \Bitrix\Main\Application::getConnection();$connection->queryExecute("SET NAMES 'utf8mb4'");$connection->queryExecute('SET collation_connection = "utf8mb4_unicode_ci"');
```

А также в файле ```/bitrix/.settings.php```

```php
'utf_mode' =>  array(     'value'    => true,     'readonly' => true,  ),
```

Ещё желательно сбросить весь кэш сайта, либо в админке, либо удалив вот эти папки с диска.

```
bitrix/cache/
bitrix/managed_cache
bitrix/stack_cache
bitrix/html_pages/example.com
```

Всё, это должно помочь, других настроек нет.

### Заметки автора скрипта

1) Скрипт будет работать, даже если закрыть окно браузера, пока все не выполнит.

2) Скрипт тестировался только на кодировке utf8, для кириллицы cp1251 пока не подходит, позже постараюсь и этот момент доработать.

3) Если все же хочется попробовать другую кодировку, то изменяйте значение в этих переменных в самом начале скрипта.

   ```php
   $charset = 'utf8mb4';
   ``$collate = 'utf8mb4_unicode_ci';
   ```

4) Я базу тестового сайта конвертировал раз 50 и никаких проблем, если что, можно запускать скрипт несколько раз.

5) При конвертации тип и другие параметры поля не изменяются, тщательно все проверил, некоторые запросы почему-то изменяли тип поля text на mediumtext

   А проверить это можно инструментом от 1С Битрикс Проверка системы.

   ```Настройки - Инструменты - Проверка системы```

   ```Кодировка соединения``` - будет ругаться, пока Битрикс про это дело не в курсе.  
   ```Структура базы данных``` - Если успешно, значит конвертация прошла успешно, ни одно поле не изменилось в процессе конвертации, важно проверить этот момент еще до конвертации, чтобы потом не гадать, когда это случилось.  
   Если перед конвертацией скрипт найдет отличающиеся от базы поля, то надо все исправить, кроме случаев, когда вы сами изменяли  поля в таблицах и точно знаете, что делаете.

   В этом случае следите за тем, что бы кто-нибудь из ваших разрабов или даже клиент не вернул тут все обратно, скрипт Битрикса может вернуть кодировки обратно в utf8.

6) На двух тестовых сайтах, которые у меня на OSPanel, никаких проблем с конвертацией не было, а вот на текущем пришлось повозиться с такой вот проблемой.

   ```sql
   2017-12-05 03:20:12 - Host: tuning-soft.ru - UNCAUGHT_EXCEPTION - [Bitrix\Main\DB\SqlQueryException] Mysql query error: (1071) Specified key was too long; max key length is 767 bytes (400)ALTER TABLE `b_user_option` MODIFY `NAME` varhar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT  NULL ;
   ```

   Ровно в 20 таблицах пришлось менять тип поля с ```varchar(255)``` на ```varchar(191)```

   Например ```ALTER TABLE `b_sale_discount_entities` MODIFY `FIELD_TABLE` VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;```

   Получется, что для хранения строки utf8 нужно 3 байта на символ, а utf8mb4 нужно 4 байта.  
   Предел для utf8 составляет 767/3 = ~255 символов, для utf8mb4 это 767/4 = ~191 символ.

   ```sql
   utf8 VARCHAR(255)
   utf8mb4 VARCHAR(191)
   ```

   Но почему-то это не для всех полей varchar(255) требовал, только для некоторых, не знаю почему.

   Менял я длину значения поля в базе с помощью своего модуля TSAdminer, вы можете это сделать в любом инструменте для работы с БД.

   Ошибки возможно и у вас будут, их просто надо исправить все, пока конвертация не закончится.

### Ошибки

Скрипт busconvert_11.php работает без проблем на percona mysql 5.7 / 8.0.  
На mariadb 10.11 на свежеустановленном портале падает с ошибкой на этом шаге:

```sql
ALTER TABLE b_lang MODIFY LID char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT  NULL ;
ERROR 1833 (HY000): Cannot change column 'LID': used in a foreign key constraint 'bitrix/b_learn_course_site_ibfk_2' of table 'bitrix/b_learn_course_site'
```

Попытка отключить проверку на время конвертации не помогла ```SET FOREIGN_KEY_CHECKS = 0;```

Тут нужно вручную удалять ключи и добавлять обратно.

```sql
ALTER TABLE `b_learn_course_site` DROP FOREIGN KEY `b_learn_course_site_ibfk_2`;
ALTER TABLE `b_list_rubric` DROP FOREIGN KEY `b_list_rubric_ibfk_1`;
ALTER TABLE `b_xdi_lf_scheme` DROP FOREIGN KEY `b_xdi_lf_scheme_ibfk_1`;
```

Модифицируем

```sql
ALTER TABLE `b_lang` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
```

И добавляем ключи обратно.

```sql
CREATE INDEX idx_b_lang_LID ON `b_lang` (`LID`);
ALTER TABLE `b_learn_course_site` MODIFY `SITE_ID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_learn_course_site` ADD CONSTRAINT `b_learn_course_site_ibfk_2` FOREIGN KEY (`SITE_ID`) REFERENCES `b_lang` (`LID`);


ALTER TABLE `b_list_rubric` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_list_rubric` ADD CONSTRAINT `b_list_rubric_ibfk_1` FOREIGN KEY (`LID`) REFERENCES `b_lang` (`LID`);

ALTER TABLE `b_xdi_lf_scheme` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_xdi_lf_scheme` ADD CONSTRAINT `b_xdi_lf_scheme_ibfk_1` FOREIGN KEY (`LID`) REFERENCES `b_lang` (`LID`);
```

В других таблицах проблем не возникло и скрипт смог завершить конвертацию.

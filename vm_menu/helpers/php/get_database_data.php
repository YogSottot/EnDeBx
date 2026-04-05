<?php

$path_to_settings_file = "{$argv[1]}/.settings.php";

$data = require_once $path_to_settings_file;

$db_name = $data['connections']['value']['default']['database'];
$db_user = $data['connections']['value']['default']['login'];
$db_class = $data['connections']['value']['default']['className'] ?? '';
$db_type = stripos($db_class, 'Pgsql') !== false ? 'pgsql' : 'mysql';
$db_host = $data['connections']['value']['default']['host'] ?? 'localhost';
$db_port = $data['connections']['value']['default']['port'] ?? ($db_type === 'pgsql' ? '5432' : '3306');

echo "$db_name\n";
echo "$db_user\n";
echo "$db_type\n";
echo "$db_host\n";
echo "$db_port\n";

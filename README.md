# PHP-Apache-TCP Development Environment

Простая и переиспользуемая среда разработки на базе Docker для быстрого развертывания стека **PHP-FPM + Apache + MySQL + phpMyAdmin**.

## 📋 Описание

Этот проект представляет собой современную замену XAMPP, MAMP и OpenServer для разработчиков, которые хотят:

- ✅ Быстро развернуть среду разработки для PHP
- ✅ Использовать современные технологии (Docker, PHP 8.4, Apache 2.4, MySQL 8.4)
- ✅ Иметь изолированную и воспроизводимую среду
- ✅ Легко экспериментировать с PHP и веб-разработкой

> **⚠️ Важно**: Эта среда предназначена **только для изучения и экспериментов**. Не используйте её в производственной среде!

## 🏗️ Архитектура

Проект состоит из следующих Docker-контейнеров:

1. **PHP-FPM** (`php-apache-tcp`) - обработка PHP-скриптов
2. **Apache HTTP Server** (`apache-tcp`) - веб-сервер на порту 80
3. **MySQL 8.4** (`mysql-apache-tcp`) - база данных на порту 3306
4. **phpMyAdmin** (`phpmyadmin`) - веб-интерфейс для MySQL на порту 8080

## 📁 Структура проекта
```

php-apache-tcp/
├── config/
│   ├── apache/
│   │   └── httpd.conf          # Конфигурация Apache (в процессе настройки)
│   └── php/
│       └── php.ini             # Конфигурация PHP (в процессе настройки)
├── docker/
│   └── php.Dockerfile          # Dockerfile для PHP-FPM
├── env/
│   ├── .env                    # Переменные окружения
│   └── .env.example            # Пример конфигурации
├── public/                     # Публичные файлы (document root)
│   ├── index.php              # Точка входа приложения
│   └── phpinfo.php            # Информация о PHP
├── src/                       # Исходный код приложения
├── logs/                      # Директория для логов
├── docker-compose.yml         # Основная конфигурация Docker
└── README.md
```
## 🚀 Быстрый старт

### Предварительные требования

- [Docker](https://www.docker.com/get-started) (версия 20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (версия 2.0+)

### 1. Клонирование проекта
```
bash
git clone <repository-url> php-apache-tcp
cd php-apache-tcp
```
### 2. Настройка окружения

Скопируйте файл с примером переменных окружения:
```
bash
cp env/.env.example env/.env
```
При необходимости отредактируйте `env/.env`:
```
bash
# Настройки MySQL
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=php-apache-tcp-db
MYSQL_USER=php-user
MYSQL_PASSWORD=password

# Настройки phpMyAdmin
PMA_HOST=mysql-apache-tcp
PMA_ARBITRARY=1
```
### 3. Запуск среды
```
bash
# Запуск в фоновом режиме
docker-compose up -d

# Или с выводом логов
docker-compose up
```
### 4. Проверка работы

После успешного запуска будут доступны следующие сервисы:

- **Веб-сервер**: http://localhost
- **phpMyAdmin**: http://localhost:8080
- **MySQL**: localhost:3306

## 🔧 Основные команды

### Управление контейнерами
```
bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Просмотр логов
docker-compose logs -f

# Просмотр логов конкретного сервиса
docker-compose logs -f php-apache-tcp
```
### Работа с контейнерами
```
bash
# Доступ к контейнеру PHP
docker-compose exec php-apache-tcp bash

# Доступ к контейнеру Apache
docker-compose exec apache-tcp sh

# Доступ к MySQL
docker-compose exec mysql-apache-tcp mysql -u root -p
```
### Очистка данных
```
bash
# Остановка и удаление всех контейнеров и томов
docker-compose down -v

# Удаление неиспользуемых образов
docker system prune -f
```
## 📝 Разработка

### Размещение файлов

- Поместите ваши PHP-файлы в папку `public/` для публичного доступа
- Исходный код приложения размещайте в папке `src/`
- Оба каталога автоматически монтируются в соответствующие контейнеры

### Конфигурация

#### PHP (config/php/php.ini)

Текущие настройки оптимизированы для разработки:
- `memory_limit = 256M`
- `upload_max_filesize = 20M`
- `max_execution_time = 30`
- OPcache включен для производительности

> **Примечание**: Файл конфигурации находится в стадии разработки и может быть дополнен

#### Apache (config/apache/httpd.conf)

Включены модули:
- `mod_proxy_fcgi` - для работы с PHP-FPM
- `mod_rewrite` - для URL-перезаписи
- `mod_headers` - для управления заголовками
- Базовые настройки безопасности и сжатия

> **Примечание**: Конфигурация находится в стадии разработки

## 🗄️ Работа с базой данных

### Подключение к MySQL
```
php
<?php
$host = 'mysql-apache-tcp';  // Имя сервиса Docker
$dbname = 'php-apache-tcp-db';
$username = 'php-user';
$password = 'password';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    echo "Подключение успешно!";
} catch (PDOException $e) {
    echo "Ошибка подключения: " . $e->getMessage();
}
?>
```
### Доступ к phpMyAdmin

1. Откройте http://localhost:8080
2. Используйте данные из файла `.env`:
   - **Сервер**: `mysql-apache-tcp`
   - **Пользователь**: `php-user` (или `root`)
   - **Пароль**: `password` (или значение `MYSQL_ROOT_PASSWORD`)

## 🐛 Решение проблем

### Порты уже заняты

Если порты 80, 3306 или 8080 уже используются:

```bash
# Проверка занятых портов
netstat -tulpn | grep :80

# Изменение портов в docker-compose.yml
ports:
  - "8080:80"  # вместо "80:80"
```
```


### Проблемы с правами доступа

```shell script
# Установка правильных прав на папки
chmod -R 755 public/
chmod -R 755 src/
```


### Очистка кеша Docker

```shell script
docker-compose down
docker system prune -a -f
docker-compose up -d --build
```


## 🤝 Участие в разработке

Этот проект находится в активной разработке. Планы на будущее:

- [ ] Завершение настройки `php.ini`
- [ ] Оптимизация `httpd.conf`
- [ ] Добавление Makefile для автоматизации команд
- [ ] Поддержка различных версий PHP
- [ ] Добавление Xdebug для отладки
- [ ] Конфигурация Composer

## 📄 Лицензия

Этот проект предназначен для образовательных целей и свободного использования.

## ⚠️ Дисклеймер

**НЕ ИСПОЛЬЗУЙТЕ В ПРОИЗВОДСТВЕННОЙ СРЕДЕ!**

Этот проект создан исключительно для изучения и экспериментов. Конфигурация не обеспечивает необходимый уровень безопасности для производственных систем.

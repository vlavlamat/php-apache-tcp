# План улучшений дев-среды (php.ini, Xdebug, переносимость, healthchecks)

## Цели
- Сделать поведение PHP предсказуемым и «шумным» для обучения (видны все ошибки).
- Включить удобную пошаговую отладку и профилирование (Xdebug), но с простым переключением.
- Повысить переносимость (убрать жёсткую привязку к архитектуре).
- Добавить проверки «здоровья» сервисов и правильный порядок старта.

## Шаг 1. Добавить php.ini (dev-настройки)
- Создать файл config/php/php.ini с базовыми dev-настройками: ошибки, тайм зона, лимиты, «живой» OPCache, подготовка к Xdebug.

Пример содержимого:
```ini
; ===== PHP Dev defaults =====
; Диагностика
error_reporting = E_ALL
display_errors = On
display_startup_errors = On
log_errors = On

; Среда
date.timezone = Europe/Moscow
default_charset = UTF-8

; Лимиты и время
memory_limit = 256M
upload_max_filesize = 20M
post_max_size = 20M
max_execution_time = 60

; OPCache (живое обновление кода)
opcache.enable = 1
opcache.enable_cli = 1
opcache.validate_timestamps = 1
opcache.revalidate_freq = 0

; Гигиена
expose_php = Off
variables_order = "EGPCS"

; ===== Xdebug (управляется через переменные окружения) =====
; Расширение Xdebug будет установлено в образе.
; Режимы включаем через XDEBUG_MODE и XDEBUG_START.
zend_extension=xdebug
xdebug.mode=${XDEBUG_MODE}
xdebug.start_with_request=${XDEBUG_START}
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
; Удобные настройки для develop-режима:
xdebug.discover_client_host=true
xdebug.log_level=0
```


## Шаг 2. Установить Xdebug и утилиту для healthcheck PHP-FPM
Зачем: Xdebug — для пошаговой отладки/профилирования; cgi-fcgi — простой способ «прощупать» FPM-порт из healthcheck.

Изменения в образе PHP (установка Xdebug и cgi-fcgi):
```dockerfile
# docker/php.Dockerfile (фрагмент)
# ...
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    oniguruma-dev \
    libzip-dev \
    fcgi \
 && pecl install xdebug \
 && docker-php-ext-enable xdebug
# ...
```


## Шаг 3. Убрать жёсткую привязку к платформе и смонтировать php.ini
Зачем: переносимость между arm64 и amd64 без ручных правок; удобное редактирование php.ini без пересборки.

Обновления в docker-compose:
- Удалить platform: linux/arm64/v8 у всех сервисов.
- Для PHP добавить монтирование php.ini и env-переменные для Xdebug.
- Опционально оставить пример platform в docker-compose.override.yml.example (вне основного compose) для тех, кому нужно.

Фрагмент для PHP-сервиса:
```yaml
services:
  php-apache-tcp:
    build:
      context: ./docker
      dockerfile: php.Dockerfile
    container_name: php-apache-tcp
    restart: unless-stopped
    volumes:
      - ./public:/var/www/html
      - ./config/php/php.ini:/usr/local/etc/php/conf.d/zz-dev.ini:ro
    environment:
      XDEBUG_MODE: "${XDEBUG_MODE:-off}"     # off | debug | profile | develop | coverage
      XDEBUG_START: "${XDEBUG_START:-no}"    # yes | no
    networks:
      - php-apache-tcp-network
```


## Шаг 4. Добавить healthchecks
Зачем: наглядные статусы, «правильный» порядок старта, понятные сбои.

- PHP-FPM: тест cgi-fcgi подключения к 9000.
- Apache: запрос главной страницы через wget (обычно есть в Alpine как busybox wget).
- MySQL: mysqladmin ping (учитываем пароль из окружения).

Примеры healthcheck:
```yaml
services:
  php-apache-tcp:
    # ...
    healthcheck:
      test: ["CMD", "cgi-fcgi", "-bind", "-connect", "localhost:9000"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 10s

  apache-tcp:
    # ...
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "-", "http://localhost/"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    depends_on:
      php-apache-tcp:
        condition: service_healthy

  mysql-apache-tcp:
    # ...
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-p$$MYSQL_ROOT_PASSWORD"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s
```

Примечание: двойной доллар $$ нужен, чтобы Compose не разворачивал переменную на своей стороне — пароль подставится внутри контейнера.

## Шаг 5. Расширить .env.example (переключатели Xdebug)
Добавить переключатели Xdebug (по умолчанию выключен, чтобы не снижать производительность).
```dotenv
# Xdebug (dev)
XDEBUG_MODE=off     # off | debug | profile | develop | coverage
XDEBUG_START=no     # yes | no
```


## Шаг 6. Обновить README (или docs) — как включать Xdebug и что делают healthchecks
- Как включить/выключить Xdebug:
    - Вариант 1: отредактировать env/.env (XDEBUG_MODE=debug, XDEBUG_START=yes) и перезапустить php-контейнер.
    - Вариант 2 (опционально): отдельный профиль compose или цели Makefile xdebug-on/xdebug-off.
- Что проверяют healthchecks и как читать статусы docker compose ps.

## Шаг 7. (Опционально) Цели Makefile для Xdebug и быстрой проверки здоровья
Удобные шорткаты для разработчика:
```makefile
xdebug-on:
	@echo "XDEBUG_MODE=debug" > /tmp/.xdebug_env && echo "XDEBUG_START=yes" >> /tmp/.xdebug_env
	docker-compose up -d --no-deps php-apache-tcp
	@echo "Xdebug включен: debug + start_with_request"

xdebug-off:
	@echo "XDEBUG_MODE=off" > /tmp/.xdebug_env && echo "XDEBUG_START=no" >> /tmp/.xdebug_env
	docker-compose up -d --no-deps php-apache-tcp
	@echo "Xdebug выключен"

health:
	docker-compose ps
```

Примечание: этот скетч можно заменить на правку env/.env и обычный docker-compose up -d — выберите подходящий для вашего процесса.

Порядок внедрения (быстрый чек-лист)
1) Добавить config/php/php.ini (как в примере).
2) Обновить Dockerfile PHP: установить fcgi и xdebug, включить расширение.
3) Обновить docker-compose:
    - удалить platform у всех сервисов,
    - примонтировать php.ini в PHP-контейнер,
    - добавить environment для Xdebug,
    - добавить healthcheck-и (и depends_on: condition: service_healthy для Apache).
4) Расширить env/.env.example (XDEBUG_MODE, XDEBUG_START).
5) Пересобрать и запустить:
    - docker-compose down -v
    - docker-compose up -d --build
6) Верификация:
    - http://localhost открывается,
    - docker-compose ps показывает healthy для php, mysql, apache,
    - в PHP-скрипте намеренно вызвать предупреждение — оно видно на экране (display_errors=On),
    - включить Xdebug (XDEBUG_MODE=debug, XDEBUG_START=yes), поставить брейкпоинт — убедиться, что IDE ловит соединение на 9003.

Откат (если что-то пойдёт не так)
- Вернуть XDEBUG_MODE=off и XDEBUG_START=no.
- Временно убрать healthcheck блоки.
- Проверить, что php.ini корректно примонтирован (phpinfo() -> Loaded Configuration File).
- Пересобрать php-образ, если меняли Dockerfile.

Результат
- Предсказуемое, «говорящее» окружение для обучения.
- Удобная пошаговая отладка и профилирование по требованию.
- Переносимость между ARM/Intel без ручных правок.
- Наглядные статусы сервисов и корректный порядок старта.
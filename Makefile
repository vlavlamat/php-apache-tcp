# ==========================================
# PHP-Apache-TCP Development Environment
# ==========================================
# Современная замена XAMPP/MAMP/OpenServer
# 
# Основные команды:
# make up        - Запуск всех сервисов
# make down      - Остановка всех сервисов
# make restart   - Перезапуск сервисов
# make logs      - Просмотр логов всех сервисов
# make status    - Статус контейнеров
# make clean     - Полная очистка
# ==========================================

.PHONY: help up down restart build rebuild logs logs-php logs-apache logs-mysql logs-phpmyadmin status shell-php shell-apache shell-mysql clean clean-all setup info test

# Цвета для вывода
YELLOW=\033[0;33m
GREEN=\033[0;32m
RED=\033[0;31m
NC=\033[0m # No Color

# По умолчанию показываем справку
help: ## Показать справку по командам
	@echo "$(YELLOW)PHP-Apache-TCP Development Environment$(NC)"
	@echo "======================================"
	@echo "Современная замена XAMPP/MAMP/OpenServer для изучения PHP"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)URL сервисов после запуска:$(NC)"
	@echo "  Web Server:  http://localhost"
	@echo "  phpMyAdmin:  http://localhost:8080"
	@echo "  MySQL:       localhost:3306"

setup: ## Первоначальная настройка проекта
	@echo "$(YELLOW)Настройка проекта...$(NC)"
	@if [ ! -f env/.env ]; then \
		cp env/.env.example env/.env; \
		echo "$(GREEN)✓ Создан файл env/.env из примера$(NC)"; \
	else \
		echo "$(YELLOW)! Файл env/.env уже существует$(NC)"; \
	fi
	@echo "$(GREEN)✓ Настройка завершена$(NC)"

up: ## Запуск всех сервисов
	@echo "$(YELLOW)Запуск сервисов...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Сервисы запущены$(NC)"
	@echo "$(YELLOW)Доступные URL:$(NC)"
	@echo "  Web Server:  http://localhost"
	@echo "  phpMyAdmin:  http://localhost:8080"

down: ## Остановка всех сервисов
	@echo "$(YELLOW)Остановка сервисов...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Сервисы остановлены$(NC)"

restart: ## Перезапуск всех сервисов
	@echo "$(YELLOW)Перезапуск сервисов...$(NC)"
	docker-compose restart
	@echo "$(GREEN)✓ Сервисы перезапущены$(NC)"

build: ## Сборка образов
	@echo "$(YELLOW)Сборка образов...$(NC)"
	docker-compose build
	@echo "$(GREEN)✓ Образы собраны$(NC)"

rebuild: ## Пересборка образов с очисткой кэша
	@echo "$(YELLOW)Пересборка образов...$(NC)"
	docker-compose build --no-cache
	@echo "$(GREEN)✓ Образы пересобраны$(NC)"

logs: ## Просмотр логов всех сервисов
	docker-compose logs -f

logs-php: ## Просмотр логов PHP-FPM
	docker-compose logs -f php-apache-tcp

logs-apache: ## Просмотр логов Apache
	docker-compose logs -f apache-tcp

logs-mysql: ## Просмотр логов MySQL
	docker-compose logs -f mysql-apache-tcp

logs-phpmyadmin: ## Просмотр логов phpMyAdmin
	docker-compose logs -f phpmyadmin

status: ## Показать статус контейнеров
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker-compose ps

shell-php: ## Подключиться к контейнеру PHP
	docker-compose exec php-apache-tcp sh

shell-apache: ## Подключиться к контейнеру Apache
	docker-compose exec apache-tcp sh

shell-mysql: ## Подключиться к MySQL CLI
	docker-compose exec mysql-apache-tcp mysql -u root -p

info: ## Показать информацию о проекте
	@echo "$(YELLOW)PHP-Apache-TCP Development Environment$(NC)"
	@echo "======================================"
	@echo "$(GREEN)Сервисы:$(NC)"
	@echo "  • PHP-FPM 8.4 (Alpine)"
	@echo "  • Apache HTTP Server 2.4"
	@echo "  • MySQL 8.4"
	@echo "  • phpMyAdmin"
	@echo ""
	@echo "$(GREEN)Структура:$(NC)"
	@echo "  • public/    - публичные файлы (DocumentRoot)"
	@echo "  • src/       - исходный код приложения"
	@echo "  • env/.env   - переменные окружения"
	@echo "  • apache/    - конфигурация Apache"
	@echo ""
	@echo "$(GREEN)Порты:$(NC)"
	@echo "  • 80   - Apache HTTP Server"
	@echo "  • 3306 - MySQL Database"
	@echo "  • 8080 - phpMyAdmin"
	@echo "  • 9000 - PHP-FPM (внутренний)"

test: ## Проверить работу сервисов
	@echo "$(YELLOW)Проверка работы сервисов...$(NC)"
	@echo -n "Apache (http://localhost): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo -n "phpMyAdmin (http://localhost:8080): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

clean: ## Остановка и удаление контейнеров
	@echo "$(YELLOW)Очистка контейнеров...$(NC)"
	docker-compose down -v
	@echo "$(GREEN)✓ Контейнеры и тома удалены$(NC)"

clean-all: ## Полная очистка (контейнеры, образы, тома)
	@echo "$(YELLOW)Полная очистка...$(NC)"
	docker-compose down -v
	docker-compose down --rmi all
	docker system prune -f
	@echo "$(GREEN)✓ Выполнена полная очистка$(NC)"

# Дополнительные команды для разработки
dev-setup: setup up ## Полная настройка для разработки (setup + up)
	@echo "$(GREEN)✓ Среда разработки готова к работе!$(NC)"

dev-reset: clean-all build up ## Сброс среды разработки
	@echo "$(GREEN)✓ Среда разработки сброшена и перезапущена!$(NC)"

# Утилиты для работы с файлами
permissions: ## Исправить права доступа к файлам проекта
	@echo "$(YELLOW)Исправление прав доступа...$(NC)"
	chmod -R 755 public/
	chmod -R 755 src/
	@echo "$(GREEN)✓ Права доступа исправлены$(NC)"

# Composer команды
composer-install: ## Установить зависимости через Composer
	docker-compose exec php-apache-tcp composer install

composer-update: ## Обновить зависимости через Composer
	docker-compose exec php-apache-tcp composer update

composer-require: ## Установить пакет через Composer (make composer-require PACKAGE=vendor/package)
	docker-compose exec php-apache-tcp composer require $(PACKAGE)

# Команда по умолчанию
.DEFAULT_GOAL := help
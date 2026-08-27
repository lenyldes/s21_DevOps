#!/bin/bash

# ==============================================================================
# Справочные данные для генерации логов Nginx в Combined формате
# ==============================================================================

# Коды ответа (HTTP Status Codes) и их значения согласно спецификации:
#
# 200 (OK):
#   Успешный запрос. Стандартный ответ при успешном получении/обработке данных.
# 201 (Created):
#   Запрос успешно выполнен и привел к созданию нового ресурса (обычно в ответ на POST/PUT).
# 400 (Bad Request):
#   Сервер не смог понять запрос из-за некорректного синтаксиса на стороне клиента.
# 401 (Unauthorized):
#   Для доступа к ресурсу требуется аутентификация пользователя (не предоставлены валидные учетные данные).
# 403 (Forbidden):
#   Сервер понял запрос, но отказывается его выполнять из-за отсутствия прав доступа у клиента.
# 404 (Not Found):
#   Сервер не нашел запрашиваемый ресурс по указанному URL.
# 500 (Internal Server Error):
#   Внутренняя ошибка сервера. Сервер столкнулся с непредвиденным условием, помешавшим выполнению запроса.
# 501 (Not Implemented):
#   Сервер не поддерживает функциональность, необходимую для выполнения запроса (например, неизвестный метод).
# 502 (Bad Gateway):
#   Сервер, действуя в качестве шлюза или прокси, получил недопустимый ответ от вышестоящего сервера.
# 503 (Service Unavailable):
#   Сервер временно не готов обрабатывать запросы (обычно из-за перегрузки или технических работ).
STATUS_CODES=(200 201 400 401 403 404 500 501 502 503)

# Методы HTTP-запросов (HTTP Methods)
HTTP_METHODS=("GET" "POST" "PUT" "PATCH" "DELETE")

# Набор типичных URL-адресов ресурсов
REQUEST_URLS=(
    "/index.html"
    "/api/v1/users"
    "/api/v1/auth"
    "/login"
    "/about.html"
    "/static/css/style.css"
    "/static/js/main.js"
    "/images/logo.png"
    "/dashboard"
    "/checkout"
    "/products/item"
    "/contact"
)

# Агенты (User-Agents) согласно требованиям задания:
# 1. Mozilla
# 2. Google Chrome
# 3. Opera
# 4. Safari
# 5. Internet Explorer
# 6. Microsoft Edge
# 7. Crawler and bot
# 8. Library and net tool
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
    "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
    "Googlebot/2.1 (+http://www.google.com/bot.html)"
    "curl/8.4.0"
)

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

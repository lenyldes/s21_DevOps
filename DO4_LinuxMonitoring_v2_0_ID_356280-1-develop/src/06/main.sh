#!/bin/bash

# ==============================================================================
# Part 6: GoAccess Web Dashboard (DO4_LinuxMonitoring_v2.0)
# ==============================================================================

# Определение директорий и путей
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../04/logs"
REPORT_FILE="${SCRIPT_DIR}/report.html"
PORT=8080

# Подключение вспомогательных модулей
source "${SCRIPT_DIR}/validator.sh"
source "${SCRIPT_DIR}/report.sh"

# 1. Валидация входных аргументов
if ! validate_args "$@"; then
    exit 1
fi

# 2. Проверка наличия необходимых зависимостей (Docker и Python 3)
if ! check_dependencies; then
    exit 1
fi

# 3. Проверка наличия сгенерированных логов Nginx
if ! check_log_files "$LOG_DIR"; then
    exit 1
fi

# 4. Генерация отчёта через контейнер GoAccess
if ! generate_report "$LOG_DIR" "$REPORT_FILE"; then
    exit 1
fi

# 5. Запуск веб-сервера и вывод ссылки в терминал
start_server "$SCRIPT_DIR" "$PORT"
exit $?

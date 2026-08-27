#!/bin/bash

# Определение директории со скриптами
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../04/logs"

# Подключение модулей
source "${SCRIPT_DIR}/validator.sh"
source "${SCRIPT_DIR}/parser.sh"

# 1. Валидация входных параметров
if ! validate_args "$@"; then
    exit 1
fi

# 2. Проверка наличия файлов логов
if ! check_log_files "$LOG_DIR"; then
    exit 1
fi

# 3. Разбор и вывод логов
process_logs "$1" "$LOG_DIR"
exit $?

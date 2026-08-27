#!/bin/bash

# Определение директории со скриптами
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключение модулей
source "${SCRIPT_DIR}/validator.sh"
source "${SCRIPT_DIR}/data.sh"
source "${SCRIPT_DIR}/generator.sh"

# 1. Валидация аргументов
if ! validate_args "$@"; then
    exit 1
fi

# 2. Запуск генерации 5 файлов логов в папку logs/
generate_all_logs "${SCRIPT_DIR}/logs"
exit $?

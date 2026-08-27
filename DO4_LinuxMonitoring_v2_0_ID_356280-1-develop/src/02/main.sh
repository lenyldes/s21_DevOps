#!/bin/bash

# Определение директории со скриптами
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключение модулей
source "${SCRIPT_DIR}/validator.sh"
source "${SCRIPT_DIR}/clogger.sh"

# 1. Валидация аргументов
if ! validate_args "$@"; then
    exit 1
fi

# 2. Фиксация времени старта
start_time_sec=$(date +%s)
start_time_str=$(date +"%Y-%m-%d %H:%M:%S")

# 3. Запуск засорения файловой системы
start_clogging "$@"

# 4. Фиксация времени окончания и расчет продолжительности
end_time_sec=$(date +%s)
end_time_str=$(date +"%Y-%m-%d %H:%M:%S")
total_sec=$(( end_time_sec - start_time_sec ))
minutes=$(( total_sec / 60 ))
seconds=$(( total_sec % 60 ))

# 5. Формирование отчета
log_file="${SCRIPT_DIR}/clogging.log"

summary="
=== ИТОГИ РАБОТЫ СКРИПТА ===
Время начала работы:    $start_time_str
Время окончания работы: $end_time_str
Общее время работы:     ${total_sec} сек. (${minutes} мин. ${seconds} сек.)
"

# Вывод на экран и в лог-файл
echo "$summary"
echo "$summary" >> "$log_file"

exit 0

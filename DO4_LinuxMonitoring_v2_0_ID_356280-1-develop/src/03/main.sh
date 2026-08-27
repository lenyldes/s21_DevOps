#!/bin/bash

# Определение директории со скриптами
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключение модулей очистки
source "${SCRIPT_DIR}/clean_log.sh"
source "${SCRIPT_DIR}/clean_time.sh"
source "${SCRIPT_DIR}/clean_mask.sh"

# 1. Проверка входного параметра
if [ "$#" -lt 1 ]; then
    echo "Ошибка: Не указан способ очистки!"
    echo "Использование: $0 <1|2|3> [дополнительные параметры]"
    echo "  1 — Очистка по лог-файлу"
    echo "  2 — Очистка по дате и времени создания (с точностью до минуты)"
    echo "  3 — Очистка по маске имени"
    exit 1
fi

mode="$1"

# 2. Вызов соответствующего способа
case "$mode" in
    1)
        clean_by_log "$@"
        ;;
    2)
        clean_by_time "$@"
        ;;
    3)
        clean_by_mask "$@"
        ;;
    *)
        echo "Ошибка: Некорректный способ очистки '$mode'! Допустимые значения: 1, 2 или 3."
        exit 1
        ;;
esac

exit $?

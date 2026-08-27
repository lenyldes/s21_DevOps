#!/bin/bash

# Способ 1: Очистка по лог-файлу
clean_by_log() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local log_file="${2:-${script_dir}/../02/clogging.log}"

    # Если лог-файл не найден по умолчанию, спросим путь у пользователя
    if [ ! -f "$log_file" ]; then
        echo "Лог-файл по умолчанию не найден: $log_file"
        read -p "Введите путь к лог-файлу: " log_file
    fi

    if [ ! -f "$log_file" ]; then
        echo "Ошибка: Лог-файл '$log_file' не существует."
        return 1
    fi

    echo "Начинаем очистку по лог-файлу: $log_file"
    local count=0

    # Читаем лог построчно и извлекаем пути
    while IFS= read -r line; do
        local target_path=""
        if [[ "$line" =~ ^(Папка|Файл):[[:space:]]+([^|]+)[[:space:]]+\| ]]; then
            target_path="${BASH_REMATCH[2]}"
            # Убираем пробелы по краям
            target_path=$(echo "$target_path" | xargs)

            if [ -e "$target_path" ]; then
                if rm -rf "$target_path" 2>/dev/null; then
                    count=$((count + 1))
                else
                    echo "Предупреждение: Не удалось удалить '$target_path' (требуются права sudo)"
                fi
            fi
        fi
    done < "$log_file"

    echo "Очистка по лог-файлу завершена. Удалено объектов: $count"
    return 0
}

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

#!/bin/bash

# Способ 2: Очистка по дате и времени создания
clean_by_time() {
    local start_time="$2"
    local end_time="$3"

    # Если параметры времени не переданы в командной строке, запрашиваем у пользователя
    if [ -z "$start_time" ]; then
        echo "Введите время начала в формате 'YYYY-MM-DD HH:MM' (например, $(date +"%Y-%m-%d %H:%M")):"
        read -r start_time
    fi

    if [ -z "$end_time" ]; then
        echo "Введите время окончания в формате 'YYYY-MM-DD HH:MM' (например, $(date +"%Y-%m-%d %H:%M")):"
        read -r end_time
    fi

    # Проверяем корректность формата даты через date
    if ! date -d "$start_time" >/dev/null 2>&1; then
        echo "Ошибка: Неверный формат времени начала '$start_time'. Ожидается: 'YYYY-MM-DD HH:MM'."
        return 1
    fi

    if ! date -d "$end_time" >/dev/null 2>&1; then
        echo "Ошибка: Неверный формат времени окончания '$end_time'. Ожидается: 'YYYY-MM-DD HH:MM'."
        return 1
    fi

    # Если время передано с точностью до минуты (без секунд), расширяем диапазон на полную минуту
    if [[ "$start_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}$ ]]; then
        start_time="${start_time}:00"
    fi
    if [[ "$end_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}$ ]]; then
        end_time="${end_time}:59"
    fi

    echo "Поиск и удаление объектов, созданных с '$start_time' по '$end_time'..."
    local count=0

    # Находим файлы и папки с суффиксом даты _DDMMYY, созданные в заданный интервал
    while IFS= read -r item; do
        if [ -e "$item" ]; then
            if rm -rf "$item" 2>/dev/null; then
                count=$((count + 1))
            else
                echo "Предупреждение: Не удалось удалить '$item' (требуются права sudo)"
            fi
        fi
    done < <(find / -newermt "$start_time" ! -newermt "$end_time" 2>/dev/null | grep -E "_[0-9]{6}" | grep -v -E "bin|sbin|proc|sys|dev|run")

    echo "Очистка по времени завершена. Удалено объектов: $count"
    return 0
}

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

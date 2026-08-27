#!/bin/bash

# Способ 3: Очистка по маске имени (символы_дата, например: aaazz_220826 или az_220826)
clean_by_mask() {
    local mask="$2"

    # Если маска не передана аргументом, запрашиваем
    if [ -z "$mask" ]; then
        echo "Введите маску имени (например, 'az_$(date +"%d%m%y")' или '*_$(date +"%d%m%y")'):"
        read -r mask
    fi

    if [ -z "$mask" ]; then
        echo "Ошибка: Маска не может быть пустой."
        return 1
    fi

    echo "Поиск и удаление объектов по маске: '$mask'..."
    local count=0

    # Формируем паттерн для поиска find
    local pattern=""
    if [[ "$mask" =~ ^([a-zA-Z]+)_([0-9]{6})$ ]]; then
        # Если передали формат вида 'az_250826', берем суффикс даты
        local date_part="${BASH_REMATCH[2]}"
        pattern="*_${date_part}*"
    elif [[ "$mask" =~ ^[0-9]{6}$ ]]; then
        # Если передали только дату '250826'
        pattern="*_${mask}*"
    elif [[ "$mask" == \** ]]; then
        pattern="${mask}*"
    else
        pattern="*${mask}*"
    fi

    while IFS= read -r item; do
        if [ -e "$item" ]; then
            if rm -rf "$item" 2>/dev/null; then
                count=$((count + 1))
            else
                echo "Предупреждение: Не удалось удалить '$item' (требуются права sudo)"
            fi
        fi
    done < <(find / -name "$pattern" 2>/dev/null | grep -v -E "bin|sbin|proc|sys|dev|run")

    echo "Очистка по маске завершена. Удалено объектов: $count"
    return 0
}

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

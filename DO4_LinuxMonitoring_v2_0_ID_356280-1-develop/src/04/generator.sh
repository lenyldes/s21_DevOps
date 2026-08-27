#!/bin/bash

# Функция для генерации случайного корректного IPv4-адреса
get_random_ip() {
    local octet1=$(( RANDOM % 223 + 1 ))
    local octet2=$(( RANDOM % 256 ))
    local octet3=$(( RANDOM % 256 ))
    local octet4=$(( RANDOM % 254 + 1 ))
    echo "${octet1}.${octet2}.${octet3}.${octet4}"
}

# Функция генерации одного файла логов за один день
generate_log_for_day() {
    local day_index="$1"
    local output_file="$2"
    local base_midnight="$3"

    # Вычисляем начало дня в секундах (day_index=1 -> 4 дня назад, day_index=5 -> сегодня)
    local day_start_sec=$(( base_midnight - (5 - day_index) * 86400 ))

    # Количество записей за день: случайное число от 100 до 1000
    local records_count=$(( RANDOM % 901 + 100 ))

    local current_sec=$day_start_sec

    # Очищаем или создаем файл лога
    > "$output_file"

    for (( k = 1; k <= records_count; k++ )); do
        # Вычисляем шаг по времени, чтобы распределить записи в рамках суток
        local remaining_records=$(( records_count - k + 1 ))
        local remaining_seconds=$(( day_start_sec + 86399 - current_sec ))
        local max_step=$(( remaining_seconds / remaining_records ))

        if [ "$max_step" -lt 1 ]; then
            max_step=1
        fi

        # Случайное приращение времени для сохранения строго возрастающего хронологического порядка
        local step=$(( RANDOM % max_step + 1 ))
        current_sec=$(( current_sec + step ))

        if [ "$current_sec" -gt $(( day_start_sec + 86399 )) ]; then
            current_sec=$(( day_start_sec + 86399 ))
        fi

        # Форматирование даты в формат Nginx Combined
        local formatted_date
        formatted_date=$(date -d "@$current_sec" +"%d/%b/%Y:%H:%M:%S %z")

        # Генерация данных записи простым прямым доступом к массивам
        local ip
        ip=$(get_random_ip)

        local status="${STATUS_CODES[$(( RANDOM % ${#STATUS_CODES[@]} ))]}"
        local method="${HTTP_METHODS[$(( RANDOM % ${#HTTP_METHODS[@]} ))]}"
        local url="${REQUEST_URLS[$(( RANDOM % ${#REQUEST_URLS[@]} ))]}"
        local agent="${USER_AGENTS[$(( RANDOM % ${#USER_AGENTS[@]} ))]}"

        # Размер ответа в байтах (от 100 до 50000 байт)
        local bytes_sent=$(( RANDOM % 49900 + 100 ))

        # Сборка строки в Combined формате Nginx:
        # $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
        echo "${ip} - - [${formatted_date}] \"${method} ${url} HTTP/1.1\" ${status} ${bytes_sent} \"-\" \"${agent}\"" >> "$output_file"
    done

    local day_str
    day_str=$(date -d "@$day_start_sec" +"%Y-%m-%d")
    echo "Сгенерирован файл $(basename "$output_file"): $records_count записей (Дата: $day_str)"
}

# Функция генерации всех 5 файлов логов
generate_all_logs() {
    local target_dir="$1"

    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    # Получаем полночь сегодняшнего дня в секундах
    local base_midnight
    base_midnight=$(date -d "today 00:00:00" +%s)

    echo "Генерация 5 файлов логов Nginx в формате combined..."
    echo "Директория сохранения: $target_dir"
    echo "--------------------------------------------------------"

    local total_records=0

    for day in {1..5}; do
        local log_file="${target_dir}/nginx_${day}.log"
        generate_log_for_day "$day" "$log_file" "$base_midnight"
        local count
        count=$(wc -l < "$log_file")
        total_records=$(( total_records + count ))
    done

    echo "--------------------------------------------------------"
    echo "Все 5 лог-файлов успешно созданы. Всего ${total_records} записей."
}

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

#!/bin/bash

# Функция генерации базового имени (длина не менее 4 символов + сохранение порядка)
generate_name() {
    local letters="$1"
    local index="$2" # Смещение для генерации уникального имени (0, 1, 2, ...)

    local len=${#letters}
    local first_char="${letters:0:1}"
    local last_char="${letters: -1}"
    local base_name="$letters"

    # Если длина меньше 4 символов, дополняем первой буквой в начале
    while [ ${#base_name} -lt 4 ]; do
        base_name="${first_char}${base_name}"
    done

    # Для каждого следующего элемента добавляем повторение последней буквы
    local extra=""
    for ((k = 0; k < index; k++)); do
        extra="${extra}${last_char}"
    done

    echo "${base_name}${extra}"
}

# Функция проверки свободного места в разделе / (не менее 1 Гб)
check_free_space() {
    # Свободное место в Кб
    local free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local min_kb=1048576 # 1 Гб в Килобайтах

    if [ "$free_kb" -lt "$min_kb" ]; then
        echo "Ошибка: В разделе / осталось менее 1 Гб свободного места ($free_kb Кб)."
        return 1
    fi
    return 0
}

# Основная функция создания папок и файлов
generate_files() {
    local target_dir="$1"
    local dir_count="$2"
    local dir_chars="$3"
    local file_count="$4"
    local file_pattern="$5"
    local file_size="$6"

    # Извлекаем числовое значение размера в Кб
    [[ "$file_size" =~ ^([0-9]+) ]]
    local size_num="${BASH_REMATCH[1]}"

    # Разделяем параметр 5 на имя и расширение
    local file_chars="${file_pattern%%.*}"
    local file_ext="${file_pattern##*.}"

    local date_suffix=$(date +"%d%m%y")
    local log_file="$(dirname "$0")/generator.log"

    # Гарантируем существование целевой директории
    mkdir -p "$target_dir"

    # Создаем/очищаем лог-файл (или дописываем)
    echo "=== Запуск генератора $(date +"%Y-%m-%d %H:%M:%S") ===" >> "$log_file"

    for ((i = 0; i < dir_count; i++)); do
        if ! check_free_space; then
            echo "Генерация остановлена из-за нехватки свободного места."
            return 1
        fi

        local dir_base=$(generate_name "$dir_chars" "$i")
        local dir_name="${dir_base}_${date_suffix}"
        local full_dir_path="${target_dir}/${dir_name}"

        mkdir -p "$full_dir_path"
        local dir_date=$(date +"%d.%m.%y %H:%M:%S")
        echo "Папка: $full_dir_path | $dir_date" >> "$log_file"
        echo "Создана папка: $full_dir_path"

        for ((j = 0; j < file_count; j++)); do
            if ! check_free_space; then
                echo "Генерация остановлена из-за нехватки свободного места."
                return 1
            fi

            local file_base=$(generate_name "$file_chars" "$j")
            local file_name="${file_base}_${date_suffix}.${file_ext}"
            local full_file_path="${full_dir_path}/${file_name}"

            # Создаем файл заданного размера
            fallocate -l "${size_num}K" "$full_file_path" 2>/dev/null || truncate -s "${size_num}K" "$full_file_path"

            local file_date=$(date +"%d.%m.%y %H:%M:%S")
            echo "Файл:  $full_file_path | $file_date | ${size_num}KB" >> "$log_file"
        done
    done

    echo "Генерация успешно завершена. Лог записан в: $log_file"
    return 0
}

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

#!/bin/bash

# Генерация имени (длина буквенной части не менее 5 символов + сохранение порядка)
generate_name() {
    local letters="$1"
    local index="$2" # Смещение для уникальности (0, 1, 2, ...)

    local len=${#letters}
    local first_char="${letters:0:1}"
    local last_char="${letters: -1}"
    local base_name="$letters"

    # В Part 2 минимальная длина имени должна быть от 5 знаков
    while [ ${#base_name} -lt 5 ]; do
        base_name="${first_char}${base_name}"
    done

    # Для каждого следующего имени добавляем повторение последней буквы
    local extra=""
    for ((k = 0; k < index; k++)); do
        extra="${extra}${last_char}"
    done

    echo "${base_name}${extra}"
}

# Проверка свободного места в разделе / (не менее 1 Гб) с использованием команды df -h /
check_free_space() {
    # Получаем вывод df -h / согласно условию задания
    local avail_human=$(df -h / | awk 'NR==2 {print $4}')
    
    # Для точного вычисления берем размер в килобайтах (1 Гб = 1048576 Кб)
    local free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local min_kb=1048576 # 1 Гб в Кб

    if [ "$free_kb" -le "$min_kb" ]; then
        echo "Внимание: В файловой системе (в разделе /) осталось 1 Гб или менее свободного места ($avail_human)!"
        return 1
    fi
    return 0
}

# Действие 0: Создать новую папку с файлами в текущей директории
action_create_folder_with_files() {
    # Проверяем права на запись и отсутствие запрещенных путей
    if [ ! -w "$current_dir" ] || [[ "$current_dir" =~ (bin|sbin|/proc|/sys|/dev|/run|/boot) ]]; then
        return 0
    fi

    # Считаем, сколько папок с нашей датой уже создано в этой директории
    local local_dir_count=$(find "$current_dir" -mindepth 1 -maxdepth 1 -name "*_${date_suffix}" -type d 2>/dev/null | wc -l)

    local offset=0
    local dir_base=""
    local dir_name=""
    local full_dir_path=""

    # Ищем свободное имя для новой папки
    while true; do
        dir_base=$(generate_name "$dir_chars" "$(( local_dir_count + offset ))")
        dir_name="${dir_base}_${date_suffix}"
        full_dir_path="${current_dir}/${dir_name}"
        full_dir_path="${full_dir_path//\/\//\/}"

        if [ ! -d "$full_dir_path" ]; then
            break
        fi
        offset=$((offset + 1))
    done

    if mkdir -p "$full_dir_path" 2>/dev/null; then
        local dir_date=$(date +"%d.%m.%y %H:%M:%S")
        echo "Папка: $full_dir_path | $dir_date" >> "$log_file"
        echo "Создана папка: $full_dir_path"

        # Генерируем случайное число файлов от 1 до 5
        local file_count=$(( RANDOM % 5 + 1 ))

        for ((f = 0; f < file_count; f++)); do
            if ! check_free_space; then
                return 1 # Место закончилось (< 1 Гб)
            fi

            local file_base=$(generate_name "$file_chars" "$f")
            local file_name="${file_base}_${date_suffix}.${file_ext}"
            local full_file_path="${full_dir_path}/${file_name}"

            # Выделяем размер файла в Mb
            fallocate -l "${size_num}M" "$full_file_path" 2>/dev/null || truncate -s "${size_num}M" "$full_file_path"

            local file_date=$(date +"%d.%m.%y %H:%M:%S")
            echo "Файл:  $full_file_path | $file_date | ${size_num}MB" >> "$log_file"
        done
    fi

    # current_dir остается родительской системной директорией для продолжения обхода
    return 0
}

# Действие 1: Перейти в случайную системную подпапку (или подняться наверх, если пусто)
action_go_to_random_child() {
    local subdirs=()
    if [ "$current_depth" -lt 100 ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && subdirs+=("$line")
        done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -type d -writable 2>/dev/null | grep -v -E "bin|sbin|proc|sys|dev|run|boot")
    fi

    local count_subdirs=${#subdirs[@]}
    if [ "$count_subdirs" -gt 0 ]; then
        local rand_idx=$(( RANDOM % count_subdirs ))
        current_dir="${subdirs[$rand_idx]}"
        current_depth=$((current_depth + 1))
    else
        # Если тупик (нет подпапок) — поднимаемся на уровень выше (как cd ..)
        if [ "$current_dir" != "/" ]; then
            current_dir=$(dirname "$current_dir")
            [ "$current_depth" -gt 0 ] && current_depth=$((current_depth - 1))
        fi
    fi
}

# Действие 2: Вернуться в корень файловой системы
action_return_to_root() {
    current_dir="/"
    current_depth=0
}

# Основная функция засорения системы
start_clogging() {
    dir_chars="$1"
    local file_pattern="$2"
    local file_size="$3"

    # Извлекаем числовое значение размера в Mb
    [[ "$file_size" =~ ^([0-9]+) ]]
    size_num="${BASH_REMATCH[1]}"

    file_chars="${file_pattern%%.*}"
    file_ext="${file_pattern##*.}"

    date_suffix=$(date +"%d%m%y")
    log_file="$(dirname "$0")/clogging.log"

    echo "=== Запуск засорения файловой системы $(date +"%Y-%m-%d %H:%M:%S") ===" >> "$log_file"

    current_dir="/"
    current_depth=0

    # Главный цикл
    while true; do
        if ! check_free_space; then
            break
        fi

        # Случайный выбор действия по процентам (1..100)
        local roll=$(( RANDOM % 100 + 1 ))

        if [ "$roll" -le 35 ]; then
            # 1..35 (35%): Создать папку с файлами в текущей директории
            if ! action_create_folder_with_files; then
                break
            fi
        elif [ "$roll" -le 95 ]; then
            # 36..95 (60%): Перейти в случайную подпапку (или шаг назад, если пусто)
            action_go_to_random_child
        else
            # 96..100 (5%): Вернуться в корень
            action_return_to_root
        fi
    done

    return 0
}

# Если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh"
    exit 1
fi

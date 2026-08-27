#!/bin/bash

analyze() {
    local dir_path=$1

    start=$(date +%s.%N)

    echo "Total number of folders (including all nested ones) = $(find "$dir_path" -type d | wc -l)"

    echo "TOP 5 folders of maximum size arranged in descending order (path and size):"
    du "$dir_path" -h --max-depth=1 | sort -hr | tail -n +2 | head -n 5 | awk '{printf "%d - %s/, %s\n", NR, $2, $1}'

    echo "Total number of files = $(find "$dir_path" -type f | wc -l)"

    echo "Number of:"
    echo "Configuration files (with the .conf extension) = $(find "$dir_path" -type f -name "*.conf" | wc -l)"
    echo "Text files = $(find "$dir_path" -type f -name "*.txt" | wc -l)"
    echo "Executable files = $(find "$dir_path" -type f -executable | wc -l)"
    echo "Log files (with the extension .log) = $(find "$dir_path" -type f -name "*.log" | wc -l)"
    echo "Archive files = $(find "$dir_path" -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" -o -name "*.bz2" -o -name "*.xz" -o -name "*.7z" -o -name "*.rar" \) | wc -l)"
    echo "Symbolic links = $(find "$dir_path" -type l | wc -l)"

    echo "TOP 10 files of maximum size arranged in descending order (path, size and type):"
    find "$dir_path" -type f -exec du -h {} + | sort -hr | head -n 10 | awk '{
        # извлекаем имя файла (последний элемент после "/")
        n = split($2, path_parts, "/")
        filename = path_parts[n]

        # ищем расширение в имени файла
        m = split(filename, name_parts, ".")
        ext = (m > 1) ? name_parts[m] : "no ext"

        printf "%d - %s, %s, %s\n", NR, $2, $1, ext
    }'

    echo "TOP 10 executable files of the maximum size arranged in descending order (path, size and MD5 hash of file):"
    find "$dir_path" -type f -executable -exec du -h {} + | sort -hr | head -n 10 | awk '{
        cmd = "md5sum " $2
        cmd | getline hash
        close(cmd)
        split(hash, arr, " ")
        printf "%d - %s, %s, %s\n", NR, $2, $1, arr[1]
    }'

    end=$(date +%s.%N)

    awk "BEGIN {printf \"Script execution time (in seconds) = %.1f\n\", $end - $start}"
}

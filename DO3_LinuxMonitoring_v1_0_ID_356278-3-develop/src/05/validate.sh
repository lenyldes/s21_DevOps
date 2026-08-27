#!/bin/bash

# Проверка количества параметров (должен быть ровно 1)
if [ $# -ne 1 ]; then
    echo "ОШИБКА: нужно передать ровно один параметр (путь к директории)"
    echo "Использование: ./main.sh /path/to/dir/"
    exit 1
fi

dir_path=$1

# Проверка, что путь заканчивается символом '/'
if [ "${dir_path: -1}" != "/" ]; then
    echo "ОШИБКА: путь к директории должен заканчиваться символом '/'"
    echo "Использование: ./main.sh /path/to/dir/"
    exit 1
fi

# Проверка существования директории
if [ ! -d "$dir_path" ]; then
    echo "ОШИБКА: директория '$dir_path' не существует"
    echo "Использование: ./main.sh /path/to/dir/"
    exit 1
fi

# Проверка прав доступа (отсутствие Permission denied)
if find "$dir_path" -type d 2>&1 | grep -q "Permission denied"; then
    echo "ОШИБКА: недостаточно прав доступа для чтения некоторых директорий. Запустите скрипт через sudo."
    echo "Использование: sudo ./main.sh /path/to/dir/"
    exit 1
fi

# Проверка, что директория не пуста
if [ $(find "$dir_path" -mindepth 1 2>/dev/null | wc -l) -eq 0 ]; then
    echo "ОШИБКА: указанная директория пуста"
    echo "Использование: ./main.sh /path/to/dir/"
    exit 1
fi

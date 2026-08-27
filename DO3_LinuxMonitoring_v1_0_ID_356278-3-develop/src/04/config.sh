#!/bin/bash

CONFIG_FILE="config.cfg"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "ОШИБКА: файл конфигурации не найден: $CONFIG_FILE"
    echo "Убедитесь, что файл конфигурации существует и доступен для чтения."
    exit 1
fi

source ./colors.sh

# Дефолтная цветовая схема
DEF_C1_BG=6 # black
DEF_C1_FG=1 # white
DEF_C2_BG=2 # red
DEF_C2_FG=4 # blue

# Функция определения цвета и его текстового описания
resolve_color() {
    local val=$1
    local def=$2

    if [[ "$val" =~ ^[1-6]$ ]]; then
        RES_NUM=$val
        RES_STR="$val ($(color_name "$val"))"
    else
        RES_NUM=$def
        RES_STR="default ($(color_name "$def"))"
    fi
}

resolve_color "$column1_background" "$DEF_C1_BG"
col1_bg=$RES_NUM
col1_bg_str=$RES_STR

resolve_color "$column1_font_color" "$DEF_C1_FG"
col1_fg=$RES_NUM
col1_fg_str=$RES_STR

resolve_color "$column2_background" "$DEF_C2_BG"
col2_bg=$RES_NUM
col2_bg_str=$RES_STR

resolve_color "$column2_font_color" "$DEF_C2_FG"
col2_fg=$RES_NUM
col2_fg_str=$RES_STR

# Проверка: фон и шрифт одного столбца не должны совпадать
if [ "$col1_bg" -eq "$col1_fg" ]; then
    echo "ОШИБКА: Цвет фона и цвет шрифта первой колонки совпадают ($col1_bg)."
    echo "Пожалуйста, измените настройки в файле config.cfg и перезапустите скрипт."
    exit 1
fi

if [ "$col2_bg" -eq "$col2_fg" ]; then
    echo "ОШИБКА: Цвет фона и цвет шрифта второй колонки совпадают ($col2_bg)."
    echo "Пожалуйста, измените настройки в файле config.cfg и перезапустите скрипт."
    exit 1
fi
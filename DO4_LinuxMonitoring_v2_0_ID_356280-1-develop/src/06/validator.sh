#!/bin/bash

# ==============================================================================
# Модуль валидации входных параметров и зависимостей для Part 6
# ==============================================================================

# Проверка входных аргументов (скрипт запускается без параметров)
validate_args() {
    if [[ $# -ne 0 ]]; then
        echo "Ошибка: Скрипт не принимает аргументов." >&2
        echo "Использование: ./main.sh" >&2
        return 1
    fi
    return 0
}

# Проверка наличия необходимых утилит (Docker и Python3)
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        echo "Ошибка: Утилита 'docker' не найдена. Пожалуйста, установите Docker." >&2
        return 1
    fi

    if ! command -v python3 &> /dev/null; then
        echo "Ошибка: Утилита 'python3' не найдена. Пожалуйста, установите Python 3." >&2
        return 1
    fi

    # Проверка доступности Docker daemon
    if ! docker info &> /dev/null; then
        echo "Ошибка: Служба Docker недоступна или у текущего пользователя нет прав." >&2
        echo "Подсказка: Убедитесь, что Docker запущен (sudo systemctl start docker) или добавьте пользователя в группу docker." >&2
        return 1
    fi

    return 0
}

# Проверка наличия файлов логов
check_log_files() {
    local log_dir="$1"

    if [[ ! -d "$log_dir" ]]; then
        echo "Ошибка: Директория с логами '$log_dir' не найдена." >&2
        echo "Подсказка: Сначала сгенерируйте логи с помощью скрипта из Part 4 (src/04/main.sh)." >&2
        return 1
    fi

    # Проверяем наличие хотя бы одного файла nginx_*.log
    local log_files=("$log_dir"/nginx_*.log)
    if [[ ! -e "${log_files[0]}" ]]; then
        echo "Ошибка: В директории '$log_dir' не найдено файлов логов (nginx_*.log)." >&2
        echo "Подсказка: Запустите генератор логов в папке src/04." >&2
        return 1
    fi

    return 0
}

# Защита от прямого запуска модуля
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh" >&2
    exit 1
fi

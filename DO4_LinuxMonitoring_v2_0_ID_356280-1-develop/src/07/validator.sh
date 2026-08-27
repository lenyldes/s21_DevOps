#!/bin/bash

# ==============================================================================
# Модуль валидации окружения и аргументов для Part 7
# ==============================================================================

validate_args() {
    if [[ $# -ne 0 ]]; then
        echo "Ошибка: Скрипт не принимает аргументов." >&2
        echo "Использование: ./main.sh" >&2
        return 1
    fi
    return 0
}

check_dependencies() {
    if ! command -v docker &> /dev/null; then
        echo "Ошибка: Утилита 'docker' не найдена. Пожалуйста, установите Docker." >&2
        return 1
    fi

    if ! docker info &> /dev/null; then
        echo "Ошибка: Служба Docker недоступна или у текущего пользователя нет прав." >&2
        echo "Подсказка: Убедитесь, что Docker запущен (sudo systemctl start docker) или добавьте пользователя в группу docker." >&2
        return 1
    fi

    if ! docker compose version &> /dev/null; then
        echo "Ошибка: Плагин 'docker compose' не установлен." >&2
        return 1
    fi

    return 0
}

# Защита от прямого запуска модуля
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh" >&2
    exit 1
fi

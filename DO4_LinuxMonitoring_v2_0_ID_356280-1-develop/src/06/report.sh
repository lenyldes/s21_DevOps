#!/bin/bash

# ==============================================================================
# Модуль генерации отчета GoAccess через Docker и запуска веб-сервера
# ==============================================================================

# Генерация HTML-отчета через официальную команду контейнера GoAccess
generate_report() {
    local log_dir="$1"
    local report_file="$2"

    echo "==> Обработка логов с помощью GoAccess (Docker)..."
    # Официальная команда GoAccess: передача логов на stdin и сохранение stdout в HTML-файл
    cat "$log_dir"/nginx_*.log | docker run --rm -i \
        -e LANG="${LANG:-en_US.UTF-8}" \
        allinurl/goaccess -a -o html --log-format COMBINED - > "$report_file"

    local docker_status="${PIPESTATUS[1]}"
    if [[ $docker_status -ne 0 ]] || [[ ! -s "$report_file" ]]; then
        echo "Ошибка: Не удалось сгенерировать отчёт GoAccess (код ошибки: $docker_status)." >&2
        return 1
    fi

    echo "==> Отчет успешно сгенерирован: $report_file"
    return 0
}

# Запуск встроенного HTTP-сервера Python и вывод ссылки
start_server() {
    local script_dir="$1"
    local port="${2:-8080}"

    echo ""
    echo "=================================================================="
    echo "  GoAccess Веб-интерфейс готов к работе!"
    echo "=================================================================="
    echo "  Ссылка для открытия в браузере на хосте:"
    echo "  http://localhost:${port}/report.html"
    echo ""
    echo "  (Для завершения работы веб-сервера нажмите Ctrl+C)"
    echo "=================================================================="
    echo ""

    # Запуск веб-сервера Python в директории со сгенерированным отчетом
    python3 -m http.server "$port" --directory "$script_dir"
}

# Защита от прямого запуска модуля
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ошибка: Этот скрипт является модулем. Запускайте через main.sh" >&2
    exit 1
fi

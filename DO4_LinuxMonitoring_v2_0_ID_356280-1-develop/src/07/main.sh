#!/bin/bash

# ==============================================================================
# Part 7: Prometheus & Grafana Stack (DO4_LinuxMonitoring_v2.0)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключение модуля валидации
source "${SCRIPT_DIR}/validator.sh"

# 1. Проверка аргументов
if ! validate_args "$@"; then
    exit 1
fi

# 2. Проверка зависимостей (Docker и Docker Compose)
if ! check_dependencies; then
    exit 1
fi

echo "==> Запуск стека мониторинга через Docker Compose..."
# Docker Compose автоматически дождется статуса healthy для зависимых сервисов
docker compose -f "${SCRIPT_DIR}/docker-compose.yml" up -d

if [[ $? -ne 0 ]]; then
    echo "Ошибка: Не удалось запустить сервисы через Docker Compose." >&2
    exit 1
fi

echo "==> Подождем пару секунд пока все сервисы поднимутся..."
for i in {5..1}; do
    echo "==> $i..."
    sleep 1
done

echo ""
echo "==> Проверка состояния сервисов..."
docker compose -f "${SCRIPT_DIR}/docker-compose.yml" ps

echo ""
echo "=================================================================="
echo "  Сервисы мониторинга успешно запущены!"
echo "=================================================================="
echo "  Node Exporter метрики: http://localhost:9100/metrics"
echo "  Prometheus интерфейс:  http://localhost:9090"
echo "  Grafana дашборд:       http://localhost:3000 (admin / admin)"
echo "=================================================================="
echo ""

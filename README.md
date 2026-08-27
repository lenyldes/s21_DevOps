# Портфолио проектов по DevOps, системному администрированию и CI/CD

![Linux](https://img.shields.io/badge/Linux-Ubuntu%2020.04%20LTS-FCC624?style=flat&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Language-Bash%205.0+-4EAA25?style=flat&logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Containerization-Docker%20%7C%20Compose-2496ED?style=flat&logo=docker&logoColor=white)
![GitLab CI](https://img.shields.io/badge/CI%2FCD-GitLab%20CI-FC6D26?style=flat&logo=gitlab&logoColor=white)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-E6522C?style=flat&logo=prometheus&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-success?style=flat)

Репозиторий представляет собой последовательную систему прикладных инженерных задач, моделирующих реальные сценарии эксплуатации серверной инфраструктуры — от базовой инициализации физических/виртуальных серверов до автоматизированной доставки кода на удаленные целевые узлы с мгновенным оповещением команды.

Все проекты выполнены с соблюдением отраслевых стандартов надежности, принципов Infrastructure as Code (IaC), строгой валидации входных параметров, безопасности сетевого периметра и изоляции процессов.

---

## Навигация по проектам

| # | Модуль | Тематика проекта | Основные изучаемые концепции | Документация |
| :- | :--- | :--- | :--- | :--- |
| 01 | **D01: Linux Basics** | Системное администрирование Linux, пользователи, процессы, накопители и службы | Права доступа, sudoers, разметка дисков fdisk, анализ FS (df, du, ncdu), systemd (sshd, timesyncd), cron, аудит логов | [README.md](./D01_Linux.ID_356272-1-develop/README.md) |
| 02 | **DO2: Linux Network** | Компьютерные сети в Linux, статическая маршрутизация, фильтрация трафика и NAT | Бесклассовая адресация (ipcalc, CIDR), Netplan YAML, статическая маршрутизация, iptables (Filter, NAT/MASQUERADE, DNAT), DHCP (isc-dhcp-server), iperf3, SSH-туннели | [README.md](./DO2_LinuxNetwork.ID_356275-1-develop/README.md) |
| 03 | **DO3: Linux Monitoring v1.0** | Автоматизация системного мониторинга и анализ файлов на Bash | Модульные Bash-скрипты, валидация CLI-аргументов regex, ANSI-стилизация вывода, чтение метрик procfs/sysfs, логирование .status, аудит файлов и хеширование MD5 | [README.md](./DO3_LinuxMonitoring_v1_0_ID_356278-3-develop/README.md) |
| 04 | **DO4: Linux Monitoring v2.0** | Комплексный мониторинг, стресс-нагрузка FS, аналитика веб-логов и Prometheus/Grafana | Генерация файлов (fallocate), стресс-тестирование FS до 1 Гб порога, стратегии очистки (лог, время, маска), синтез и awk-парсинг логов Nginx, GoAccess, стек Prometheus/Grafana | [README.md](./DO4_LinuxMonitoring_v2_0_ID_356280-1-develop/README.md) |
| 05 | **DO5: Simple Docker** | Контейнеризация сервисов, FastCGI на C, безопасность Dockle и Docker Compose | Жизненный цикл Docker, написание Dockerfile, непривилегированный пользователь (non-root), устранение уязвимостей CIS Docker Benchmark (Dockle), multi-container стек (Nginx + FastCGI) через Docker Compose | [README.md](./DO5_SimpleDocker.ID_356282-1-develop/README.md) |
| 06 | **DO6: CI/CD Pipeline** | Непрерывная интеграция и доставка (CI/CD) на базе GitLab CI/CD | Проектирование .gitlab-ci.yml (4 стадии: build, style_check, test, deploy), артефакты сборки, строгий линтинг clang-format (-Werror), bash-тестирование, ручной деплой по SSH/SCP, Telegram Bot API нотификации | [README.md](./DO6_CICD.ID_356283-1-develop/README.md) |

---

## Структура репозитория

```text
.
├── README.md                                         # Общая документация портфолио DevOps
├── D01_Linux.ID_356272-1-develop/                    # Проект 01: Администрирование Linux
│   ├── README.md                                     # Документация проекта D01
│   └── src/
│       ├── D01_Linux.md                              # Инженерный отчет по 15 разделам
│       └── screenshot/                               # Графические подтверждения конфигураций
├── DO2_LinuxNetwork.ID_356275-1-develop/             # Проект 02: Сетевое администрирование
│   ├── README.md                                     # Документация проекта DO2
│   └── src/
│       ├── DO2_LinuxNetwork.md                       # Инженерный отчет по 8 разделам сетей
│       └── screenshot/                               # Подтверждения тестов маршрутизации
├── DO3_LinuxMonitoring_v1_0_ID_356278-3-develop/     # Проект 03: Bash-мониторинг v1.0
│   ├── README.md                                     # Документация проекта DO3
│   └── src/
│       ├── 01/                                       # Модуль валидации CLI-аргументов
│       ├── 02/                                       # Модуль сбора системной телеметрии
│       ├── 03/                                       # Модуль ANSI-стилизации терминального вывода
│       ├── 04/                                       # Модуль конфигурационного управления цветами
│       └── 05/                                       # Модуль глубокого аудита файловой системы
├── DO4_LinuxMonitoring_v2_0_ID_356280-1-develop/     # Проект 04: Комплексный мониторинг v2.0
│   ├── README.md                                     # Документация проекта DO4
│   └── src/
│       ├── 01/                                       # Модуль комбинаторной генерации директорий
│       ├── 02/                                       # Модуль стресс-нагрузки файловой системы
│       ├── 03/                                       # Модуль очистки диска (3 независимых метода)
│       ├── 04/                                       # Генератор веб-логов Nginx Combined
│       ├── 05/                                       # AWK-парсер и фильтратор веб-логов
│       ├── 06/                                       # Модуль визуализации отчетов GoAccess
│       ├── 07/                                       # Observability-стек (Prometheus + Grafana)
│       └── 08/                                       # Экспорт и визуализация дашбордов Grafana
├── DO5_SimpleDocker.ID_356282-1-develop/             # Проект 05: Контейнеризация и Docker
│   ├── README.md                                     # Документация проекта DO5
│   └── src/
│       ├── Dockerfile                                # Оптимизированный Dockerfile (non-root)
│       ├── docker-compose.yml                        # Мультиконтейнерная оркестрация
│       ├── part_1.md                                 # Исследование базовых операций Docker
│       ├── part_2.md                                 # Кастомные конфигурации Nginx
│       ├── part_4.sh                                 # Скрипт сборки и тестирования контейнера
│       ├── part6_nginx/                              # Конфигурация Reverse Proxy Nginx
│       ├── server/                                   # Исходный код FastCGI-сервера на C
│       └── status.conf                               # Конфигурация эндпоинта stub_status
└── DO6_CICD.ID_356283-1-develop/                     # Проект 06: CI/CD пайплайн
    ├── README.md                                     # Документация проекта DO6
    ├── .gitlab-ci.yml                                # Декларация этапов CI/CD конвейера
    └── src/
        ├── deploy.sh                                 # Скрипт автоматизированного деплоя по SSH
        └── test.sh                                   # Интеграционные тесты CLI-приложения
```

---

## Требования и инструкция по быстрому старту

### Системные требования
- **Операционная система:** Linux (рекомендуется Ubuntu 20.04 LTS или выше);
- **Командные оболочки:** GNU Bash 5.0+;
- **Базовый инструментарий:** GNU Coreutils, `awk`, `sed`, `curl`, `iproute2`, `net-tools`;
- **Контейнеризация:** Docker Engine 20.10+, Docker Compose v2+;
- **CI/CD раннер:** GitLab Runner (для воспроизведения распределенного пайплайна);
- **Линтеры и компиляторы:** `gcc`, `clang-format`, `make`.

### Быстрый старт

1. **Клонирование репозитория:**
   ```bash
   git clone <url-репозитория>
   cd <каталог-репозитория>
   ```

2. **Запуск скриптов системного мониторинга (DO3):**
   ```bash
   # Вывод базовой телеметрии системы с сохранением в лог
   cd DO3_LinuxMonitoring_v1_0_ID_356278-3-develop/src/02
   bash main.sh

   # Анализ файловой структуры каталога
   cd ../05
   bash main.sh /var/log/
   ```

3. **Запуск стресс-тестирования и стека метрик (DO4):**
   ```bash
   # Развертывание Prometheus и Grafana через Docker Compose
   cd DO4_LinuxMonitoring_v2_0_ID_356280-1-develop/src/07
   docker compose up -d
   ```

4. **Сборка и запуск контейнеризованного FastCGI-сервера (DO5):**
   ```bash
   # Запуск multi-container стека с Reverse Proxy
   cd DO5_SimpleDocker.ID_356282-1-develop/src
   docker compose up --build -d
   curl http://localhost:80/
   ```

5. **Тестирование конвейера сборки и интеграционных тестов (DO6):**
   ```bash
   # Локальный прогон тестов приложения
   cd DO6_CICD.ID_356283-1-develop/src
   bash test.sh
   ```

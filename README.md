# Портфолио проектов по DevOps, системному администрированию и CI/CD

![Linux](https://img.shields.io/badge/Linux-Ubuntu-FCC624?style=flat&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Language-Bash%205.0+-4EAA25?style=flat&logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Containerization-Docker%20%7C%20Compose%20%7C%20Swarm-2496ED?style=flat&logo=docker&logoColor=white)
![Ansible](https://img.shields.io/badge/Automation-Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![Consul](https://img.shields.io/badge/Service_Discovery-HashiCorp%20Consul-F24C53?style=flat&logo=consul&logoColor=white)
![GitLab CI](https://img.shields.io/badge/CI%2FCD-GitLab%20CI-FC6D26?style=flat&logo=gitlab&logoColor=white)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-E6522C?style=flat&logo=prometheus&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-success?style=flat)

Репозиторий представляет собой последовательную систему прикладных инженерных задач, моделирующих реальные сценарии эксплуатации серверной инфраструктуры — от базовой инициализации физических/виртуальных серверов до автоматизированной доставки кода на удаленные целевые узлы с мгновенным оповещением команды.

Все проекты выполнены с соблюдением отраслевых стандартов надежности, принципов Infrastructure as Code (IaC), строгой валидации входных параметров, безопасности сетевого периметра и изоляции процессов.

---

## Обзор портфолио

Инженерный комплекс охватывает полный жизненный цикл серверных систем и распределенных приложений:

1. **Фундамент системного уровня (D01, DO2)**: глубокое администрирование дисковых подсистем, прав доступа, демонов `systemd`, развертывание сложных сетевых топологий, бесклассовой маршрутизации и пакетной фильтрации через `iptables`.
2. **Автоматизация и системный мониторинг (DO3, DO4)**: разработка специализированных CLI-утилит на Bash для сбора телеметрии ядра, стресс-нагрузка дисковых накопителей, потоковый аудит логов веб-серверов через `awk` и развертывание Observability-стека Prometheus/Grafana.
3. **Контейнеризация и веб-сервисы (DO5)**: разработка высокопроизводительного C-демона FastCGI, создание защищенных легковесных образов Docker в соответствии с CIS Docker Benchmark (Dockle) и двухуровневое обратное проксирование Nginx.
4. **Непрерывная интеграция и доставка (DO6)**: проектирование многостадийного конвейера GitLab CI/CD со статическим анализом кода Google Style, автоматическим тестированием, ручным гейтом деплоя по SSH/SCP и интеграцией Telegram-оповещений.
5. **Кластерная оркестрация микросервисов (DO7)**: оптимизация многоэтапных сборок (Multi-Stage Builds) для микросервисов Java 21 / Spring Boot, предотвращение состояния гонки при запуске (`wait-for-it.sh`), локальный запуск через Docker Compose и развертывание отказоустойчивого кластера Docker Swarm в оверлейной сети VXLAN под управлением Vagrant.
6. **Конфигурационное управление и Service Discovery (DO8)**: безагентная автоматизация серверов на базе Ansible (модульные роли, идемпотентные плейбуки), развертывание распределенного сервис-каталога HashiCorp Consul с консенсусом Raft, интеграция Service Mesh через Envoy sidecar-прокси и подтверждение Zero-Downtime миграции сервисов.

---

## Ключевые компетенции и стек технологий

| Категория | Освоенные технологии и практические компетенции |
| :--- | :--- |
| **Системное администрирование Linux** | GNU/Linux (Ubuntu 20.04/24.04 LTS), управление процессами (`systemd`, `cron`, сигналы POSIX), пользователи и группы (`sudoers`, `chmod`, `chown`, ACL), дисковая подсистема (`fdisk`, `mkfs`, монтирование томов, `df`, `du`, `ncdu`), системный аудит (`journalctl`, анализ `/var/log`). |
| **Компьютерные сети и безопасность** | Стеки протоколов TCP/IP, UDP, ICMP; бесклассовая адресация CIDR, расчет масок и подсетей (`ipcalc`); статическая маршрутизация и Netplan YAML; межсетевые экраны и NAT (`iptables`: таблицы Filter, NAT, цепочки PREROUTING, POSTROUTING, MASQUERADE); DHCP-сервер (`isc-dhcp-server`); замеры пропускной способности (`iperf3`); безопасный удаленный доступ (SSH-ключи ED25519/RSA, туннелирование портов, SCP). |
| **Bash-скриптинг и аналитика** | GNU Bash 5.0+, регулярные выражения (POSIX regex), потоковая обработка текстовых потоков (`awk`, `sed`, `grep`, `cut`, `sort`, `uniq`), опрос виртуальных файловых систем ядра (`/proc`, `/sys`), стилизация интерфейсов (ANSI escape-последовательности), криптографическое хеширование (MD5, SHA256). |
| **Контейнеризация и безопасность (Docker)** | Docker Engine, написание оптимизированных многоэтапных сборок (Multi-Stage Dockerfile на Eclipse Temurin Alpine), минимизация слоев OverlayFS, кэширование зависимостей Maven/JDK, безопасные непривилегированные пользователи (`USER non-root`), устранение уязвимостей CIS Docker Benchmark с помощью линтера Dockle, мультиплатформенная сборка Docker Buildx (`amd64`/`arm64`). |
| **Оркестрация (Compose & Swarm)** | Docker Compose (декларативное описание 9-компонентных микросервисных стеков, `depends_on`, bind-mount, изоляция сетей `bridge`), Docker Swarm (инициализация менеджера, подключение воркеров, распределенные оверлейные сети VXLAN, Ingress Routing Mesh, сервисы с репликацией, горизонтальное масштабирование `scale`, rolling updates без простоя, самоисцеление кластера Anti-Flapping), визуализатор Portainer CE Agent Stack. |
| **Управление конфигурациями (Ansible)** | Инфраструктура как код (IaC), инвентари хостов `inventory.ini`, безагентная архитектура по SSH, написание декларативных плейбуков `playbook.yml`, ключевые модули (`apt`, `deb822_repository`, `get_url`, `file`, `copy`, `unarchive`, `systemd`, `lineinfile`, `user`), архитектурная декомпозиция на повторно используемые роли (Ansible Roles), коллекция `community.postgresql`. |
| **Service Discovery & Service Mesh (Consul)** | HashiCorp Consul (серверный и клиентский режимы в синтаксисе HCL, алгоритм консенсуса Raft, gossip-протокол Serf LAN), централизованный Service Catalog, активные проверки жизнеспособности (HTTP/TCP/Script Health Checks), Service Discovery через встроенный DNS-интерфейс (порт 8600) и HTTP API (порт 8500), интеграция Consul Connect Service Mesh с Envoy sidecar-прокси (протокол xDS, gRPC 8502, взаимное mTLS-шифрование, Zero-Downtime миграция сетевых адресов). |
| **Инфраструктура виртуализации (IaC)** | HashiCorp Vagrant, Oracle VirtualBox, автоматизированное создание гетерогенных многоузловых кластеров (`Vagrantfile`), конфигурирование частных подсетей (Private Network), проброс портов (Port Forwarding), shell-провижининг. |
| **CI/CD и автоматизация поставки** | Проектирование пайплайнов в `.gitlab-ci.yml` (4 стадии: `build`, `style_check`, `test`, `deploy`), управление артефактами (`artifacts`, `expire_in: 30 days`), ручные гейты деплоя (`when: manual`), статический анализ кода Google Style (`clang-format -n -Werror`), интеграционное Bash-тестирование, беспарольная доставка бинарников по SSH/SCP, Telegram Bot API нотификации статусов пайплайна через `after_script`. |
| **Observability, мониторинг и тесты** | Prometheus (сбор метрик, scrape configs, TSDB), визуализация метрик в Grafana (проектирование кастомных дашбордов, мониторинг CPU/Memory/Disk/Network), потоковый парсинг логов Nginx через GoAccess, автоматизация сквозного тестирования REST API (коллекции Postman, запуск в контейнеризованном раннере Newman CLI). |

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
| 07 | **DO7: Container Orchestration** | Оркестрация микросервисов: Multi-Stage Docker, Docker Compose и кластер Docker Swarm | Микросервисный стек (Java 21 / Spring Boot, RabbitMQ, PostgreSQL), оптимизация multi-stage сборок (~124 МБ), wait-for-it.sh, виртуализация Vagrant/VirtualBox, кластер Swarm (Manager + Workers), оверлейная сеть VXLAN, Ingress Mesh, Portainer CE, автотесты Postman/Newman | [README.md](./DO7_Docker_Compose_ID_1219717-1-develop/README.md) |
| 08 | **DO8: Infrastructure Automation & Service Discovery** | Автоматизация конфигурации через Ansible и Service Discovery на HashiCorp Consul | Безагентный провижининг по SSH, модульные роли Ansible (application, apache, postgres), развертывание 9 микросервисов в Docker, кластер HashiCorp Consul (Raft, Serf Gossip), Service Mesh Envoy sidecar, Health Checks, DNS/HTTP discovery, Zero-Downtime миграция хостов | [README.md](./DO8_AutomationTools_ID_1220167-1-develop/README.md) |

---

## Структура репозитория

|||text
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
├── DO6_CICD.ID_356283-1-develop/                     # Проект 06: CI/CD пайплайн
│   ├── README.md                                     # Документация проекта DO6
│   ├── .gitlab-ci.yml                                # Декларация этапов CI/CD конвейера
│   └── src/
│       ├── deploy.sh                                 # Скрипт автоматизированного деплоя по SSH
│       └── test.sh                                   # Интеграционные тесты CLI-приложения
├── DO7_Docker_Compose_ID_1219717-1-develop/             # Проект 07: Docker Compose и Docker Swarm
│   ├── README.md                                     # Документация проекта DO7
│   └── src/
│       ├── Vagrantfile                               # Топология виртуальных машин Swarm (3 узла)
│       ├── docker-compose.yml                        # Мультиконтейнерная оркестрация микросервисов
│       ├── portainer-agent-stack.yml                 # Стек мониторинга и UI Portainer CE
│       ├── REPORT.md                                 # Инженерный отчет с подтверждениями
│       ├── application_tests.postman_collection.json # Сквозные E2E-тесты REST API
│       ├── script/
│       │   └── docker-install.sh                     # Автоматизированная установка Docker Engine
│       └── services/                                 # Исходный код 7 микросервисов и сервисов БД
└── DO8_AutomationTools_ID_1220167-1-develop/            # Проект 08: Ansible и Service Discovery (Consul)
    ├── README.md                                     # Документация проекта DO8
    └── src/
        ├── Vagrantfile                               # Стенды виртуализации для Ansible и Consul
        ├── REPORT.MD                                 # Инженерный отчет с подтверждениями
        ├── application_tests.postman_collection.json # Коллекция E2E-тестов API
        ├── ansible01/                                # Part 1: Плейбук и роли деплоя микросервисов
        │   ├── inventory.ini                         # Инвентарь хостов (manager, node01, node02)
        │   ├── playbook.yml                          # Оркестрация ролей (application, apache, postgres)
        │   └── roles/                                # Модульные роли Ansible (application, apache, postgres)
        ├── ansible02/                                # Part 2: Плейбук и роли Service Discovery
        │   ├── inventory.ini                         # Инвентарь хостов (consulServer, api, db)
        │   ├── playbook.yml                          # Оркестрация Consul, Envoy, Spring Boot и PostgreSQL
        │   └── roles/                                # Модульные роли Ansible (consul_*, postgres, hotel_service)
        └── consul01/                                 # HCL-конфигурации HashiCorp Consul
            ├── consul_server.hcl                     # Конфигурация сервера Consul (Raft, Web UI)
            └── consul_client.hcl                     # Конфигурация клиента Consul (gRPC, xDS)
|||

---

## Требования и инструкция по быстрому старту

### Системные требования
- **Операционная система:** Linux (рекомендуется Ubuntu 20.04 / 22.04 / 24.04 LTS);
- **Командные оболочки:** GNU Bash 5.0+;
- **Базовый инструментарий:** GNU Coreutils, `awk`, `sed`, `curl`, `git`, `git-lfs`, `iproute2`, `net-tools`;
- **Контейнеризация:** Docker Engine 20.10+, Docker Compose v2+;
- **Виртуализация и IaC:** HashiCorp Vagrant 2.3+, Oracle VirtualBox 7.0+;
- **Автоматизация конфигурации:** Ansible 2.14+ (с коллекцией `community.postgresql`);
- **CI/CD раннер:** GitLab Runner (для воспроизведения распределенного пайплайна);
- **Компиляторы и утилиты сборки:** `gcc`, `clang-format`, `make`, OpenJDK 21, Apache Maven.

### Быстрый старт

1. **Клонирование репозитория:**
   |||bash
   git clone <url-репозитория>
   cd <каталог-репозитория>
   git lfs install
   git lfs pull
   |||

2. **Запуск скриптов системного мониторинга (DO3):**
   |||bash
   # Вывод базовой телеметрии системы с сохранением в лог
   cd DO3_LinuxMonitoring_v1_0_ID_356278-3-develop/src/02
   bash main.sh

   # Анализ файловой структуры каталога
   cd ../05
   bash main.sh /var/log/
   |||

3. **Запуск стресс-тестирования и стека метрик (DO4):**
   |||bash
   # Развертывание Prometheus и Grafana через Docker Compose
   cd DO4_LinuxMonitoring_v2_0_ID_356280-1-develop/src/07
   docker compose up -d
   |||

4. **Сборка и запуск контейнеризованного FastCGI-сервера (DO5):**
   |||bash
   # Запуск multi-container стека с Reverse Proxy
   cd DO5_SimpleDocker.ID_356282-1-develop/src
   docker compose up --build -d
   curl http://localhost:80/
   |||

5. **Тестирование конвейера сборки и интеграционных тестов (DO6):**
   |||bash
   # Локальный прогон тестов приложения
   cd DO6_CICD.ID_356283-1-develop/src
   bash test.sh
   |||

6. **Локальный запуск микросервисного стека бронирования (DO7):**
   |||bash
   # Запуск 9 контейнеров стека бронирования через Docker Compose
   cd DO7_Docker_Compose_ID_1219717-1-develop/src
   docker compose up -d --build
   curl http://localhost:8087/api/v1/hotels
   |||

7. **Развертывание кластера Docker Swarm на виртуальных машинах (DO7):**
   |||bash
   # Подъем кластера виртуализации через Vagrant
   cd DO7_Docker_Compose_ID_1219717-1-develop/src
   vagrant up
   vagrant ssh manager01
   |||

8. **Автоматизация конфигурации серверов через Ansible (DO8):**
   |||bash
   # Развертывание виртуальных машин стенда Ansible
   cd DO8_AutomationTools_ID_1220167-1-develop/src
   vagrant up manager node01 node02

   # Подключение к менеджеру и запуск модульного плейбука
   vagrant ssh manager
   cd /vagrant/ansible01
   ansible-playbook -i inventory.ini playbook.yml
   |||

9. **Развертывание Service Discovery на HashiCorp Consul (DO8):**
   |||bash
   # Развертывание кластера Consul и микросервиса отелей
   cd DO8_AutomationTools_ID_1220167-1-develop/src
   vagrant up consulServer api db
   vagrant ssh consulServer
   cd /vagrant/ansible02
   ansible-playbook -i inventory.ini playbook.yml

   # Проверка статуса сервисов в веб-интерфейсе Consul
   curl http://192.168.56.20:8500/v1/catalog/services
   |||

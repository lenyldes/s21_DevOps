# Основы оркестрации контейнеров: Docker Compose и Docker Swarm (Container Orchestration Fundamentals: Docker Compose, Multi-Stage Builds & Docker Swarm Cluster)

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Docker Swarm](https://img.shields.io/badge/Docker_Swarm-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/engine/swarm/)
[![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot_3-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ_3-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)](https://www.rabbitmq.com/)
[![Portainer CE](https://img.shields.io/badge/Portainer_CE-13BEBB?style=for-the-badge&logo=portainer&logoColor=white)](https://www.portainer.io/)
[![Postman](https://img.shields.io/badge/Postman-FF6C37?style=for-the-badge&logo=postman&logoColor=white)](https://www.postman.com/)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)]()

Инженерный проект — проектирование, контейнеризация и оркестрация распределённой микросервисной системы бронирования отелей. \
Система состоит из 7 независимых сервисов на Java 21 / Spring Boot, реляционной СУБД PostgreSQL 16 с шестью изолированными базами данных, асинхронного брокера сообщений RabbitMQ 3 и обратного прокси-сервера Nginx. \
Проект охватывает полный цикл DevOps-практик: оптимизацию сборки артефактов через двухэтапные Dockerfile (Multi-Stage Builds на Eclipse Temurin 21 Alpine) с уменьшением веса контейнеров до ~124 МБ, синхронизацию зависимостей при старте через wait-for-it.sh, локальную декларативную оркестрацию и изоляцию портов через Docker Compose, автоматизированный провижионинг кластера из трёх виртуальных машин (Manager и 2 Worker) через Vagrant и VirtualBox, развёртывание и масштабирование отказоустойчивого кластера Docker Swarm в оверлейной сети (Overlay Network / VXLAN), интеграцию системы мониторинга Portainer CE Agent Stack и сквозное E2E-тестирование REST API через Postman / Newman CLI.

---

## О проекте

Микросервисная архитектура даёт гибкость разработки и независимость масштабирования компонентов, но порождает ряд инженерных сложностей: рост числа точек отказа, проблемы сетевой связности, гонки при холодном старте зависимых сервисов и неэффективное использование диска при неоптимальной сборке контейнеров. Этот проект решает перечисленные задачи на всех уровнях инфраструктуры.

### Проблематика изоляции и оптимизация образов (Multi-Stage Builds)
При классической сборке Java-приложений в Docker финальный образ часто содержит полный JDK, утилиты сборки (Maven Wrapper), исходный код и промежуточный кэш артефактов. В итоге образ раздувается до 800 МБ — 1.5 ГБ, а поверхность атаки расширяется. В проекте применяется паттерн многоэтапной сборки (Multi-Stage Build):
- **Сборочный этап (`app_builder`)**: базируется на `eclipse-temurin:21-jdk-alpine`, кэширует зависимости проекта через предварительный вызов `./mvnw dependency:go-offline` и собирает исполняемый fat-JAR (`mvn package -DskipTests`).
- **Рантайм-этап (`app_runner`)**: базируется на минималистичном JRE-образе `eclipse-temurin:21-jre-alpine`. В него копируется только скомпилированный JAR-файл и лёгкий скрипт синхронизации `wait-for-it.sh`. Итоговый размер контейнера сокращён до ~124 МБ (123 887 026 байт).

### Синхронизация распределённого запуска (Readiness Synchronization)
В микросервисной среде запуск контейнера не означает мгновенную готовность его бизнес-логики. Если сервис бронирования попытается подключиться к PostgreSQL или RabbitMQ до завершения их инициализации, приложение упадёт (CrashLoop). Для решения проблемы гонки (Race Condition) каждый Dockerfile оснащён утилитой `wait-for-it.sh`, которая опрашивает TCP-сокет целевого сервиса перед выполнением `java -jar app.jar`:
- Микросервисы бизнес-логики ждут готовности порта `$POSTGRES_HOST:$POSTGRES_PORT`.
- Входной шлюз `gateway-service` ждёт готовности `$SESSION_SERVICE_HOST:$SESSION_SERVICE_PORT`.

### Локальная оркестрация и сетевая изоляция (Docker Compose)
Для локальной разработки и тестирования стек разворачивается через `docker-compose.yml`. Реализован принцип наименьших сетевых привилегий:
- Внешний доступ с хост-машины открыт только к шлюзу `gateway-service` (`8087`) и сервису авторизации `session-service` (`8081`).
- Все внутренние сервисы (`hotel-service`, `booking-service`, `payment-service`, `loyalty-service`, `report-service`, а также `postgres` и `rabbitmq`) работают исключительно во внутренней изолированной сети Docker bridge и не имеют открытых портов наружу.

### Кластерная оркестрация и отказоустойчивость (Docker Swarm)
Одиночный хост — единая точка отказа (Single Point of Failure). Для обеспечения высокой доступности (High Availability) проект переходит к кластерной оркестрации Docker Swarm:
- **IaC-виртуализация**: Vagrantfile декларативно описывает трёхнодовую топологию на VirtualBox (`manager01`, `worker01`, `worker02`) в изолированной подсети `192.168.10.0/24` с автоматическим провижионингом Docker Engine через shell-скрипт.
- **Оверлейные сети (Overlay Networks)**: распределённая сеть VXLAN объединяет контейнеры на разных виртуальных машинах в общий защищённый периметр со встроенным Service Discovery и Ingress Routing Mesh.
- **Обратный прокси Nginx**: шлюз маршрутизации запросов изолирует сервисы сессий и API Gateway, принимая внешний трафик на портах `8081` и `8087` и проксируя его внутрь оверлейной сети.
- **Самоисцеление (Self-Healing) и Anti-Flapping**: оркестратор постоянно сверяет фактическое состояние (Actual State) с желаемым (Desired State). При внезапном падении рабочего узла (`worker02`) Swarm мгновенно переносит задачи на доступные ноды. При возврате ноды кластер следует принципу наименьшего вмешательства (Principle of Least Disruption), предотвращая искусственные простои за счёт управляемой ребалансировки (`docker service update --force`).

### Мониторинг и визуализация (Portainer CE Agent Stack)
Для прозрачного контроля состояния кластера развёрнут стек Portainer: агенты запущены в глобальном режиме (`mode: global`) на каждом узле для сбора телеметрии контейнеров, а центральный сервер Portainer размещён на узле-менеджере (`mode: replicated`, `replicas: 1`) и предоставляет визуализатор Swarm Visualizer для инспекции размещения реплик в реальном времени.

---

## Ключевые навыки и освоенные концепции

- **Multi-Stage Docker Builds**: разделение сборочной среды (JDK 21, Maven Wrapper) и среды исполнения (JRE 21 Alpine), минимизация размера образов до ~124 МБ, повышение безопасности за счёт исключения компиляторов и утилит сборки из продакшн-образов.
- **Оптимизация кэширования слоёв Docker**: послойная сборка (кэширование `pom.xml` и зависимостей через `dependency:go-offline` отдельно от исходного кода проекта), корректная обработка указателей Git LFS (`.mvn/wrapper/maven-wrapper.jar`).
- **Мультиплатформенная сборка (Docker Buildx)**: сборка и кросс-компиляция контейнеров под архитектуры `linux/amd64` и `linux/arm64`, публикация версионированных образов в публичный реестр Docker Hub.
- **Синхронизация жизненного цикла (Service Readiness & Healthcheck)**: предотвращение сбоев при холодном старте распределённых сервисов с помощью `wait-for-it.sh`, опрашивающей TCP-сокеты БД и шлюзов до запуска JVM.
- **Декларативная оркестрация (Docker Compose)**: описание мультиконтейнерного стека из 9 сервисов, управление порядком запуска через `depends_on`, параметризация через переменные окружения, проброс портов и монтирование томов (`init.sql` для PostgreSQL).
- **Сетевая безопасность и периметровая изоляция**: реализация принципа минимальных привилегий (Least Privilege) на сетевом уровне — базы данных и внутренние микросервисы скрыты внутри закрытого контура, доступ к API только через реверс-прокси Nginx.
- **Инфраструктура как код (IaC) с Vagrant и VirtualBox**: автоматизированное развёртывание гетерогенного кластера из 3 виртуальных машин Ubuntu 24.04 (`manager01` с 2 vCPU / 2048 MB RAM, `worker01` и `worker02` с 1 vCPU / 1024 MB RAM), конфигурирование статических IP-адресов приватной сети и общих папок (`synced_folder`).
- **Оркестрация в Docker Swarm**: инициализация менеджера кластера (`docker swarm init`) с явной фиксацией интерфейса `--advertise-addr 192.168.10.10`, безопасное подключение рабочих узлов по токенам (`docker swarm join`), мониторинг состояния через `docker node ls`.
- **Оверлейные сети (Overlay Network / VXLAN)**: настройка межхостовой сетевой маршрутизации для прозрачного взаимодействия сервисов на разных виртуальных нодах без прямого доступа извне.
- **Управление сервисами Swarm (Service Lifecycle)**: деплой стеков через `docker stack deploy`, инспекция задач (`docker stack ps`, `docker node ps` с фильтрами `desired-state=running`), динамическое горизонтальное масштабирование (`docker service scale`), принудительные rolling updates (`docker service update --force`).
- **Анализ отказоустойчивости и механизмов балансировки**: моделирование аварийных отказов узлов, изучение механизма сохранения желаемого состояния (Desired State Engine) и принципа минимального вмешательства (Anti-Flapping).
- **Кластерный мониторинг (Portainer CE & Agent)**: развёртывание стека управления кластером (`portainer-agent-stack.yml`) с глобальным размещением агентов, инспекция размещения контейнеров через Swarm Visualizer.
- **Автоматизированное интеграционное E2E-тестирование**: запуск коллекций Postman в контейнере Newman CLI с использованием сетевого режима хоста (`--network host`) и инжекцией динамических параметров окружения (`--env-var API_HOST=...`).

---

## Архитектура и стек технологий

### Компоненты системы

1. **gateway-service** (порт `8087`): единая точка входа для клиентов REST API. Агрегирует запросы, проверяет права доступа через обращение к `session-service` и маршрутизирует вызовы к соответствующим бизнес-микросервисам.
2. **session-service** (порт `8081`): сервис аутентификации и авторизации пользователей. Реализует Basic Auth, выпуск сессионных Bearer-токенов и управление профилями в базе `users_db`.
3. **hotel-service** (порт `8082`): каталог гостиниц и номерного фонда. Предоставляет данные об отелях, тарифах и доступности свободных номеров. Работает с базой `hotels_db`.
4. **booking-service** (порт `8083`): ключевой бизнес-сервис бронирования. Координирует процесс резервирования номеров, взаимодействует с `hotel-service`, `payment-service`, `loyalty-service` и публикует события в очередь сообщений RabbitMQ. База данных — `reservations_db`.
5. **payment-service** (порт `8084`): платежный процессинг. Проводит транзакции оплаты бронирования, фиксирует статусы счетов в базе `payments_db`.
6. **loyalty-service** (порт `8085`): программа лояльности. Управляет бонусными счетами пользователей, начисляет и списывает баллы в базе `balances_db`.
7. **report-service** (порт `8086`): асинхронный сервис сбора аналитики и статистики бронирований. Слушает очередь сообщений `messagequeue` брокера RabbitMQ и агрегирует метрики в базе `statistics_db`.
8. **postgres** (порт `5432`): реляционная база данных PostgreSQL 16 Alpine. При первом запуске автоматически инициализирует 6 независимых баз данных (`users_db`, `hotels_db`, `reservations_db`, `payments_db`, `balances_db`, `statistics_db`) через смонтированный скрипт `init.sql`.
9. **rabbitmq** (порт `5672`): асинхронный брокер сообщений RabbitMQ 3 Management. Реализует паттерн Publisher/Subscriber через обменник `messagequeue-exchange` и очередь `messagequeue` для слабой связанности сервисов бронирования и отчётов.
10. **nginx-proxy** (порты `8081`, `8087`): реверс-прокси на базе `nginx:1.31.4-alpine-slim`. Внешний шлюз кластера, проксирующий запросы к `session-service` и `gateway-service` внутри защищённой оверлейной сети.

### Топология узлов кластера Docker Swarm

- **manager01** (`192.168.10.10`): управляющий узел (2 vCPU, 2048 MB RAM). Swarm Manager (Raft Consensus Leader, API-эндпоинт `:2377`), планирует распределение задач по нодам, размещает серверную часть Portainer CE (`:9443`), Portainer Agent и ingress-прокси Nginx (`:8081`, `:8087`).
- **worker01** (`192.168.10.11`): рабочий узел (1 vCPU, 1024 MB RAM). Запускает контейнеры микросервисов (PostgreSQL, Booking, Hotel, Payment) и Portainer Agent (`:9001`).
- **worker02** (`192.168.10.12`): рабочий узел (1 vCPU, 1024 MB RAM). Запускает контейнеры микросервисов (RabbitMQ, Gateway, Session, Loyalty, Report) и Portainer Agent (`:9001`).

### Схема 1: Взаимодействие микросервисов, брокера сообщений и баз данных

```text
                               +--------------------------------------------+
                               |     Клиент / Postman (Newman Test Runner)  |
                               +--------------------------------------------+
                                         |                         |
                           HTTP GET/POST | :8087      HTTP Basic   | :8081
                           (Bearer Auth) |            Auth         |
                                         v                         v
+---------------------------------------------------------------------------------------------------------+
|                                        NGINX REVERSE PROXY                                              |
|                                       (Порты: 8081, 8087)                                               |
+---------------------------------------------------------------------------------------------------------+
       |                                                                          |
       | proxy_pass :8087                                                         | proxy_pass :8081
       v                                                                          v
+------------------------+                                             +------------------------+
|    gateway-service     | -------- Проверка сессии / токена --------> |    session-service     |
|      (Порт 8087)       |                                             |      (Порт 8081)       |
+------------------------+                                             +------------------------+
   |        |        |                                                             |
   |        |        +-------------------------+                                   |
   |        v                                  v                                   |
   |  +------------------------+         +------------------------+                |
   |  |     hotel-service      |         |     payment-service    |                |
   |  |      (Порт 8082)       |         |      (Порт 8084)       |                |
   |  +------------------------+         +------------------------+                |
   v        ^                                  ^                                   |
+------------------------+                     |                                   |
|    booking-service     | --------------------+                                   |
|      (Порт 8083)       |                                                         |
+------------------------+ --------------------+                                   |
   |        |                                  |                                   |
   | AMQP   v                                  v                                   |
   |  +------------------------+         +------------------------+                |
   |  |    loyalty-service     |         |     report-service     |                |
   |  |      (Порт 8085)       |         |      (Порт 8086)       |                |
   |  +------------------------+         +------------------------+                |
   |        |                                  ^                                   |
   |        |                                  | AMQP (Consumer)                   |
   |        v                                  |                                   |
   |  +---------------------------------------------------+                        |
   +->|              RABBITMQ MESSAGE BROKER              |                        |
      | Exchange: messagequeue-exchange | Queue: messagequeue|                     |
      +---------------------------------------------------+                        |
                                                                                   |
============================== СЕТЕВОЙ СЛОЙ ДАННЫХ ================================|
                                                                                   |
   +----------------------------------------------------------------------------+  |
   |                         POSTGRESQL 16 (Порт 5432)                          |<-+
   |  +--------------+  +--------------+  +------------------+  +-------------+ |
   |  |   users_db   |  |   hotels_db  |  | reservations_db  |  | payments_db | |
   |  +--------------+  +--------------+  +------------------+  +-------------+ |
   |  +--------------+  +--------------+                                        |
   |  |  balances_db |  |statistics_db |                                        |
   |  +--------------+  +--------------+                                        |
   +----------------------------------------------------------------------------+
```

### Схема 2: Архитектура отказоустойчивого кластера Docker Swarm

```text
+----------------------------------------------------------------------------------------------------+
|                                ХОСТОВАЯ СИСТЕМА (VAGRANT / VIRTUALBOX)                             |
|                               Приватная сеть кластера: 192.168.10.0/24                             |
+----------------------------------------------------------------------------------------------------+
           |                                       |                                    |
           v                                       v                                    v
+-----------------------+              +-----------------------+             +-----------------------+
|   УЗЕЛ: manager01     |              |    УЗЕЛ: worker01     |             |    УЗЕЛ: worker02     |
|    192.168.10.10      |              |     192.168.10.11     |             |     192.168.10.12     |
|   (2 vCPU, 2048 MB)   |              |   (1 vCPU, 1024 MB)   |             |   (1 vCPU, 1024 MB)   |
+-----------------------+              +-----------------------+             +-----------------------+
|  Docker Swarm Manager |              |  Docker Swarm Worker  |             |  Docker Swarm Worker  |
|  - Raft Leader        |              |  - Задача: Worker Node|             |  - Задача: Worker Node|
|  - Service Scheduler  |              |  - Execution Engine   |             |  - Execution Engine   |
|  - Swarm API (:2377)  |              |                       |             |                       |
|                       |              |                       |             |                       |
|  [Запущенные службы]  |              |  [Запущенные службы]  |             |  [Запущенные службы]  |
|  * Portainer Server   |              |  * Portainer Agent    |             |  * Portainer Agent    |
|    (:9443, :9000)     |              |    (:9001, Global)    |             |    (:9001, Global)    |
|  * Portainer Agent    |              |  * postgres           |             |  * rabbitmq           |
|    (:9001, Global)    |              |  * booking-service    |             |  * gateway-service    |
|  * nginx-proxy        |              |  * hotel-service      |             |  * session-service    |
|    (:8081, :8087)     |              |  * payment-service    |             |  * loyalty-service    |
|                       |              |                       |             |  * report-service     |
+-----------------------+              +-----------------------+             +-----------------------+
           ^                                       ^                                    ^
           |                                       |                                    |
           +=======================================+====================================+
                                      |
                 DOCKER OVERLAY NETWORK (VXLAN / driver: overlay)
                 - Маршрутизация Ingress Routing Mesh
                 - Внутренний Service Discovery (DNS: hotel_app_default, agent_network)
                 - Изоляция сетевого периметра сервисов
```

---

## Структура проекта и реализованные модули

| Файл / Директория | Назначение | Ключевые технологии и концепции |
| :--- | :--- | :--- |
| [src/docker-compose.yml](src/docker-compose.yml) | Декларативная спецификация запуска микросервисов стека `hotel_app` | Docker Compose, depends_on, environment variables, networks, ports isolation |
| [src/Vagrantfile](src/Vagrantfile) | IaC-конфигурация трёх виртуальных машин (`manager01`, `worker01`, `worker02`) | Vagrant, VirtualBox provider, private_network, synced_folder, shell provision |
| [src/portainer-agent-stack.yml](src/portainer-agent-stack.yml) | Стек визуализации и управления Docker Swarm через Portainer CE | Portainer Agent (mode: global), Portainer Server (mode: replicated), overlay network |
| [src/script/docker-install.sh](src/script/docker-install.sh) | Shell-скрипт автоматической установки Docker Engine и плагинов на узлы ВМ | Bash, apt GPG keyrings, docker-ce, containerd, docker-compose-plugin, usermod |
| [src/application_tests.postman_collection.json](src/application_tests.postman_collection.json) | Сквозная коллекция интеграционных тестов API для автоматизированного прогона | Postman Collection v2.1, Newman CLI, Basic Auth, Bearer Token extraction, E2E assertions |
| [src/REPORT.md](src/REPORT.md) | Подробный технический отчёт со всеми шагами реализации, логами и скриншотами | Markdown, CLI logs, multi-stage benchmarks, Swarm failover analysis |
| [src/services/nginx/nginx.conf](src/services/nginx/nginx.conf) | Конфигурационный файл обратного прокси для шлюза API и сервиса сессий | Nginx, upstream proxy_pass, routing on ports 8081 and 8087 |
| [src/services/nginx/Dockerfile](src/services/nginx/Dockerfile) | Лёгкий Dockerfile сборки прокси-сервера | Alpine Linux, nginx:1.31.4-alpine-slim |
| [src/services/database/init.sql](src/services/database/init.sql) | DDL-скрипт создания 6 независимых баз данных для каждого микросервиса | PostgreSQL SQL script, CREATE DATABASE, multi-tenancy database schema |
| [src/services/gateway-service/Dockerfile](src/services/gateway-service/Dockerfile) | Спецификация сборки API Gateway с ожиданием доступности сессионного сервиса | Multi-stage build, Eclipse Temurin 21 JDK/JRE, wait-for-it.sh |
| [src/services/session-service/Dockerfile](src/services/session-service/Dockerfile) | Спецификация сборки сервиса авторизации и выпуска токенов с ожиданием PostgreSQL | Multi-stage build, Maven dependency caching, wait-for-it.sh |
| [src/services/hotel-service/Dockerfile](src/services/hotel-service/Dockerfile) | Спецификация сборки сервиса каталога и номерного фонда отелей | Multi-stage build, Alpine runtime, layer optimization |
| [src/services/booking-service/Dockerfile](src/services/booking-service/Dockerfile) | Спецификация сборки сервиса резервирования номеров и взаимодействия с RabbitMQ | Multi-stage build, Eclipse Temurin 21 Alpine, wait-for-it.sh |
| [src/services/payment-service/Dockerfile](src/services/payment-service/Dockerfile) | Спецификация сборки платёжного шлюза и обработки счетов | Multi-stage build, Maven Wrapper offline caching |
| [src/services/loyalty-service/Dockerfile](src/services/loyalty-service/Dockerfile) | Спецификация сборки сервиса баланса бонусных баллов пользователей | Multi-stage build, JRE Alpine minimal footprint |
| [src/services/report-service/Dockerfile](src/services/report-service/Dockerfile) | Спецификация сборки сервиса аналитики, потребляющего события из очереди | Multi-stage build, Spring AMQP Consumer, wait-for-it.sh |
| [src/screenshot/](src/screenshot/) | Архив скриншотов прохождения всех этапов развёртывания и тестов | PNG screenshots: Docker builds, Swarm nodes, Postman runs, Portainer UI |

---

## Инструкция по сборке, тестированию и запуску

### 1. Локальный запуск микросервисов через Docker Compose

#### Предварительные требования и настройка Git LFS
Перед первой сборкой образов убедитесь, что бинарные файлы Maven Wrapper (`.mvn/wrapper/maven-wrapper.jar`), версионируемые в репозитории через Git Large File Storage (LFS), корректно выгружены. Иначе сборщик Maven упадёт с ошибкой `Could not find or load main class org.apache.maven.wrapper.MavenWrapperMain`.

```bash
# Установка и инициализация Git LFS
sudo apt update && sudo apt install -y git-lfs
git lfs install
git lfs pull
```

#### Сборка образов и запуск контейнеров в фоне
Сборка образов микросервисов и запуск инфраструктуры (PostgreSQL, RabbitMQ) выполняются одной командой:

```bash
cd /home/lenyldes/s21_DevOps/DO7_Docker_Compose_ID_1219717-1-develop/src

# Сборка образов с нуля и запуск всех сервисов в фоновом режиме
docker compose up -d --build
```

#### Проверка статуса контейнеров
Убедитесь, что все контейнеры перешли в статус `Up` (сервисы успешно прошли проверку готовности через `wait-for-it.sh`):

```bash
docker compose ps
# или
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

#### Измерение и анализ размера собранных образов
Благодаря multi-stage сборке на базе `eclipse-temurin:21-jre-alpine` размер итоговых образов минимизирован. Проверить размер можно тремя способами:

1. **Список образов через `docker images`:**
   ```bash
   docker images booking-service:v1
   ```
   *Результат: Content Size ~124 МБ (Disk Usage ~393 МБ со вспомогательными слоями).*

2. **Точный размер в байтах через `docker inspect`:**
   ```bash
   docker inspect --format='{{.Size}}' booking-service:v1
   ```
   *Результат: 123887026 байт (~124 МБ).*

3. **Детализация по слоям через `docker history`:**
   ```bash
   docker history booking-service:v1 --format "table {{.CreatedBy}}\t{{.Size}}"
   ```

---

### 2. Развёртывание виртуальной инфраструктуры через Vagrant

Для создания изолированного кластера из 3 узлов (`manager01`, `worker01`, `worker02`) используется Vagrant и провайдер VirtualBox.

```bash
cd /home/lenyldes/s21_DevOps/DO7_Docker_Compose_ID_1219717-1-develop/src

# Запуск и автоматический провижионинг всех виртуальных машин
vagrant up

# Проверка текущего состояния виртуальных машин
vagrant status
```

Вывод команды `vagrant status` подтверждает успешный запуск:
```text
manager01                 running (virtualbox)
worker01                  running (virtualbox)
worker02                  running (virtualbox)
```

#### Проверка подключения по SSH и синхронизации файлов
Каждая виртуальная машина имеет доступ к исходному коду проекта через общую директорию `/vagrant_data`:

```bash
# Подключение к узлу-менеджеру
vagrant ssh manager01

# Проверка файлов проекта в гостевой ОС
ls -la /vagrant_data
exit
```

#### Команды управления жизненным циклом ВМ
- `vagrant halt`: корректное завершение работы гостевых ОС (Graceful Shutdown). Состояние дисков и конфигурация сохраняются.
- `vagrant destroy -f`: полное удаление виртуальных машин и связанных виртуальных дисков из гипервизора VirtualBox.

---

### 3. Инициализация и настройка кластера Docker Swarm

#### Шаг 3.1. Инициализация Swarm Manager
Подключитесь к узлу `manager01`. При инициализации Swarm важно явно задать параметр `--advertise-addr`, так как Vagrant создаёт несколько сетевых интерфейсов (NAT `10.0.2.15` и статический интерфейс приватной сети `192.168.10.10`). Без этого флага кластер выберет NAT-интерфейс, и менеджер станет недоступен для воркеров.

```bash
vagrant ssh manager01

# Инициализация Swarm на статическом IP приватной сети
docker swarm init --advertise-addr 192.168.10.10
```

Команда выведет токен подключения воркеров:
```text
docker swarm join --token <SWARM_JOIN_TOKEN> 192.168.10.10:2377
```

#### Шаг 3.2. Присоединение рабочих узлов к кластеру
Откройте два отдельных терминала для подключения к воркерам и выполните сгенерированную команду:

```bash
# На узле worker01:
vagrant ssh worker01
docker swarm join --token <SWARM_JOIN_TOKEN> 192.168.10.10:2377
exit

# На узле worker02:
vagrant ssh worker02
docker swarm join --token <SWARM_JOIN_TOKEN> 192.168.10.10:2377
exit
```

#### Шаг 3.3. Проверка топологии кластера
Вернитесь на `manager01` и проверьте готовность всех трёх нод:

```bash
docker node ls
```
Все узлы должны иметь статус `Ready`, узел `manager01` — статус `Leader`.

#### Шаг 3.4. Мультиплатформенная сборка и отправка образов в реестр
Для прозрачного деплоя в распределённом кластере образы микросервисов собираются кросс-платформенно через `docker buildx` и публикуются в реестр Docker Hub:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/booking-service:1 --push ./services/booking-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/gateway-service:1 --push ./services/gateway-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/hotel-service:1 --push ./services/hotel-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/loyalty-service:1 --push ./services/loyalty-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/payment-service:1 --push ./services/payment-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/report-service:1 --push ./services/report-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/session-service:1 --push ./services/session-service
docker buildx build --platform linux/amd64,linux/arm64 -t lenyldes/nginx:1 --push ./services/nginx
```

#### Шаг 3.5. Развёртывание стека микросервисов в Swarm
На узле `manager01` в директории `/vagrant_data` разверните стек `hotel_app`:

```bash
cd /vagrant_data
docker stack deploy -c docker-compose.yml hotel_app
```

Проверьте запуск и дождитесь, пока все реплики перейдут в состояние `1/1`:

```bash
docker service ls
```

#### Шаг 3.6. Анализ распределения задач по узлам
Просмотр распределения контейнеров по виртуальным машинам с фильтрацией только работающих задач:

```bash
# Активные задачи стека hotel_app
docker stack ps --filter "desired-state=running" hotel_app

# Задачи, размещённые на конкретных узлах
docker node ps --filter "desired-state=running" manager01
docker node ps --filter "desired-state=running" worker01
docker node ps --filter "desired-state=running" worker02
```

#### Шаг 3.7. Управление масштабированием и принудительная ребалансировка
Для изменения количества реплик микросервиса используется команда `docker service scale`:

```bash
# Масштабирование сервиса бронирования до 2 реплик
docker service scale hotel_app_booking-service=2
```

При аварийном отключении одной из нод (например, `worker02`) Swarm автоматически переносит упавшие контейнеры на оставшиеся узлы (`manager01`, `worker01`). При повторном включении `worker02` Swarm соблюдает **принцип наименьшего вмешательства (Anti-Flapping)**: он не убивает стабильно работающие экземпляры ради перемещения. Для равномерного распределения нагрузки на вернувшийся узел выполняется принудительное плавное обновление:

```bash
docker service update --force hotel_app_booking-service
```

---

### 4. Развёртывание Portainer для визуального управления кластером

Для наглядного мониторинга топологии и контейнеров в Swarm разворачивается стек Portainer CE:

```bash
# На узле manager01:
cd /vagrant_data
docker stack deploy -c portainer-agent-stack.yml portainer

# Проверка готовности сервисов
docker service ls
```

#### Получение пароля первичной настройки и вход в веб-интерфейс
1. Определите ID контейнера Portainer Server:
   ```bash
   docker ps --filter "name=portainer_portainer" --format "{{.ID}}"
   ```
2. Посмотрите логи для получения ссылки и первичного ключа:
   ```bash
   docker logs <CONTAINER_ID>
   ```
3. Откройте в браузере хост-машины URL:
   ```text
   https://192.168.10.10:9443
   ```
4. Задайте пароль администратора, перейдите в раздел кластера и откройте **Swarm Visualizer** для визуального контроля распределения задач по узлам `manager01`, `worker01` и `worker02`.

---

### 5. Запуск интеграционных тестов Postman (Newman)

Тестирование функциональности REST API проводится с помощью официального Docker-образа CLI-раннера Postman — **Newman**.

#### Тестирование в локальном окружении Docker Compose:
```bash
docker run --rm -v "$(pwd)":/etc/newman --network host postman/newman run /etc/newman/application_tests.postman_collection.json
```

#### Тестирование в распределённом кластере Docker Swarm:
На узле `manager01` запустите Newman с передачей переменной `API_HOST=127.0.0.1` для гарантированного обращения по IPv4 к обратным прокси-портам Nginx (`8081` и `8087`):

```bash
docker run --rm -v "$(pwd)":/etc/newman --network host postman/newman run /etc/newman/application_tests.postman_collection.json --env-var API_HOST=127.0.0.1
```

#### Выполняемые проверки коллекции:
1. **Login User**: отправка Basic Auth заголовка на `:8081/api/v1/auth/authorize`, проверка кода `200 OK`, извлечение Bearer-токена в переменную окружения коллекции.
2. **Get Hotels**: запрос каталога отелей `:8087/api/v1/gateway/hotels` с Bearer-токеном, проверка кода `200 OK`.
3. **Get Hotel**: запрос детальной информации по UID отеля `:8087/api/v1/gateway/hotels/{{HOTEL_UID}}`, проверка кода `200 OK`.
4. **Book Hotel**: POST-запрос оформления бронирования номера `:8087/api/v1/gateway/booking` с телом JSON, проверка кода `201 Created`.
5. **Get User's Loyalty Balance**: запрос баланса бонусных баллов пользователя `:8087/api/v1/gateway/loyalty`, проверка кода `200 OK`.

*Итог тестирования: 5 из 5 запросов и assertions завершены успешно (`failed: 0`), сквозная интеграция подтверждена.*

---

### 6. Остановка и очистка окружения

```bash
# 1. Удаление стеков приложений из Docker Swarm (на manager01):
docker stack rm hotel_app
docker stack rm portainer

# 2. Вывод узлов из кластера Swarm (на каждом узле):
docker swarm leave --force

# 3. Остановка и уничтожение виртуальных машин Vagrant (на хост-машине):
vagrant halt
vagrant destroy -f

# 4. Остановка локального окружения Docker Compose (при необходимости):
docker compose down -v --rmi all
```

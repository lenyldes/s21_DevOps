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

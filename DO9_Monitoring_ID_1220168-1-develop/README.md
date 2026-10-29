# Комплексный мониторинг и наблюдаемость микросервисов: Prometheus, Grafana, Loki и Alertmanager (Microservices Observability: Prometheus, Grafana, Loki, cAdvisor, Micrometer & Alertmanager in Docker Swarm)

[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Grafana Loki](https://img.shields.io/badge/Grafana%20Loki-FF7800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/oss/loki/)
[![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/docs/alerting/latest/alertmanager/)
[![Docker Swarm](https://img.shields.io/badge/Docker%20Swarm-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/engine/swarm/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Micrometer](https://img.shields.io/badge/Micrometer-2496ED?style=for-the-badge&logo=spring&logoColor=white)](https://micrometer.io/)
[![cAdvisor](https://img.shields.io/badge/cAdvisor-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://github.com/google/cadvisor)
[![Telegram](https://img.shields.io/badge/Telegram%20Bot%20API-24A1DE?style=for-the-badge&logo=telegram&logoColor=white)](https://core.telegram.org/bots/api)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL%2016-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ%203-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)](https://www.rabbitmq.com/)
[![Postman](https://img.shields.io/badge/Postman-FF6C37?style=for-the-badge&logo=postman&logoColor=white)](https://www.postman.com/)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)](#)

Я спроектировал и развернул контур наблюдаемости (**Observability**) для микросервисной системы бронирования отелей в кластере **Docker Swarm**. Сделал так, чтобы метрики собирались на всех уровнях инфраструктуры, логи агрегировались централизованно в реальном времени, состояние компонентов отображалось на интерактивных панелях **Grafana** с декларативным провижионингом, а проактивные оповещения об инцидентах уходили через **Alertmanager** — в **Telegram** и на **Email**.

Сначала я оснастил Java‑микросервисы на Spring Boot: подключил **Spring Boot Actuator** и **Micrometer Prometheus Registry**, настроил сбор кастомных бизнес‑метрик — запросов к шлюзу, авторизаций, количества бронирований, счётчиков сообщений RabbitMQ. Потом развернул экспортёры (**node_exporter**, **cAdvisor**, **blackbox_exporter**) и организовал централизованный сбор логов контейнеров в **Grafana Loki** через официальный Docker‑плагин `loki-docker-driver`. Межсервисное взаимодействие двух стеков (`hotel_app` и `monitoring`) сделал через изолированную оверлейную сеть `do9-shared`. Дальше я развернул **Grafana** с декларативной автоматизацией (Provisioning) и собрал единый дашборд из 15 панелей — разбил их на три логических уровня: инфраструктура хоста и сети, контейнеризация cgroups, прикладные метрики плюс журнал логов. В завершение развернул **Alertmanager**, написал правила алертинга на PromQL по критическим порогам памяти и CPU, настроил маршрутизацию с группировкой и фильтрацией, протестировал каналы оповещений и зафиксировал статусы `FIRING` и `RESOLVED`.

---

## О проекте

Для современных распределённых приложений мало просто фиксировать сбои постфактум — нужна прозрачная наблюдаемость (**Observability**), чтобы быстро находить, где падает производительность, не допускать каскадных аварий и понимать, что происходит внутри системы, глядя на её внешние проявления. В этом проекте я как раз решал такие задачи для микросервисной архитектуры.

### 1. Три столпа наблюдаемости (Three Pillars of Observability)

Наблюдаемость строю на трёх взаимодополняющих источниках данных:

- **Метрики (Metrics)** — числовые временные ряды с агрегируемыми метками (Prometheus). Они показывают интенсивность событий: RPS, использование CPU/RAM, задержки. По ним я сразу вижу аномалии и настраиваю правила алертинга.
- **Логи (Logs)** — структурированные и неструктурированные текстовые записи о событиях с контекстом (Grafana Loki). Они отвечают на вопрос «почему случилась ошибка» и содержат стектрейсы и детали транзакций.
- **Трассировки (Traces)** — сквозные идентификаторы запросов между микросервисами для профилирования цепочек вызовов (APM).

В проекте я реализовал связку первых двух компонентов: по дашбордам метрик нахожу временной интервал и компонент с аномалией, а затем в Loki по тем же метаданным контейнеров подтягиваю точные сообщения об ошибках.

### 2. Сравнение Pull- и Push-моделей сбора данных

- **Pull-модель (Prometheus)**: сервер сам периодически опрашивает (*scrape*) зарегистрированные эндпоинты (`/actuator/prometheus`, `/metrics`, `/probe`) через HTTP GET. Так я держу под контролем нагрузку на сервисы, сразу вижу, если сервис недоступен (*health status* по отсутствию ответа), и централизованно управляю интервалами опроса.
- **Push-модель (Grafana Loki)**: приложения и лог‑драйверы сами отправляют пачки (*batches*) логов по HTTP POST на эндпоинт `/loki/api/v1/push`. Для логов это удобнее: они генерируются асинхронно и неравномерно.

### 3. Сбор контейнерной телеметрии ядра Linux через cgroups и cAdvisor

В контейнеризированных средах ресурсы виртуализируются через подсистемы ядра Linux **Control Groups (cgroups)** и **Namespaces**. Я поставил демон **cAdvisor** (Container Advisor): он монтирует корневую файловую систему хоста, сокет демона Docker `/var/run/docker.sock` и псевдофайловую систему `/sys/fs/cgroup`. Так я получаю показатели потребления памяти (`container_memory_usage_bytes`), тактов процессора (`container_cpu_usage_seconds_total`) и сетевого трафика для каждого контейнера с микросекундной точностью, а ещё обогащаю их Swarm‑метаданными (`container_label_com_docker_swarm_service_name`).

### 4. Стратегии сбора логов и манифест Twelve-Factor App

По разделу **XI. Logs** методологии **The Twelve-Factor App**, приложение не должно заниматься маршрутизацией и хранением логов: контейнеризированный сервис пишет вывод только в стандартные потоки `stdout` и `stderr`.

Я выбрал подход с **Loki Docker Driver**:

- Драйвер ставлю как Docker‑плагин (`loki-docker-driver`), он перехватывает вывод демона Docker и отправляет его в Loki по сети.
- Не нужно менять код микросервисов — логи одинаково собираются и у Java‑приложений, и у системных компонентов (Nginx, PostgreSQL, RabbitMQ).
- Настроил неблокирующий буферизованный режим (`mode: non-blocking`, `max-buffer-size: 4m`): если хранилище логов временно недоступно, микросервисы продолжают обслуживать запросы без задержек.

### 5. Сетевая изоляция и межстековое взаимодействие в Docker Swarm

Микросервисы приложения я развернул в стеке `hotel_app`, а подсистему мониторинга — в стеке `monitoring`. Чтобы соблюсти принцип наименьших привилегий, сделал внешнюю оверлейную сеть `do9-shared` с поддержкой распределённой маршрутизации VXLAN. Prometheus подключил сразу к двум сетям: внутренней `monitoring_default` (доступ к локальным агентам‑экспортёрам) и `do9-shared` (скрейпинг Actuator‑эндпоинтов Java‑сервисов). Базы данных и брокер сообщений не публикую наружу — они остаются защищёнными внутри кластера.

### 6. Декларативная автоматизация интерфейсов (Grafana Provisioning)

Ручной подход (*ClickOps*) нарушает принципы воспроизводимости и непрерывной доставки (IaC). Поэтому я использовал подсистему **Provisioning**: файлы `datasources.yaml`, `dashboards.yaml` и JSON‑модель дашборда `dashboard.json` монтирую в контейнер Grafana при старте. Так окружение мониторинга запускается сразу готовым — без ручных настроек.

### 7. Архитектура обработки и маршрутизации критических событий (Alertmanager)

Ключевой паттерн экосистемы Prometheus — разделить вычисление правил и доставку оповещений:

- **Prometheus Server**: регулярно считает PromQL‑правила (`evaluation_interval: 15s`). Если порог нарушается непрерывно в течение окна гистерезиса (`for: 30s`), алерт переходит из `PENDING` в `FIRING` и пачкой уходит в Alertmanager.
- **Alertmanager**: дедуплицирует события, группирует алерты по ключам (`group_by: ['alertname', 'severity']`), применяет задержки (`group_wait: 10s`, `group_interval: 30s`, `repeat_interval: 3h`) и маршрутизирует сообщения в приёмники: Email через защищённый SMTP и Telegram через Bot API.

---

## Ключевые навыки и освоенные концепции

### Part 1. Инструментирование, сбор метрик и логирование

- **Инструментирование Java Spring Boot приложений:**
  - Подключил зависимости `spring-boot-starter-actuator` и `micrometer-registry-prometheus` в `pom.xml` микросервисов (`booking-service`, `report-service`, `gateway-service`, `session-service`) через родительский POM `spring-boot-starter-parent` (2.3.3.RELEASE).
  - Настроил экспонирование эндпоинтов управления в `application.properties`: `management.endpoints.web.exposure.include=health,info,prometheus`.
  - Внедрил потокобезопасный реестр метрик `io.micrometer.core.instrument.MeterRegistry` через Spring Dependency Injection (`@Autowired`).
  - Использовал счетчики `Counter` для монотонно возрастающих бизнес‑показателей.
  - Добавил аннотацию Spring MVC `@ModelAttribute` в API Gateway, чтобы неинвазивно перехватывать все входящие HTTP‑запросы.
- **Разработка кастомных метрик:**
  - `gateway.requests.total` (`gateway-service`) — агрегированный счётчик запросов, поступивших на API Gateway.
  - `auth.requests.total` (`session-service`) — счётчик попыток аутентификации пользователей и выпуска JWT‑токенов.
  - `bookings.total` (`booking-service`) — счётчик успешно оформленных бронирований гостиничных номеров.
  - `rabbitmq.messages.sent.total` (`booking-service`) — объём сообщений со статистикой, отправленных в RabbitMQ exchange.
  - `rabbitmq.messages.processed.total` (`report-service`) — объём сообщений очереди `messagequeue`, успешно десериализованных и сохранённых сервисом отчётов.
- **Централизованное логирование на базе Grafana Loki:**
  - Развернул контейнер Grafana Loki 3.7.0 со стандартной конфигурацией `loki-config.yaml`.
  - Поставил и активировал плагин `loki-docker-driver` в Docker Engine с учётом архитектуры хоста (`arm64`/`amd64`).
  - Декларативно назначил драйвер логирования в `docker-compose.yml` через YAML Anchors (`&default-logging`) и ссылки (`*default-logging`) для 10 контейнеров стека.
  - Настроил неблокирующий режим буферизации логов `mode: non-blocking` с ограничением `max-buffer-size: 4m`.
  - Проверил потоки логов и индексируемые метки (`compose_service`, `container_name`) через REST API Loki (`/ready`, `/loki/api/v1/labels`, `/loki/api/v1/label/.../values`).
- **Стек мониторинга в Docker Swarm:**
  - Создал внешнюю оверлейную сеть `do9-shared` (`--driver overlay --attachable`).
  - Развернул экспортеры уровня хоста: `node_exporter` в режиме `deploy.mode: global` с монтированием хостового корня `/:/host:ro`.
  - Поставил `cAdvisor` в режиме `deploy.mode: global`, смонтировал сокеты Docker и containerd, а также каталоги cgroups.
  - Настроил синтетический HTTP‑мониторинг через `blackbox_exporter` с Relabeling‑конфигурацией для внешнего таргета `https://www.google.com`.
  - Прописал скрейпинг‑задачи Prometheus (`prometheus.yml`) с 15‑секундным интервалом опроса.
  - Проверил работоспособность таргетов в веб‑интерфейсе Prometheus (`:9090/targets`).

### Part 2. Визуализация и декларативный провижионинг в Grafana

- **Оркестрация Grafana:**
  - Интегрировал официальный образ `grafana/grafana` в стек мониторинга Docker Swarm.
  - Обеспечил сохранность метаданных через персистентный том `grafana-storage:/var/lib/grafana`.
  - Опубликовал веб‑интерфейс на порту `3000`.
- **Конфигурирование источников данных (Data Sources):**
  - Подключил источник Prometheus (`http://prometheus:9090`) как дефолтный провайдер метрик.
  - Добавил источник Grafana Loki (`http://loki:3100`) для агрегации журналов событий.
- **Проектирование и сборка комплексного дашборда (15 панелей):**
  - **Секция Host & Network Infrastructure:**
    1. *Количество нод* (`count(up{job="node_exporter"})`);
    2. *Количество CPU* (`count(node_cpu_seconds_total{mode="idle"})`);
    3. *Доступная и занятая память* (`node_memory_MemAvailable_bytes` и разность с `node_memory_MemTotal_bytes`);
    4. *Использование CPU по ядрам и узлам* (`(1 - rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100`);
    5. *Доступность google.com* (`probe_success{job="blackbox_check"}`).
  - **Секция cAdvisor:**
    6. *Количество контейнеров* (`count(container_last_seen{name=~".+"})` с фильтрацией псевдоконтейнеров);
    7. *Количество стеков* (`count(count by (container_label_com_docker_stack_namespace)(...))`);
    8. *Использование CPU по сервисам* (`sum by(container_label_com_docker_swarm_service_name) (rate(container_cpu_usage_seconds_total...))`);
    9. *Затраченная RAM* (`sum by(container_label_com_docker_swarm_service_name) (container_memory_usage_bytes...)`).
  - **Секция Actuator + Loki:**
    10. *Количество полученных запросов на gateway* (`sum(gateway_requests_total)`);
    11. *Количество полученных запросов на авторизацию* (`sum(auth_requests_total)`);
    12. *Количество бронирований* (`sum(bookings_total)`);
    13. *Количество сообщений, отправленных в RabbitMQ* (`sum(rabbitmq_messages_sent_total)`);
    14. *Количество сообщений, обработанных в RabbitMQ* (`sum(rabbitmq_messages_processed_total)`);
    15. *Логи приложения* (LogQL: `{swarm_stack="hotel_app"}`).
- **Grafana Provisioning (Configuration as Code):**
  - Описал источники данных в `datasources.yaml` с жёсткой фиксацией UID.
  - Настроил автоматический файловый провайдер дашбордов в `dashboards.yaml`.
  - Экспортировал и завёл в версионирование полное описание дашборда в `dashboard.json`.

### Part 3. Оповещение об инцидентах через Alertmanager

- **Развертывание Alertmanager:**
  - Запустил сервис `alertmanager` из образа `quay.io/prometheus/alertmanager` на порту `9093`.
  - Связал Prometheus и Alertmanager, добавив блок `alerting.alertmanagers` в `prometheus.yml`.
- **Проектирование правил алертинга на PromQL (`rules.yml`):**
  - Настроил правило `NodeMemoryAvailableLow`: алерт срабатывает, если доступной памяти хоста меньше 100 Мб (`node_memory_MemAvailable_bytes / 1024 / 1024 < 100`).
  - Добавил правило `NodeRAMUsageHigh`: отслеживаю превышение занятой памяти хоста более 1 Гб (`(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024 > 1`).
  - Реализовал правило `ServiceCPUUsageHigh`: фиксирую повышенную утилизацию CPU сервисом Swarm — более 10% (`sum by(...) (rate(container_cpu_usage_seconds_total...)) > 10`).
  - Прописал период стабилизации `for: 30s`, чтобы не реагировать на кратковременные всплески. Добавил аннотации с динамическими шаблонами `{{ $value }}` и `{{ $labels }}` — так в оповещениях сразу видны конкретные значения и метки.
- **Маршрутизация и каналы оповещения (`config.yml`):**
  - Настроил тайминги отправки: первичная буферизация `group_wait: 10s`, досылка алертов `group_interval: 30s`, повтор уведомлений — каждые 3 часа (`repeat_interval: 3h`).
  - Интегрировал Telegram Bot API: выпустил токен бота через `@BotFather`, получил `chat_id` через `getUpdates`, настроил HTML‑форматирование текста и включил уведомления о восстановлении (`send_resolved: true`) — теперь приходят и сигналы об аварии, и сообщения, что всё снова в норме.
  - Подключил SMTP Mail.ru: настроил защищённое SSL/TLS‑подключение на порту `465`, использовал отдельный пароль для внешних приложений и прописал отправку на свой почтовый ящик.
- **Тестирование и верификация алертов:**
  - Подтвердил штатную фиксацию алерта `NodeRAMUsageHigh` при потреблении хоста около 3.9 Гб.
  - Провёл безопасное тестирование: временно снизил пороги — для памяти поставил `< 5000 Мб`, для CPU сервисов — `> 1%`, чтобы стабильно воспроизвести срабатывание.
  - Принудительно обновил конфигурацию в Swarm командой `docker service update --force monitoring_prometheus`, чтобы изменения точно применились.
  - Проверил переход правил в статус `FIRING` в интерфейсах Prometheus (`:9090/alerts`) и Alertmanager (`:9093`).
  - Убедился, что сообщения доходят: протестировал доставку в Telegram‑бот и на почту.
  - Вернул проектные пороги правил алертинга — система теперь работает с целевыми значениями.

---

## Архитектура и стек технологий

### Архитектурная диаграмма контура мониторинга и микросервисов

|||text
+-------------------------------------------------------------------------------------------------------------------------+
|                                                 ХОСТОВАЯ СИСТЕМА (HOST)                                                 |
|                                                                                                                         |
|    +-----------------------------+     +-----------------------------+     +---------------------------------------+    |
|    |      Grafana Dashboard      |     |    Prometheus Web UI        |     |          Alertmanager Web UI          |    |
|    |    http://localhost:3000    |     |  http://localhost:9090      |     |         http://localhost:9093         |    |
|    +--------------+--------------+     +--------------+--------------+     +-------------------+-------------------+    |
|                   |                                   |                                        |                        |
+-------------------|-----------------------------------|----------------------------------------|------------------------+
                    |                                   |                                        |
====================|===================================|========================================|=========================
                    | Внутренняя сеть monitoring_default| (bridge/overlay)                       |
                    v                                   v                                        v
+-------------------------------------------------------------------------------------------------------------------------+
| СТЕК МОНИТОРИНГА (monitoring stack)                                                                                     |
|                                                                                                                         |
|   +-----------------------+              +-----------------------+            +------------------------------------+    |
|   |        Grafana        | PromQL /     |   Prometheus Server   | HTTP PUSH  |            Alertmanager            |    |
|   |       (Port 3000)     |------------->|      (Port 9090)      |----------->|            (Port 9093)             |    |
|   |  - 15 Панелей метрик  | LogQL        |  - TSDB Хранилище     | (FIRING)   |  - Дедупликация и группировка      |    |
|   |  - Provisioning       |---+          |  - Scrape Engine      |            |  - Подавление (Inhibition)         |    |
|   +-----------------------+   |          |  - Rules Evaluation   |            +------------------+-----------------+    |
|                               |          +-----------+-----------+                               |                      |
|                               |                      |                                           |                      |
|                               v                      | Scrape Targets                            |                      |
|   +-----------------------+   |                      | (15s interval)                            |                      |
|   |     Grafana Loki      |<--+                      |                                           |                      |
|   |      (Port 3100)      |                          |                                           |                      |
|   |  - Индексация меток   |                          |                                           |                      |
|   |  - Хранение chunks    |                          |                                           |                      |
|   +-----------^-----------+                          |                                           |                      |
|               |                                      v                                           |                      |
|               |              +-----------------------------------------------+                   |                      |
|               |              | Локальные системные экспортёры (Swarm Global):|                   |                      |
|               |              | - node_exporter:9100   (Host OS / CPU / RAM)  |                   |                      |
|               |              | - cadvisor:8080        (cgroups / Containers) |                   |                      |
|               |              | - blackbox_exporter:9115 (Probe google.com)   |                   |                      |
|               |              +-----------------------------------------------+                   |                      |
+---------------|--------------------------------------|-------------------------------------------|----------------------+
                |                                      |                                           |
                | Логи контейнеров                     | Pull-скрейпинг                            | Внешние каналы связи
                | (Loki Docker Driver)                 | Actuator-метрик                           |
                |                                      |                                           v
================|======================================|===================================================================
                | Внешняя оверлейная сеть: do9-shared  |                                +---------------------+
                |                                      |                                |   Telegram Bot API  |
                |                                      v                                |    (Chat / Alerts)  |
+---------------|-------------------------------------------------------------------+   +---------------------+
| СТЕК ПРИЛОЖЕНИЯ (hotel_app stack)                                                 |              ^
|                                                                                   |              |
|   +-----------+-----------+                     +-----------------------------+   |              |
|   |      nginx-proxy      |                     |       gateway-service       |   |              |
|   |   (Ports 8081, 8087)  |                     |         (Port 8087)         |   |              |
|   +-----------+-----------+                     |  - gateway.requests.total   |   |   +----------+----------+
|               |                                 +-----------------------------+   |   |   SMTP Mail.ru:465  |
|               v                                                |                  |   |    (Email Alerts)   |
|   +-----------------------+                     +--------------v--------------+   |   +---------------------+
|   |    session-service    |                     |       booking-service       |   |
|   |      (Port 8081)      |                     |         (Port 8083)         |   |
|   | - auth.requests.total |                     |  - bookings.total           |   |
|   +-----------------------+                     |  - rabbitmq.messages.sent   |   |
|                                                 +--------------+--------------+   |
|                                                                |                  |
|   +-----------------------+                     +--------------v--------------+   |
|   |      PostgreSQL       |                     |          RabbitMQ           |   |
|   |      (Port 5432)      |                     |         (Port 5672)         |   |
|   |  - 6 баз данных       |                     |  - messagequeue exchange    |   |
|   +-----------------------+                     +--------------+--------------+   |
|                                                                |                  |
|   +-----------------------+   +-----------------------+        v                  |
|   |     hotel-service     |   |    payment-service    | +---------------------+   |
|   |      (Port 8082)      |   |      (Port 8084)      | |   report-service    |   |
|   +-----------------------+   +-----------------------+ |     (Port 8086)     |   |
|                                                         | - rabbitmq.messages |   |
|   +---------------------------------------------------+ |   .processed.total  |   |
|   | loyalty-service (Port 8085)                       | +---------------------+   |
|   +---------------------------------------------------+                           |
+-----------------------------------------------------------------------------------+
|||

---

### Спецификация компонентов контура мониторинга

| Имя сервиса | Базовый Docker-образ | Режим оркестрации | Порты (Host -> Container) | Подключённые сети | Назначение и зона ответственности |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **prometheus** | `prom/prometheus:latest` | `replicated` (1) | `9090:9090` | `monitoring_default`, `do9-shared` | Центральный сервер метрик, TSDB-хранилище, скрейпинг таргетов, вычисление PromQL-правил |
| **grafana** | `grafana/grafana:latest` | `replicated` (1) | `3000:3000` | `monitoring_default` | Визуализация метрик и логов, 15 панелей дашборда, файловый Provisioning |
| **loki** | `grafana/loki:3.7.0` | `replicated` (1) | `3100:3100` | `monitoring_default` | Сбор и индексация потоков логов от контейнеров через HTTP Push API |
| **alertmanager**| `quay.io/prometheus/alertmanager` | `replicated` (1) | `9093:9093` | `monitoring_default` | Приём алертов от Prometheus, дедупликация, отправка в Telegram и Email |
| **node_exporter** | `quay.io/prometheus/node-exporter:latest` | `global` (1 на узел) | — (внутренний `9100`) | `monitoring_default` | Сбор аппаратных метрик хоста (CPU, RAM, диски, сеть) через `/host` |
| **cadvisor** | `ghcr.io/google/cadvisor:latest` | `global` (1 на узел) | — (внутренний `8080`) | `monitoring_default` | Анализ cgroups контейнеров, сбор метрик памяти и процессора с метками Swarm |
| **blackbox_exporter** | `quay.io/prometheus/blackbox-exporter:latest` | `replicated` (1) | — (внутренний `9115`) | `monitoring_default` | Синтетический сетевой пробинг (HTTP 2xx) доступности `https://www.google.com` |

---

### Спецификация микросервисов приложения (`hotel_app`)

| Имя сервиса | Порт сервиса | Внутренний эндпоинт Actuator | Специфические метрики Micrometer | Назначение в архитектуре |
| :--- | :---: | :--- | :--- | :--- |
| **nginx-proxy** | `8081`, `8087` | — | Логирование запросов через Loki | Входной реверс-прокси Nginx, точка входа для внешних клиентов |
| **gateway-service** | `8087` | `http://gateway-service:8087/actuator/prometheus` | `gateway_requests_total` | API Gateway, маршрутизация трафика, авторизация через сессии |
| **session-service** | `8081` | `http://session-service:8081/actuator/prometheus` | `auth_requests_total` | Управление пользователями, авторизация, выпуск JWT-токенов |
| **booking-service** | `8083` | `http://booking-service:8083/actuator/prometheus` | `bookings_total`<br>`rabbitmq_messages_sent_total` | Сервис оформления бронирований, координация транзакций, отправка статистики в очередь |
| **report-service** | `8086` | `http://report-service:8086/actuator/prometheus` | `rabbitmq_messages_processed_total` | Приём сообщений из RabbitMQ, сохранение аналитики и агрегированных отчётов |
| **hotel-service** | `8082` | — | Сбор логов в Loki | Каталог гостиниц, номеров и доступности дат |
| **payment-service**| `8084` | — | Сбор логов в Loki | Процессинг платежей и биллинг операций бронирования |
| **loyalty-service**| `8085` | — | Сбор логов в Loki | Учёт баланса баллов и клиентской программы лояльности |
| **postgres** | `5432` | — | Сбор логов в Loki | СУБД PostgreSQL 16 с шестью изолированными базами данных |
| **rabbitmq** | `5672` | — | Сбор логов в Loki | Брокер сообщений RabbitMQ (Exchange `messagequeue-exchange`) |

---

### Сводная таблица используемых технологий и инструментов

| Категория | Инструмент / Компонент | Версия / Релиз | Назначение в проекте |
| :--- | :--- | :--- | :--- |
| **Оркестрация контейнеров** | Docker Engine & Docker Swarm | 26.x+ | Кластеризация, управление сервисами, оверлейная сеть VXLAN |
| **Сбор метрик и TSDB** | Prometheus Server | latest | Скрейпинг таргетов, хранилище временных рядов, PromQL-движок |
| **Сбор и агрегация логов** | Grafana Loki | 3.7.0 | Высокопроизводительное хранение логов без полнотекстового индекса |
| **Драйвер логирования** | Loki Docker Driver | 3.7.0 (arm64/amd64) | Перехват stdout/stderr контейнеров демоном Docker и отправка в Loki |
| **Визуализация данных** | Grafana OSS | latest | Построение дашбордов, графиков, визуализация потоков LogQL |
| **Контейнерная телеметрия** | Google cAdvisor | latest | Анализ cgroups ядра, метрики нагрузки контейнеров и стеков Swarm |
| **Хостовая телеметрия** | Prometheus Node Exporter | latest | Метрики операционной системы хоста (память, ядра CPU, диски, сеть) |
| **Синтетический мониторинг** | Prometheus Blackbox Exporter | latest | Внешняя проверка сетевой доступности (`https://www.google.com`) |
| **Маршрутизация алертов** | Prometheus Alertmanager | latest | Дедупликация, группировка и доставка оповещений об авариях |
| **Каналы оповещения** | Telegram Bot API / Mail.ru SMTP | HTTPS / SSL 465 | Мобильные уведомления в Telegram-чат и почтовые алерты на Email |
| **Инструментирование Java** | Spring Boot Actuator / Micrometer | 2.3.3.RELEASE | Экспонирование системных и кастомных счетчиков в формате Prometheus |
| **Стек приложений** | Spring Boot, PostgreSQL, RabbitMQ | Java 21 / PG 16 / RMQ 3 | Микросервисная распределенная система бронирования отелей |
| **Автоматизация тестов** | Postman / Newman CLI | Schema 2.1.0 | Эмуляция пользовательской нагрузки и проверка бизнес-метрик |

---

## Структура проекта и реализованные модули

Исходный код микросервисов, манифесты оркестрации и файлы конфигурации мониторинга расположены в каталоге `src/`:

|||text
.
├── README.md                                             # Комплексная документация проекта (текущий файл)
└── src/
    ├── REPORT.md                                         # Детальный инженерный отчет с иллюстрациями
    ├── screenshot/                                       # Снимки экранов верификации всех этапов работ
    ├── monitoring/                                       # Инфраструктура стека мониторинга
    │   ├── docker-compose.yml                            # Спецификация стека monitoring в Docker Swarm
    │   ├── prometheus/                                   # Конфигурация Prometheus Server
    │   │   ├── prometheus.yml                            # Скрейпинг таргетов, интервалы, интеграция Alertmanager
    │   │   └── rules.yml                                 # Правила алертинга PromQL (RAM, MemAvailable, CPU)
    │   ├── loki/                                         # Конфигурация Grafana Loki
    │   │   └── loki-config.yaml                          # Параметры инджестеров, хранилища и ретеншена
    │   ├── grafana/                                      # Декларативная конфигурация Grafana Provisioning
    │   │   └── provisioning/
    │   │       ├── datasources/
    │   │       │   └── datasources.yaml                  # Автоподключение источников Prometheus и Loki
    │   │       └── dashboards/
    │   │           ├── dashboards.yaml                   # Провайдер файловой загрузки дашбордов
    │   │           └── dashboard.json                    # Модель дашборда со всеми 15 панелями метрик
    │   └── alertmanager/                                 # Конфигурация Alertmanager
    │       └── config.yml                                # Маршрутизация алертов, SMTP Mail.ru и Telegram Bot
    └── services/                                         # Исходный код и стек микросервисов приложения
        ├── docker-compose.yml                            # Спецификация стека hotel_app с подключением Loki
        ├── application_tests.postman_collection.json     # Коллекция сквозных интеграционных тестов Postman
        ├── nginx/                                        # Конфигурация Nginx Reverse Proxy
        ├── database/                                     # SQL-скрипты инициализации баз данных (init.sql)
        ├── gateway-service/                              # Микросервис API Gateway (метрика gateway_requests_total)
        ├── session-service/                              # Сервис аутентификации (метрика auth_requests_total)
        ├── booking-service/                              # Сервис бронирования (bookings_total, rabbitmq.sent)
        ├── report-service/                               # Сервис аналитики (rabbitmq.messages.processed)
        ├── hotel-service/                                # Каталог отелей
        ├── payment-service/                              # Платежный сервис
        └── loyalty-service/                              # Программа лояльности
|||

---

### Сводная таблица ключевых конфигурационных файлов

| Относительный путь к файлу | Назначение и зона ответственности | Ключевые параметры и директивы |
| :--- | :--- | :--- |
| [./src/REPORT.md](./src/REPORT.md) | Полный технический отчет по всем частям задания | Описание архитектуры, команды, разбор листингов, скриншоты верификации |
| [./src/monitoring/docker-compose.yml](./src/monitoring/docker-compose.yml) | Манифест оркестрации стека мониторинга | Сервисы `prometheus`, `grafana`, `loki`, `alertmanager`, `cadvisor`, `node_exporter`, `blackbox_exporter` |
| [./src/services/docker-compose.yml](./src/services/docker-compose.yml) | Манифест микросервисного стека `hotel_app` | 10 сервисов, шаблон `x-logging: &default-logging`, внешняя сеть `do9-shared` |
| [./src/monitoring/prometheus/prometheus.yml](./src/monitoring/prometheus/prometheus.yml) | Главная конфигурация Prometheus Server | `scrape_interval: 15s`, `alerting.alertmanagers`, `rule_files: rules.yml`, jobs: `prometheus`, `node_exporter`, `cadvisor`, `blackbox_check`, `hotel-services` |
| [./src/monitoring/prometheus/rules.yml](./src/monitoring/prometheus/rules.yml) | Правила алертинга PromQL | Группа `DO9`, алерты `NodeMemoryAvailableLow` (<100MB), `NodeRAMUsageHigh` (>1GB), `ServiceCPUUsageHigh` (>10%), `for: 30s`, `severity: critical` |
| [./src/monitoring/alertmanager/config.yml](./src/monitoring/alertmanager/config.yml) | Конфигурация маршрутизации Alertmanager | Ресивер `DO9_alert`, тайминги `group_wait: 10s`, `repeat_interval: 3h`, `telegram_configs` (bot token, chat_id, HTML), `email_configs` (SMTP `smtp.mail.ru:465`, TLS) |
| [./src/monitoring/loki/loki-config.yaml](./src/monitoring/loki/loki-config.yaml) | Конфигурационный файл Grafana Loki | Настройки компонентов `auth_enabled: false`, `server`, `common`, `schema_config`, `storage_config` |
| [./src/monitoring/grafana/provisioning/datasources/datasources.yaml](./src/monitoring/grafana/provisioning/datasources/datasources.yaml) | Автоматическое подключение Data Sources | Описание источников `Prometheus` (`http://prometheus:9090`, default) и `Loki` (`http://loki:3100`) с фиксированными UID |
| [./src/monitoring/grafana/provisioning/dashboards/dashboards.yaml](./src/monitoring/grafana/provisioning/dashboards/dashboards.yaml) | Провайдер автоматической загрузки дашбордов | Определение провайдера `default`, путь `/etc/grafana/provisioning/dashboards` |
| [./src/monitoring/grafana/provisioning/dashboards/dashboard.json](./src/monitoring/grafana/provisioning/dashboards/dashboard.json) | Модель дашборда Grafana (JSON Schema) | 15 панелей (Stat, Time series, Logs), 3 строки (Host Infrastructure, cAdvisor, Actuator + Loki) |

---

## Инструкция по сборке, тестированию и запуску

### 1. Системные требования к хост-окружению
- **Операционная система:** Linux (Ubuntu 20.04/22.04/24.04 LTS) или macOS (с установленным Docker Desktop);
- **Docker Engine:** версия `>= 24.0`;
- **Сетевые утилиты:** `curl`, `wget`, `jq`;
- **Свободная оперативная память (RAM):** минимум 4–6 ГБ (для одновременной работы 10 сервисов приложения и 7 сервисов стека мониторинга).

---

### 2. Подготовка сетевой инфраструктуры и запуск Docker Swarm

1. Клонируйте репозиторий и перейдите в корневую директорию проекта DO9:
   |||bash
   cd DO9_Monitoring_ID_1220168-1-develop/src
   |||

2. Инициализируйте кластер Docker Swarm на текущем узле (если еще не инициализирован):
   |||bash
   docker swarm init
   |||

3. Создайте внешнюю подключаемую оверлейную сеть для безопасного межсервисного взаимодействия:
   |||bash
   docker network create do9-shared --driver overlay --attachable
   |||

---

### 3. Установка плагина Loki Docker Driver и запуск хранилища логов

1. Установите официальный плагин драйвера логирования в Docker Engine (выберите команду в соответствии с архитектурой процессора хоста):
   - **Для Apple Silicon / ARM64:**
     |||bash
     docker plugin install grafana/loki-docker-driver:3.7.0-arm64 --alias loki --grant-all-permissions
     |||
   - **Для x86_64 / AMD64:**
     |||bash
     docker plugin install grafana/loki-docker-driver:3.7.0-amd64 --alias loki --grant-all-permissions
     |||

2. Проверьте активность плагина в выводе списка плагинов:
   |||bash
   docker plugin ls
   # Убедитесь, что для псевдонима 'loki' значение ENABLED равно 'true'
   |||

---

### 4. Сборка и развертывание микросервисов (`hotel_app`)

1. Выполните сборку образов микросервисов с внедренными Actuator-эндпоинтами:
   |||bash
   docker build -t lenyldes/session-service:1 ./services/session-service
   docker build -t lenyldes/gateway-service:1 ./services/gateway-service
   docker build -t lenyldes/booking-service:1 ./services/booking-service
   docker build -t lenyldes/report-service:1 ./services/report-service
   |||

2. Разверните стек микросервисов в Docker Swarm:
   |||bash
   docker stack deploy -c ./services/docker-compose.yml hotel_app
   |||

3. Дождитесь выхода всех сервисов в рабочее состояние (`1/1` реплик):
   |||bash
   docker stack services hotel_app
   |||

---

### 5. Развертывание контура мониторинга (`monitoring`)

1. Разверните полный стек мониторинга (Prometheus, Grafana, Loki, Alertmanager, cAdvisor, Node Exporter, Blackbox Exporter):
   |||bash
   docker stack deploy -c ./monitoring/docker-compose.yml monitoring
   |||

2. Проверьте статус запуска сервисов мониторинга:
   |||bash
   docker stack services monitoring
   |||
   Все сервисы должны успешно запуститься и перейти в состояние готовности (`1/1` для replicated и `1/1` для global).

3. Проверьте статус готовности сервиса Loki:
   |||bash
   curl -i http://localhost:3100/ready
   # Ожидаемый ответ: HTTP/1.1 200 OK (ready)
   |||

4. Проверьте регистрацию меток микросервисов в Loki через API:
   |||bash
   curl -s http://localhost:3100/loki/api/v1/label/compose_service/values | jq .
   |||
   В ответе должны присутствовать все сервисы приложения (`booking-service`, `gateway-service`, `rabbitmq`, `postgres` и др.).

---

### 6. Проверка таргетов в веб-интерфейсе Prometheus

1. Откройте в веб-браузере страницу таргетов Prometheus:
   |||text
   http://localhost:9090/targets
   |||

2. Убедитесь, что все 5 пулов скрейпинга находятся в состоянии **UP** (зеленый статус):
   - `blackbox_check` (`1/1 UP`) — доступность `https://www.google.com`;
   - `cadvisor` (`1/1 UP`) — сбор контейнерной телеметрии cgroups;
   - `hotel-services` (`4/4 UP`) — Actuator-эндпоинты микросервисов бронирования;
   - `node_exporter` (`1/1 UP`) — метрики аппаратных ресурсов хоста;
   - `prometheus` (`1/1 UP`) — внутренняя телеметрия ядра Prometheus.

---

### 7. Генерация нагрузки и валидация бизнес-метрик через Newman CLI

Для проверки монотонного возрастания счетчиков Micrometer выполните прогон интеграционной коллекции тестов Postman:

1. Зафиксируйте начальные значения счетчиков метрик:
   |||bash
   echo "=== auth_requests_total ==="
   curl -s http://localhost:8081/actuator/prometheus | grep -E '^auth_requests_total'

   echo "=== gateway_requests_total ==="
   curl -s http://localhost:8087/actuator/prometheus | grep -E '^gateway_requests_total'
   |||

2. Запустите консольный раннер Newman в эфемерном Docker-контейнере:
   |||bash
   docker run --rm \
     -v "$(pwd)/services":/etc/newman \
     --network host \
     postman/newman run /etc/newman/application_tests.postman_collection.json
   |||

3. Повторно снимите значения счетчиков метрик:
   |||bash
   echo "=== auth_requests_total (после тестов) ==="
   curl -s http://localhost:8081/actuator/prometheus | grep -E '^auth_requests_total'

   echo "=== gateway_requests_total (после тестов) ==="
   curl -s http://localhost:8087/actuator/prometheus | grep -E '^gateway_requests_total'
   |||
   Значения счетчиков увеличиваются строго в соответствии с выполненными сценариями.

---

### 8. Работа с дашбордом в веб-интерфейсе Grafana

1. Откройте в браузере стартовую страницу Grafana:
   |||text
   http://localhost:3000
   |||
   *(Учетные данные по умолчанию: логин `admin`, пароль `admin`)*.

2. Перейдите в раздел **Dashboards**: благодаря механизму Grafana Provisioning автоматически загрузится комплексный дашборд.
3. Ознакомьтесь с показаниями 15 панелей:
   - **Host & Network Infrastructure:** утилизация процессорных ядер, динамика RAM, доступность внешнего ресурса `google.com`;
   - **cAdvisor:** потребление ресурсов памяти и процессора в разрезе Swarm-сервисов, общее количество активных контейнеров и стеков;
   - **Actuator + Loki:** динамика бизнес-показателей (бронирования, сообщения очереди RabbitMQ, запросы к шлюзу) и интерактивный просмотр логов приложения.

---

### 9. Проверка подсистемы алертинга Alertmanager

1. **Проверка штатного срабатывания алерта `NodeRAMUsageHigh`:**
   - Откройте в браузере веб-интерфейс Prometheus на вкладке алертов: `http://localhost:9090/alerts`;
   - Правило `NodeRAMUsageHigh` переходит в статус `FIRING` (потребление оперативной памяти превышает установленный порог в 1 ГБ);
   - Откройте интерфейс Alertmanager: `http://localhost:9093` — алерт отображается в активной группе `DO9_alert`;
   - Проверьте входящие сообщения в Telegram-боте и почтовом ящике Mail.ru — доставлены подробные отчеты об инциденте.

2. **Комплексное тестирование порогов (`NodeMemoryAvailableLow`, `ServiceCPUUsageHigh`):**
   - Для безопасного тестирования временно скорректируйте пороги в `monitoring/prometheus/rules.yml`:
     - порог доступной памяти хоста: `< 5000` Мб;
     - порог использования CPU сервисом: `> 1` %.
   - Примените обновленную конфигурацию с принудительным обновлением сервиса:
     |||bash
     docker service update --force monitoring_prometheus
     |||
   - Убедитесь, что все три правила перешли в статус `FIRING` в интерфейсе Prometheus;
   - Проверьте доставку сводных уведомлений в Telegram и на Email.

3. **Возврат проектных настроек:**
   - Верните параметры в `monitoring/prometheus/rules.yml` к исходным проектным значениям:
     - `NodeMemoryAvailableLow`: порог `< 100` Мб;
     - `ServiceCPUUsageHigh`: порог `> 10` %.
   - Примените изменения:
     |||bash
     docker service update --force monitoring_prometheus
     |||

---

### 10. Остановка и удаление окружения

После завершения работы освободите системные ресурсы хоста:

1. Удалите стек микросервисов и стек мониторинга:
   |||bash
   docker stack rm hotel_app
   docker stack rm monitoring
   |||

2. Удалите внешнюю оверлейную сеть:
   |||bash
   docker network rm do9-shared
   |||

3. При необходимости отключите Swarm-режим на узле:
   |||bash
   docker swarm leave --force
   |||

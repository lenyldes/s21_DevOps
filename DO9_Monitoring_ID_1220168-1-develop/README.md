# Комплексный мониторинг и наблюдаемость микросервисов.

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

Я спроектировал и развернул контур наблюдаемости (**Observability**) для микросервисной системы бронирования отелей в кластере **Docker Swarm**. Сделал так, чтобы метрики собирались на всех уровнях инфраструктуры, логи агрегировались централизованно в реальном времени, состояние компонентов отображалось на интерактивных панелях **Grafana** с декларативным провижионингом, а проактивные оповещения об инцидентах уходили через **Alertmanager** — в **Telegram** и на **Email**.\

Сначала я оснастил Java‑микросервисы на Spring Boot: подключил **Spring Boot Actuator** и **Micrometer Prometheus Registry**, настроил сбор кастомных бизнес‑метрик — запросов к шлюзу, авторизаций, количества бронирований, счётчиков сообщений RabbitMQ. Потом развернул экспортёры (**node_exporter**, **cAdvisor**, **blackbox_exporter**) и организовал централизованный сбор логов контейнеров в **Grafana Loki** через официальный Docker‑плагин `loki-docker-driver`. \
Межсервисное взаимодействие двух стеков (`hotel_app` и `monitoring`) сделал через изолированную оверлейную сеть `do9-shared`. \
Дальше я развернул **Grafana** с декларативной автоматизацией (Provisioning) и собрал единый дашборд из 15 панелей — разбил их на три логических уровня: инфраструктура хоста и сети, контейнеризация cgroups, прикладные метрики плюс журнал логов. \
В завершение развернул **Alertmanager**, написал правила алертинга на PromQL по критическим порогам памяти и CPU, настроил маршрутизацию с группировкой и фильтрацией, протестировал каналы оповещений и зафиксировал статусы `FIRING` и `RESOLVED`.

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
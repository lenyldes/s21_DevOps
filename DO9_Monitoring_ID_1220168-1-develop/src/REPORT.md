# Мониторинг

Инструменты мониторинга для отслеживания метрик и критических ситуаций.

## Оглавление

1. [Part 1. Получение метрик и логов](#part-1-получение-метрик-и-логов)
   - 1.1. [Развертывание кластера и стека сервисов в Docker Swarm](#11-развертывание-кластера-и-стека-сервисов-в-docker-swarm)
   - 1.2. [Сбор метрик приложения с помощью библиотеки Micrometer](#12-сбор-метрик-приложения-с-помощью-библиотеки-micrometer)
     - 1.2.1. [Подключение инфраструктуры метрик (Spring Boot Actuator и Micrometer)](#121-подключение-инфраструктуры-метрик-spring-boot-actuator-и-micrometer)
     - 1.2.2. [Реализация сбора кастомных метрик приложения](#122-реализация-сбора-кастомных-метрик-приложения)
       - 1.2.2.1. [Количество полученных запросов на авторизацию пользователей (session-service)](#1221-количество-полученных-запросов-на-авторизацию-пользователей-session-service)
       - 1.2.2.2. [Количество полученных запросов на gateway (gateway-service)](#1222-количество-полученных-запросов-на-gateway-gateway-service)
       - 1.2.2.3. [Сбор метрик бронирования и очередей RabbitMQ. Комплексная проверка](#1223-сбор-метрик-бронирования-и-очередей-rabbitmq-комплексная-проверка)
   - 1.3. [Сбор логов приложения с помощью Grafana Loki](#13-сбор-логов-приложения-с-помощью-grafana-loki)
     - [Развертывание и проверка готовности сервиса Grafana Loki](#развертывание-и-проверка-готовности-сервиса-grafana-loki)
     - [Установка и настройка плагина Loki Docker Driver](#установка-и-настройка-плагина-loki-docker-driver)
     - [Настройка сбора логов микросервисов и проверка данных в Loki](#настройка-сбора-логов-микросервисов-и-проверка-данных-в-loki)
   - 1.4. [Развертывание стека мониторинга в Docker Swarm](#14-развертывание-стека-мониторинга-в-docker-swarm)
     - [Архитектура и компоненты контура наблюдаемости](#архитектура-и-компоненты-контура-наблюдаемости)
     - [Организация межсервисного сетевого взаимодействия](#организация-межсервисного-сетевого-взаимодействия)
     - [Конфигурация Prometheus Server (prometheus.yml)](#конфигурация-prometheus-server-prometheusyml)
     - [Конфигурация Compose-файла стека мониторинга (docker-compose.yml)](#конфигурация-compose-файла-стека-мониторинга-docker-composeyml)
     - [Развертывание стеков и проверка работоспособности в веб-интерфейсе Prometheus](#развертывание-стеков-и-проверка-работоспособности-в-веб-интерфейсе-prometheus)
2. [Part 2. Визуализация](#part-2-визуализация)
   - 2.1. [Развертывание сервиса Grafana в стеке мониторинга](#21-развертывание-сервиса-grafana-в-стеке-мониторинга)
   - 2.2. [Подключение источников данных (Data Sources)](#22-подключение-источников-данных-data-sources)
   - 2.3. [Создание и настройка дашборда мониторинга](#23-создание-и-настройка-дашборда-мониторинга)
     - 2.3.1. [Метрики инфраструктуры хоста и сети (Host & Network Infrastructure)](#231-метрики-инфраструктуры-хоста-и-сети-host--network-infrastructure)
     - 2.3.2. [Метрики контейнеризации cAdvisor](#232-метрики-контейнеризации-cadvisor)
     - 2.3.3. [Бизнес-метрики приложения и логи (Actuator + Loki)](#233-бизнес-метрики-приложения-и-логи-actuator--loki)
   - 2.4. [Автоматизация конфигурации через Grafana Provisioning](#24-автоматизация-конфигурации-через-grafana-provisioning)
3. [Part 3. Отслеживание критических событий](#part-3-отслеживание-критических-событий)
   - 3.1. [Развертывание Alertmanager в стеке мониторинга](#31-развертывание-alertmanager-в-стеке-мониторинга)
   - 3.2. [Настройка правил алертинга Prometheus (Alerting Rules)](#32-настройка-правил-алертинга-prometheus-alerting-rules)
   - 3.3. [Конфигурация роутинга и каналов оповещения (Email и Telegram)](#33-конфигурация-роутинга-и-каналов-оповещения-email-и-telegram)
   - 3.4. [Тестирование и верификация доставки алертов](#34-тестирование-и-верификация-доставки-алертов)

---

## Part 1. Получение метрик и логов

### 1.1. Развертывание кластера и стека сервисов в Docker Swarm

- Согласно требованиям первого задания, используется Docker Swarm — инфраструктура оркестрации взята из проекта DO7_Docker_Compose.
- В директорию `src/` помещены файл конфигурации `docker-compose.yml` и сами микросервисы приложения.

```bash
. (src)
├── docker-compose.yml
└── services
    ├── booking-service
    ├── database
    ├── gateway-service
    ├── hotel-service
    ├── loyalty-service
    ├── nginx
    ├── payment-service
    ├── report-service
    └── session-service
```

- Инициализируем Swarm-режим (если ещё не инициализирован) и разворачиваем стек сервисов командой `docker stack deploy`:

```sh
docker swarm init
docker stack deploy -c docker-compose.yml hotel_app
```

- Проверяем, что развёртывание прошло успешно и все реплики сервисов готовы (`1/1`):

```sh
docker service ls
```

> Развертывание стека hotel_app в Docker Swarm и проверка статуса сервисов \
![Статус сервисов стека](<screenshot/Screenshot 2026-09-09 at 11.28.15.png>)

---

### 1.2. Сбор метрик приложения с помощью библиотеки Micrometer

#### 1.2.1. Подключение инфраструктуры метрик (Spring Boot Actuator и Micrometer)

##### Аудит кодовой базы и распределение метрик

Перед модификацией исходного кода проведён статический анализ всех микросервисов в каталоге `src/services/` — нужно было определить классы и методы, отвечающие за события, указанные в задании.

Сводная таблица распределения метрик по микросервисам:

| № | Требуемая метрика | Целевой сервис | Класс / Метод интеграции | Название метрики |
|---|-------------------|----------------|--------------------------|------------------|
| 1 | Количество отправленных сообщений в RabbitMQ | `booking-service` | `QueueProducer.java` (`putStatistics`) | `rabbitmq.messages.sent.total` |
| 2 | Количество обработанных сообщений в RabbitMQ | `report-service` | `QueueConsumer.java` (`processMessage`) | `rabbitmq.messages.processed.total` |
| 3 | Количество бронирований | `booking-service` | `BookingController.java` (`bookHotel`) | `bookings.total` |
| 4 | Количество полученных запросов на gateway | `gateway-service` | `GatewayController.java` (`countRequests`) | `gateway.requests.total` |
| 5 | Количество полученных запросов на авторизацию пользователей | `session-service` | `SessionController.java` (`authorize`) | `auth.requests.total` |

---

##### Архитектура сбора метрик: Spring Boot Actuator и Micrometer

Prometheus собирает метрики по **Pull-модели**: периодически опрашивает каждый сервис через HTTP-скрейпинг по заданному пути. Чтобы связать Java-приложения на Spring Boot с Prometheus, нужны два инструмента:

1. **Spring Boot Actuator (`spring-boot-starter-actuator`)** — встроенная подсистема Spring Boot, открывающая технические эндпоинты телеметрии (`/actuator/health`, `/actuator/info`, `/actuator/metrics`).
2. **Micrometer Prometheus Registry (`micrometer-registry-prometheus`)** — адаптер-фасад, преобразующий счётчики и таймеры JVM в текстовый формат Prometheus с поддержкой метаданных (`# HELP`, `# TYPE`, labels).

> **Справка: Управление зависимостями в Maven (`<parent>` vs `<dependencies>`)** \
> В файлах `pom.xml` микросервисов уже подключен родительский POM `spring-boot-starter-parent` версии `2.3.3.RELEASE`. Наличие `<parent>` обеспечивает централизованное управление версиями (*Dependency Management*), но само по себе **не добавляет** библиотеки в приложение. Артефакты Actuator и Micrometer нужно явно объявить в секции `<dependencies>`, при этом указывать `<version>` не требуется — Maven автоматически согласует её с версией родительского Spring Boot.

- В файлы `pom.xml` четырёх целевых сервисов (`booking-service`, `report-service`, `gateway-service`, `session-service`) добавляем зависимости:

```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>
```

- По умолчанию Spring Boot Actuator скрывает веб-эндпоинты от внешних запросов (доступен только `/health`). Чтобы открыть `/actuator/prometheus`, добавляем в `src/main/resources/application.properties` каждого из четырёх сервисов:

```properties
management.endpoints.web.exposure.include=health,info,prometheus
```

> Конфигурация зависимостей в pom.xml и параметров application.properties \
![Конфигурация зависимостей](<screenshot/Screenshot 2026-09-09 at 11.32.08.png>)

---

#### 1.2.2. Реализация сбора кастомных метрик приложения

Для сбора метрик используется потокобезопасный объект `Counter` из библиотеки Micrometer — он предназначен для монотонно возрастающих значений.

> **Справка: Inversion of Control в Spring Boot vs ручное создание реестра** \
> В Spring Boot реестр метрик создаётся автоматически при запуске приложения и связывается с веб-эндпоинтом Actuator. Если создать реестр вручную через `new SimpleMeterRegistry()`, получится изолированный объект в памяти: инкременты будут идти в него, а эндпоинт `/actuator/prometheus` будет возвращать нулевые или дефолтные значения. \
> Поэтому реестр внедряется через стандартный механизм DI в Spring — аннотацией `@Autowired private MeterRegistry registry;`.

---

##### 1.2.2.1. Количество полученных запросов на авторизацию пользователей (`session-service`)

В контроллер `SessionController.java` внедрён системный реестр `MeterRegistry`, а в методе обработки запросов на получение JWT-токена `/api/v1/auth/authorize` добавлен инкремент счётчика `auth.requests.total`.

Листинг изменённого контроллера `services/session-service/.../SessionController.java`:

```java
package com.s21.devops.sample.sessionservice.Controller;

// ... существующие импорты ...
import io.micrometer.core.instrument.MeterRegistry;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/v1/auth")
public class SessionController {
    /// ...

    @Autowired
    private MeterRegistry registry;

    @GetMapping("/authorize")
    public ResponseEntity<Void> authorize(@RequestHeader("authorization") String authorization)
            throws InvalidKeySpecException, NoSuchAlgorithmException, EntityNotFoundException, RoleNotFoundException {
        
        // Фиксация входящей попытки авторизации
        registry.counter("auth.requests.total").increment();
        
        String jwtToken = sessionService.authorize(authorization);
        return ResponseEntity.ok().header("Authorization", "Bearer " + jwtToken).header("Access-Control-Expose-Headers", "authorization").build();
    }
    
    // ... остальные методы контроллера ...
}
```

---

#### Сборка, тестирование и отладка `session-service`

Проверим, что всё подключилось и метрики корректно отдаются.

Пересобираем Docker-образ микросервиса:

```sh
docker build -t lenyldes/session-service:1 ./services/session-service
```

Перезапускаем сервисы `session-service` и `nginx-proxy`:

```sh
docker compose up -d --force-recreate session-service nginx-proxy
```

- Проверяем доступность эндпоинта метрик через Nginx:

```sh
curl -s -i http://localhost:8081/actuator/prometheus | head -3
```

Сервер возвращает `HTTP/1.1 200 OK`.

- Эмулируем запросы на авторизацию с тестовыми учётными данными:

```sh
curl -s -i -H "Authorization: Basic VXNlcjpxd2VydHk=" http://localhost:8081/api/v1/auth/authorize | grep -e "Authorization" -e "200"
```

Сервер возвращает `HTTP/1.1 200 OK` и JWT-токен в заголовке `Authorization`.

- Проверяем значение счётчика в Prometheus-эндпоинте:

```sh
curl -s http://localhost:8081/actuator/prometheus | grep auth_requests_total
```

Вывод:

```text
# HELP auth_requests_total  
# TYPE auth_requests_total counter
auth_requests_total 18.0
```

После двух дополнительных запросов значение счётчика корректно увеличивается до `20.0`.
```sh
curl -s -H "Authorization: Basic VXNlcjpxd2VydHk=" http://localhost:8081/api/v1/auth/authorize
```

> Проверка фиксации метрики auth_requests_total при запросах авторизации \
![Метрика auth_requests_total](<screenshot/Screenshot 2026-09-09 at 11.48.31.png>)

---

##### 1.2.2.2. Количество полученных запросов на gateway (`gateway-service`)

API Gateway — единая точка входа для внешних клиентов, содержит множество эндпоинтов (`/users`, `/hotels`, `/booking` и др.). Чтобы не дублировать код инкремента в каждом обработчике, используется аннотация `@ModelAttribute`.

> **Справка: Механизм `@ModelAttribute` для перехвата входящего трафика** \
> В Spring MVC метод контроллера, аннотированный `@ModelAttribute`, автоматически вызывается перед любым методом обработки запросов этого контроллера. Это позволяет считать все входящие запросы к шлюзу, не добавляя отдельные перехватчики и фильтры.

Листинг изменённого контроллера `services/gateway-service/.../GatewayController.java`:

```java
package com.s21.devops.sample.gatewayservice.Controller;

// ... существующие импорты ...
import io.micrometer.core.instrument.MeterRegistry;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/v1/gateway")
public class GatewayController {
    /// ...

    @Autowired
    private MeterRegistry registry;

    @ModelAttribute
    public void countRequests() {
        registry.counter("gateway.requests.total").increment();
    }

    // ... методы контроллера (createUser, getHotels, bookHotel и др.) ...
}
```

- Собираем обновлённый образ микросервиса шлюза:

```sh
docker build -t lenyldes/gateway-service:1 ./services/gateway-service
```

- Перезапускаем контейнер `gateway-service`:

```sh
docker compose up -d --force-recreate gateway-service
```

- Выполняем тестовый запрос к любому эндпоинту API Gateway (порт 8087, проксируется через Nginx):

```sh
curl -i -s http://localhost:8087/api/v1/gateway/hotels | head -3
```

- Запрашиваем `/actuator/prometheus` шлюза и проверяем значение счётчика:

```sh
curl -s http://localhost:8087/actuator/prometheus | grep gateway_requests_total
```

Вывод:

```text
# HELP gateway_requests_total  
# TYPE gateway_requests_total counter
gateway_requests_total 6.0
```

После двух дополнительных запросов значение счётчика корректно увеличивается до `8.0`.

> Проверка фиксации метрики gateway_requests_total при запросах к API Gateway \
![Метрика gateway_requests_total](<screenshot/Screenshot 2026-09-09 at 11.52.11.png>)

---

##### 1.2.2.3. Сбор метрик бронирования и очередей RabbitMQ. Комплексная проверка

По той же схеме собираем ещё три метрики с помощью Micrometer:
1. **`bookings.total`** — сколько было оформлено бронирований (`booking-service`);
2. **`rabbitmq.messages.sent.total`** — сколько сообщений отправили в RabbitMQ (`booking-service`);
3. **`rabbitmq.messages.processed.total`** — сколько сообщений обработали из RabbitMQ (`report-service`).

##### 1. Сервис `booking-service`: считаем бронирования и отправку в очередь

- В контроллере `BookingController.java` подключаем реестр метрик (`MeterRegistry`) и в методе `bookHotel` увеличиваем счётчик бронирований `bookings.total`.

Листинг контроллера `services/booking-service/.../BookingController.java`:

```java
package com.s21.devops.sample.bookingservice.Controller;

// ... существующие импорты ...
import io.micrometer.core.instrument.MeterRegistry;

@EnableCircuitBreaker
@RestController
@RequestMapping("/api/v1/booking")
public class BookingController {
    @Autowired
    private BookingService bookingService;

    @Autowired
    private MeterRegistry registry;

    @ResponseStatus(HttpStatus.CREATED)
    @PostMapping("")
    public void bookHotel(@Valid @RequestBody BookHotelReq bookHotelReq)
            throws CustomRuntimeException, PaymentNotFoundException, LoyaltyNotFoundException, JsonProcessingException, CoudntPayException {
        System.out.println("hotel was booked");
        bookingService.bookHotel(bookHotelReq);

        registry.counter("bookings.total").increment();
    }

    // ... остальные методы контроллера ...
}
```

- В компоненте `QueueProducer.java` тоже подключаем `MeterRegistry`. После того как сообщение успешно ушло в очередь RabbitMQ через `rabbitTemplate.convertAndSend(...)`, увеличиваем счётчик `rabbitmq.messages.sent.total`.

Листинг компонента `services/booking-service/.../QueueProducer.java`:

```java
package com.s21.devops.sample.bookingservice.Statistics;

// ... существующие импорты ...
import io.micrometer.core.instrument.MeterRegistry;

@Component
public class QueueProducer {
    @Value("${fanout.exchange}")
    private String fanoutExchange;

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Autowired
    private MeterRegistry registry;

    private ObjectMapper objectMapper = new ObjectMapper();

    public void putStatistics(BookingStatisticsMessage bookingStatisticsMessage) throws JsonProcessingException {
        rabbitTemplate.setExchange(fanoutExchange);
        rabbitTemplate.convertAndSend(objectMapper.writeValueAsString(bookingStatisticsMessage));
        System.out.println("Message was sent successfully!");

        registry.counter("rabbitmq.messages.sent.total").increment();
    }
}
```

##### 2. Сервис `report-service`: считаем обработку сообщений из очереди

- В компоненте-слушателе `QueueConsumer.java` подключаем `MeterRegistry`. В методе `processMessage(...)` после того, как распарсенное сообщение передали в сервис статистики, увеличиваем счётчик `rabbitmq.messages.processed.total`.

Листинг компонента `services/report-service/.../QueueConsumer.java`:

```java
package com.s21.devops.sample.reportservice.Statistics;

// ... существующие импорты ...
import io.micrometer.core.instrument.MeterRegistry;

@Component
public class QueueConsumer {
    @Autowired
    private BookingStatsService bookingStatsService;

    @Autowired
    private MeterRegistry registry;

    private ObjectMapper objectMapper = new ObjectMapper();

    public void receiveMessage(String message) throws JsonProcessingException {
        System.out.println("Received message: " + message);
        processMessage(message);
    }

    private void processMessage(String message) throws JsonProcessingException {
        BookingStatisticsMessage bsm = objectMapper.readValue(message, BookingStatisticsMessage.class);
        bookingStatsService.postBookingStatsMessage(bsm);

        registry.counter("rabbitmq.messages.processed.total").increment();
    }
}
```

##### 3. Комплексная проверка работы всех 5 метрик

Сначала пересобираем образы сервисов и обновляем контейнеры, чтобы изменения применились:

```sh
docker build -t lenyldes/booking-service:1 ./services/booking-service
docker build -t lenyldes/report-service:1 ./services/report-service
docker compose up -d --force-recreate booking-service report-service
```

Теперь проверяем, что все метрики собираются правильно: снимаем начальные значения, запускаем тесты через Newman, потом снова смотрим метрики и сравниваем.

1. **Снимаем начальные значения метрик.**

Сервисы `booking-service` (порт 8083) и `report-service` (порт 8086) работают внутри Docker-сети и не доступны напрямую снаружи. Поэтому запрашиваем их метрики через контейнер `nginx-proxy` с помощью утилиты `wget`:

```sh
NGINX=$(docker ps -q -f name=nginx-proxy | head -n 1)

echo "=== 1. session-service: auth_requests_total ==="
curl -s http://localhost:8081/actuator/prometheus | grep -E '^auth_requests_total'

echo "=== 2. gateway-service: gateway_requests_total ==="
curl -s http://localhost:8087/actuator/prometheus | grep -E '^gateway_requests_total'

echo "=== 3 и 4. booking-service: bookings_total и rabbitmq_messages_sent_total ==="
docker exec $NGINX wget -qO- http://booking-service:8083/actuator/prometheus | grep -E '^(bookings_total|rabbitmq_messages_sent_total)'

echo "=== 5. report-service: rabbitmq_messages_processed_total ==="
docker exec $NGINX wget -qO- http://report-service:8086/actuator/prometheus | grep -E '^rabbitmq_messages_processed_total'
```

Пояснения к командам:
- `NGINX=$(docker ps -q -f name=nginx-proxy | head -n 1)` — находим контейнер Nginx-прокси, который в той же сети, что и микросервисы;
- `curl -s http://localhost:...` — берём метрики у сервисов, у которых есть внешний доступ (сессия и шлюз);
- `docker exec $NGINX wget ...` — делаем запрос к внутренним сервисам прямо из сети Docker по их именам (`booking-service`, `report-service`);
- `grep -E '^...'` — оставляем только строки с нужными счётчиками.

> Снятие первоначальных показателей всех 5 метрик перед тестированием \
![Снятие первоначальных показателей метрик](<screenshot/Screenshot 2026-09-09 at 12.46.43.png>)

2. **Запускаем тестовую коллекцию через Newman.**

Чтобы имитировать реальную нагрузку (авторизация, просмотр отелей, бронирование, отправка статистики), запускаем Newman:

```sh
docker run --rm -v "$(pwd)":/etc/newman --network host postman/newman run /etc/newman/application_tests.postman_collection.json
```

Что делают флаги:
- `--rm` — контейнер Newman удалится сам после тестов;
- `-v "$(pwd)":/etc/newman` — подкладываем текущую папку внутрь контейнера, чтобы Newman увидел файл коллекции;
- `--network host` — контейнер может обращаться к тем же портам, что и хост (например, к 8081 и 8087);
- `run /etc/newman/...` — запускаем сценарии из коллекции Postman.

3. **Проверяем метрики ещё раз после тестов.**

Снова запускаем скрипт, который собирает значения метрик, чтобы увидеть, насколько они выросли.

> Контрольный замер значений всех 5 метрик после выполнения тестов Newman \
![Контрольный замер метрик](<screenshot/Screenshot 2026-09-09 at 12.48.19.png>)

4. **Смотрим результаты.**

Сравниваем значения до и после тестов:
- **`auth_requests_total`**: было `2.0`, стало `3.0` (+1) — прошёл один запрос на авторизацию;
- **`gateway_requests_total`**: было `5.0`, стало `9.0` (+4) — через шлюз прошло 4 запроса из коллекции;
- **`bookings_total`**: было `1.0`, стало `2.0` (+1) — успешно зафиксировано одно бронирование;
- **`rabbitmq_messages_sent_total`**: было `61.0`, стало `122.0` (+61) — в очередь отправили 61 сообщение со статистикой;
- **`rabbitmq_messages_processed_total`**: было `61.0`, стало `122.0` (+61) — сервис отчётов обработал ровно столько же сообщений.

> **Вывод:** Значения `rabbitmq_messages_sent_total` и `rabbitmq_messages_processed_total` совпали (оба `122.0`) — значит, сообщения доставлены и обработаны без потерь. Все 5 счётчиков работают как надо и отдают данные в формате Prometheus.

---

### 1.3. Сбор логов приложения с помощью Grafana Loki

#### Метрики (Prometheus) vs логи (Grafana Loki)

Наблюдаемость (Observability) опирается на три столпа:

1. **Метрики (Metrics)** — числовые временные ряды (Prometheus);
2. **Логи (Logs)** — потоки событий с полнотекстовым поиском (Grafana Loki);
3. **Трассировки (Traces)** — сквозное отслеживание запросов между сервисами (Jaeger, Grafana Tempo).

Prometheus и Loki решают разные, но взаимодополняющие задачи:

- **Prometheus** — числовые временные ряды. Работает по **pull-модели**: сервер опрашивает эндпоинты сервисов (например, `/actuator/prometheus`) с заданным интервалом (*scrape interval*). Отвечает на вопрос «что и в каком объёме происходит прямо сейчас?» (RPS, загрузка CPU, количество обработанных сообщений). Но метрики не дают контекста инцидента: Prometheus покажет всплеск `http_requests_total{status="500"} = 15`, но не объяснит причину.

- **Grafana Loki** — текстовые потоки событий. Работает по **push-модели**: приложения и агенты отправляют логи пачками (*batches*) по HTTP. Отвечает на вопрос «что конкретно произошло внутри сервиса в данный момент?». В отличие от Elasticsearch, Loki не строит инвертированный индекс по каждому слову — индексируются только **метки (labels)**, а текст лога сжимается в блоки (*chunks*). Это даёт лёгкость, высокую скорость записи и низкое потребление ресурсов.

> **Справка: синергия Prometheus и Loki** \
> Метрики и логи образуют единый контур диагностики: по дашбордам Prometheus выявляется факт и временной интервал аномалии, затем через Loki по тем же лейблам локализуются подробные сообщения об ошибках и стектрейсы — без ручного поиска по серверам.

---

#### Twelve-Factor App и подходы к сбору логов

Согласно **Twelve-Factor App (раздел XI. Logs)**, сервис не должен сам управлять маршрутизацией, хранением и ротацией логов. Контейнеризированное приложение пишет только в стандартные потоки:

- `stdout` — информационные сообщения, ход выполнения, отладка;
- `stderr` — предупреждения, исключения, критические ошибки.

Docker перехватывает `stdout` и `stderr` всех контейнеров. Для доставки в Loki рассмотрены три подхода:

1. **Loki Docker Driver (официальный плагин логирования Docker)**
   - Регистрируется в демоне Docker и напрямую стримит вывод контейнеров по HTTP в Loki.
   - **Плюсы:** приложения не модифицируются (Java, Nginx, PostgreSQL, RabbitMQ — всё без изменений); единый механизм сбора со всех контейнеров; подключается декларативно через секцию `logging` в `docker-compose.yml` или глобально через `/etc/docker/daemon.json`.
   - **Минусы:** требует установки плагина на хост; при недоступности Loki контейнеры в режиме `mode: blocking` могут зависнуть при выводе, поэтому обязательно настраивается `mode: non-blocking`.

2. **Агент-сборщик (Promtail / Grafana Alloy)**
   - Отдельный контейнер-агент монтирует сокет Docker (`/var/run/docker.sock`) или каталог логов (`/var/lib/docker/containers/`), читает строки через `tail -f`, парсит и отправляет в Loki.
   - **Плюсы:** не меняет глобальную конфигурацию Docker Daemon; поддерживает гибкие конвейеры фильтрации.
   - **Минусы:** дополнительный сервис с привилегированным доступом к хосту. Главное — в требованиях к стеку мониторинга (пункт 4 задания: *«Prometheus Server, Loki, node_exporter, blackbox_exporter, cAdvisor»*) агент Promtail не предусмотрен.

3. **Встроенный лог-аппендер приложения (например, Loki4j)**
   - Java-сервис через аппендер Logback отправляет логи напрямую в Loki из приложения.
   - **Минусы:** нарушение Twelve-Factor App (зависимость от доступности лог-сервера). Инфраструктурные сервисы (Nginx на C, PostgreSQL на C, RabbitMQ на Erlang) — не Java-приложения, внедрить аппендер нельзя, их логи будут потеряны.

**Выбор:** целевой — **Подход 1 (Loki Docker Driver)**: прозрачный сбор со всех сервисов (Java-микросервисов и инфраструктурных контейнеров Nginx, PostgreSQL, RabbitMQ), соответствие Twelve-Factor App, без лишних агентов.

---

#### Развертывание и проверка готовности сервиса Grafana Loki

Сбор логов вынесен в отдельный стек `monitoring` — дальше туда же добавятся остальные компоненты (Prometheus Server, Grafana, экспортеры).

- Структура каталогов для конфигурации и сервисов мониторинга:

```bash
. (src)
└── monitoring/
    ├── docker-compose.yml
    └── loki/
        └── loki-config.yaml
```

- Скачиваем эталонную конфигурацию Loki версии `3.7.0` из официального репозитория Grafana:

```sh
wget https://raw.githubusercontent.com/grafana/loki/v3.7.0/cmd/loki/loki-local-config.yaml -O monitoring/loki/loki-config.yaml
```

где:
- `https://raw.githubusercontent.com/.../loki-local-config.yaml` — URL официального шаблона локальной конфигурации Grafana Loki релиза `v3.7.0`;
- `-O monitoring/loki/loki-config.yaml` — путь и имя файла для сохранения конфигурации.

- Файл `monitoring/docker-compose.yml`:

```yaml
services:
  loki:
    image: grafana/loki:3.7.0
    ports:
      - "3100:3100"
    volumes:
      - ./loki:/mnt/config
    command: -config.file=/mnt/config/loki-config.yaml
```

где:
- `image: grafana/loki:3.7.0` — официальный образ Grafana Loki фиксированной версии `3.7.0`;
- `ports: - "3100:3100"` — проброс порта `3100` хоста для приёма логов по HTTP (Push API) и выполнения запросов LogQL;
- `volumes: - ./loki:/mnt/config` — монтирование локального каталога `loki/` с конфигурацией внутрь контейнера по пути `/mnt/config`;
- `command: -config.file=/mnt/config/loki-config.yaml` — переопределение аргументов запуска демона Loki с указанием пути к конфигурационному файлу.

- Переходим в директорию `monitoring/` и запускаем контейнер Loki в фоновом режиме:

```sh
cd monitoring
docker compose up -d # пока для теста, потом будет Swarm
```

где:
- `cd monitoring` — переход в рабочий каталог стека мониторинга;
- `docker compose up -d` — создание и запуск контейнеров, объявленных в `docker-compose.yml`, в фоновом режиме (*detached mode*).

- Проверяем готовность сервиса к приёму логов через эндпоинт `/ready`:

```sh
curl -i http://localhost:3100/ready
```

где:
- `-i` — вывод заголовков HTTP-ответа вместе с телом;
- `http://localhost:3100/ready` — технический эндпоинт проверки готовности сервиса Loki.

В ответ сервер возвращает HTTP-статус `200 OK` и сообщение `ready` — Компоненты приёма и обработки логов (distributor, ingester),а также система хранения блоков данных работают корректно.

> Запуск контейнера Grafana Loki и проверка эндпоинта готовности /ready \
![Готовность сервиса Loki](<screenshot/Screenshot 2026-09-10 at 09.38.23.png>)

---

#### Установка и настройка плагина Loki Docker Driver

Чтобы собирать логи контейнеров, нужно подключить их к работающему серверу Grafana Loki, настроить перехват стандартных потоков вывода (`stdout` / `stderr`) и автоматически добавлять метаданные (метки / *labels*).

По умолчанию Docker Engine использует драйвер `json-file`: он сохраняет логи в JSON‑файлы на хосте — в папке `/var/lib/docker/containers/...`. Чтобы отправлять логи прямо в Loki по сети, используют плагины Docker Engine (*Docker Plugins*).

Плагин работает как отдельный фоновый процесс под управлением Docker‑демона:

1. Приложение в контейнере пишет строку в стандартный поток (`stdout` или `stderr`).
2. Демон Docker перехватывает этот поток и передаёт его через локальный сокет плагину драйвера логирования.
3. Плагин собирает строки в пакеты (*batches*), добавляет к ним метки (имя контейнера, образ, проект, сервис) и отправляет по HTTP POST на эндпоинт `http://localhost:3100/loki/api/v1/push`.

- Устанавливаем официальный плагин логирования Grafana Loki в Docker Engine:

```sh
docker plugin install grafana/loki-docker-driver:3.7.0-arm64 --alias loki --grant-all-permissions
```

где:
- `docker plugin install` — команда установки плагина в Docker Engine;
- `grafana/loki-docker-driver:3.7.0-arm64` — образ официального драйвера логирования Grafana Loki (версия `3.7.0`, архитектура `arm64`);
- `--alias loki` — задаём короткий псевдоним `loki` для драйвера (потом можно ссылаться на него как `logging.driver: "loki"`);
- `--grant-all-permissions` — автоматически даём плагину все запрашиваемые системные привилегии (в том числе доступ к сети хоста).

> ⚠ **Внимание: архитектура хоста (ARM64 vs AMD64)** \
> Плагин `loki-docker-driver` выпускают отдельными сборками под разные архитектуры. Для Apple Silicon (ARM64 / M‑серия) берите тег `grafana/loki-docker-driver:3.7.0-arm64`, для обычных серверов x86_64 — `grafana/loki-docker-driver:3.7.0-amd64`. Если поставить плагин не под свою архитектуру, демон плагина не запустится.

- Проверяем, что плагин установлен и работает:

```sh
docker plugin ls
```

где:
- `docker plugin ls` — показывает список всех установленных плагинов Docker Engine, включая их ID, псевдонимы и статус (`ENABLED = true` означает, что плагин активен).

> Установка плагина loki-docker-driver и проверка его активного состояния \
![Установка и статус плагина Loki в Docker Engine](<screenshot/Screenshot 2026-09-10 at 10.21.57.png>)

---

#### Настройка сбора логов микросервисов и проверка данных в Loki

##### Пилотное подключение логирования для сервиса RabbitMQ

Сначала проверяем работу логирования на одном сервисе — брокере сообщений `rabbitmq`, а потом уже распространяем конфигурацию на весь стек.

- В файл `services/docker-compose.yml` в описание сервиса `rabbitmq` добавляем секцию `logging`:

```yaml
  rabbitmq:
    image: rabbitmq:3-management-alpine
    restart: always
    logging:
      driver: "loki"
      options:
        loki-url: "http://localhost:3100/loki/api/v1/push"
        mode: non-blocking
        max-buffer-size: 4m
```

где:
- `driver: "loki"` — говорим Docker использовать плагин с псевдонимом `loki`;
- `loki-url: "http://localhost:3100/loki/api/v1/push"` — адрес API Loki, куда плагин будет отправлять пакеты логов;
- `mode: non-blocking` — неблокирующий режим отправки: если Loki временно недоступен, контейнер не зависнет, а логи будут копиться в буфере в оперативной памяти;
- `max-buffer-size: 4m` — максимальный размер буфера для неотправленных логов — 4 МБ.

- Перезапускаем сервисы, чтобы применить новую конфигурацию:

```sh
docker compose up -d --build
```

где:
- `docker compose up -d` — запускаем контейнеры в фоновом режиме (*detached*);
- `--build` — проверяем и при необходимости пересобираем образы перед запуском.

- Проверяем, что логи начали поступать в Loki и метки индексируются, через REST API Grafana Loki:

```sh
curl -s http://localhost:3100/loki/api/v1/labels
```

где:
- `-s` — тихий режим (*silent*), без индикатора прогресса;
- `http://localhost:3100/loki/api/v1/labels` — эндпоинт Loki, который возвращает все зарегистрированные ключи меток.

Сервер вернёт список меток, которые добавил драйвер логирования Docker:

```json
{"status":"success","data":["compose_project","compose_service","container_name","filename","host","service_name","source"]}
```

- Смотрим, какие значения есть у метки `compose_service`:

```sh
curl -s http://localhost:3100/loki/api/v1/label/compose_service/values
```

где:
- `.../label/compose_service/values` — эндпоинт Loki для получения значений конкретной метки `compose_service`.

В ответе будет имя сервиса `rabbitmq`:

```json
{"status":"success","data":["rabbitmq"]}
```

> Валидация регистрации меток и поступления логов сервиса rabbitmq через HTTP API Loki \
![Проверка меток сервиса rabbitmq в Loki API](<screenshot/Screenshot 2026-09-10 at 10.55.00.png>)

---

##### Масштабирование логирования на все сервисы стека

Когда пилотная настройка сработала, включаем централизованный сбор логов для всех 10 сервисов приложения (`nginx-proxy`, `postgres`, `rabbitmq` и всех Java‑микросервисов).

> **Справка: повторное использование конфигурации через YAML Anchors (`&`) и Aliases (`*`)** \
> Чтобы не копировать одинаковые параметры `logging` для каждого сервиса в `docker-compose.yml`, используют YAML‑якоря (*Anchors* `&`) и ссылки (*Aliases* `*`). Блок `x-logging: &default-logging` задаёт общий фрагмент конфигурации (префикс `x-` — это пользовательское расширение, Compose его игнорирует), а `logging: *default-logging` просто подставляет этот фрагмент в нужный сервис.

- Добавляем шаблон логирования в начало `services/docker-compose.yml` и подключаем его ко всем сервисам:

```yaml
x-logging: &default-logging
  driver: "loki"
  options:
    loki-url: "http://localhost:3100/loki/api/v1/push"
    mode: non-blocking
    max-buffer-size: 4m

services:
  nginx-proxy:
    image: lenyldes/nginx:1
    ports:
      - 8081:8081
      - 8087:8087
    depends_on:
      - session-service
      - gateway-service
    logging: *default-logging

  postgres:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: users_db
    volumes:
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    logging: *default-logging

  rabbitmq:
    image: rabbitmq:3-management-alpine
    restart: always
    logging: *default-logging

  booking-service:
    image: lenyldes/booking-service:1
    restart: always
    # ... переменные окружения ...
    logging: *default-logging

  # ... аналогично добавляем logging: *default-logging в остальные сервисы:
  # gateway-service, hotel-service, loyalty-service, payment-service, report-service, session-service
```

- Перезапускаем весь стек, чтобы новая политика логирования применилась ко всем сервисам:

```sh
docker compose up -d --build
```

- Делаем контрольный запрос к API Loki, чтобы убедиться, что все сервисы зарегистрированы:

```sh
curl -s http://localhost:3100/loki/api/v1/label/compose_service/values
```

Ответ Loki API:

```json
{"status":"success","data":["booking-service","gateway-service","hotel-service","loyalty-service","nginx-proxy","payment-service","postgres","rabbitmq","report-service","session-service"]}
```

> **Вывод:** Все 10 сервисов стека (`booking-service`, `gateway-service`, `hotel-service`, `loyalty-service`, `nginx-proxy`, `payment-service`, `postgres`, `rabbitmq`, `report-service`, `session-service`) теперь пишут логи через плагин `loki-docker-driver`. Потоки вывода контейнеров автоматически получают метки Compose и попадают в хранилище Grafana Loki.

> Перезапуск стека микросервисов и проверка регистрации всех 10 сервисов в Loki \
![Регистрация всех сервисов стека в Loki API](<screenshot/Screenshot 2026-09-10 at 11.00.55.png>)

---

### 1.4. Развертывание стека мониторинга в Docker Swarm

Источники данных подготовлены — переходим к построению полноценного контура наблюдаемости (*Observability*). Цель — развернуть в Docker Swarm отдельный стек `monitoring` с Prometheus Server в качестве ядра.

---

#### Архитектура и компоненты контура наблюдаемости

В инфраструктуре наблюдаемости важно чётко разделять уровни сбора телеметрии и зоны ответственности компонентов:

1. **Prometheus Server** — центральное ядро: сбор, хранение временных рядов (TSDB) и обработка числовых метрик по Pull-модели. Поддерживает язык запросов PromQL и веб-интерфейс на порту `9090`.
2. **Grafana Loki** — горизонтально масштабируемое хранилище логов приложения, оптимизированное для работы с метками (labels).
3. **node_exporter** — агент сбора аппаратных и операционных метрик сервера (*Host Level*: утилизация CPU, распределение RAM, дисковый ввод-вывод `disk_io`, активность сетевых интерфейсов).
4. **cAdvisor (Container Advisor)** — системный демон для сбора телеметрии на уровне контейнеров (*Container Level*). Анализирует данные виртуальной файловой системы cgroups ядра Linux и Docker-демона, фиксируя фактическое потребление ресурсов каждым контейнером.
5. **blackbox_exporter** — инструмент пробинга и синтетического мониторинга конечных точек методом «чёрного ящика» (*Synthetic / Blackbox Monitoring*). Проверяет доступность внутренних и внешних ресурсов по сетевым протоколам (HTTP/HTTPS, TCP, ICMP, DNS).

##### Сводная таблица параметров сервисов стека `monitoring`:

| Сервис | Образ | Режим (`deploy.mode`) | Сети | Публикация портов (`ports:`) | Зона ответственности |
|---|---|---|---|---|---|
| `prometheus` | `prom/prometheus:latest` | `replicated` | `monitoring_default`, `do9-shared` | `"9090:9090"` | Центральный сервер метрик и TSDB |
| `loki` | `grafana/loki:3.7.0` | `replicated` | `monitoring_default` | `"3100:3100"` | Сбор и хранение логов микросервисов |
| `node_exporter` | `quay.io/prometheus/node-exporter:latest` | `global` | `monitoring_default` | Не публикуется (скрыт) | Метрики хоста и ОС (Host Level) |
| `cadvisor` | `ghcr.io/google/cadvisor:latest` | `global` | `monitoring_default` | Не публикуется (скрыт) | Метрики контейнеров cgroups (Container Level) |
| `blackbox_exporter` | `quay.io/prometheus/blackbox-exporter:latest` | `replicated` | `monitoring_default` | Не публикуется (скрыт) | Синтетический пробинг доступности конечных точек |

> **Справка: Выбор режима развёртывания (`global` vs `replicated`) в Docker Swarm** \
> Для экспортеров низкоуровневых системных метрик (`node_exporter` и `cAdvisor`) используется режим `deploy.mode: global`. Это гарантирует запуск ровно одной реплики на каждом узле Swarm-кластера (в том числе при динамическом добавлении новых нод), что необходимо для охвата всех физических ресурсов и локальных контейнеров. Сервисы уровня приложений и агрегации (`prometheus`, `loki`, `blackbox_exporter`) работают в режиме `replicated` — они не привязаны к конкретному хосту и масштабируются гибче.

---

#### Организация межсервисного сетевого взаимодействия

Prometheus развёртывается в стеке `monitoring`, а микросервисы приложения — в стеке `hotel_app`. Чтобы Prometheus мог скрейпить эндпоинты `/actuator/prometheus`, стекам нужна общая сеть.

- Создаём внешнюю оверлейную сеть:

```sh
docker network create do9-shared --driver overlay --attachable
```

где:
- `docker network create` — команда создания пользовательской сети в Docker;
- `do9-shared` — имя создаваемой сети;
- `--driver overlay` — распределённый оверлейный драйвер Docker Swarm для связи контейнеров на разных узлах кластера;
- `--attachable` — флаг, позволяющий подключать к оверлейной сети не только Swarm-сервисы, но и отдельные standalone-контейнеры.

##### Подходы к сетевой интеграции стеков:

1. **Точечное подключение (*Principle of Least Privilege*):** к сети `do9-shared` подключаются только те сервисы, к которым нужен прямой доступ Prometheus (микросервисы с Actuator-эндпоинтами). Внутренние хранилища данных (PostgreSQL, RabbitMQ) остаются строго изолированными во внутренней сети. Рекомендуется для сред с повышенными требованиями к безопасности (*production*).
2. **Переопределение сети по умолчанию (`default` network):** стандартная сеть стека `hotel_app` переопределяется на внешнюю `do9-shared`. Это избавляет от необходимости дублировать блок `networks` у каждого сервиса в Compose-файле:

```yaml
networks:
  default:
    external: true
    name: do9-shared
```

Prometheus в стеке `monitoring` подключается сразу к двум сетям: внутренней `monitoring_default` (для обращения к локальным экспортерам) и внешней `do9-shared` (для сбора метрик с микросервисов приложения):

```yaml
networks:
  default:
    name: monitoring_default
  shared:
    external: true
    name: do9-shared
```

---

#### Конфигурация Prometheus Server (`prometheus.yml`)

Таргеты сбора метрик описаны в файле `src/monitoring/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'blackbox_check'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://www.google.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox_exporter:9115

  - job_name: 'hotel-services'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets:
          - 'booking-service:8083'
          - 'gateway-service:8087'
          - 'session-service:8081'
          - 'report-service:8086'
```

##### Разбор задач сбора метрик (*scrape jobs*):

- `global.scrape_interval: 15s` — базовый интервал опроса всех таргетов по умолчанию (15 секунд);
- `job_name: 'prometheus'` — сбор собственных метрик и телеметрии сервера Prometheus;
- `job_name: 'node_exporter'` — опрос хостового экспортера на порту `9100`;
- `job_name: 'cadvisor'` — опрос экспортера метрик контейнеров на порту `8080`;
- `job_name: 'blackbox_check'` — синтетическая проверка доступности `https://www.google.com` через Blackbox Exporter;
- `job_name: 'hotel-services'` — опрос кастомных метрик микросервисов приложения (`booking-service`, `gateway-service`, `session-service`, `report-service`) по эндпоинту `metrics_path: '/actuator/prometheus'`.

> **Справка: Механизм Relabeling в Blackbox Exporter** \
> При проверке доступности через Blackbox Exporter Prometheus отправляет запрос не напрямую к целевому хосту, а к эндпоинту `/probe` самого `blackbox_exporter:9115`, передавая целевой ресурс в query-параметре `target`. Блок `relabel_configs` прозрачно подменяет адрес опроса (`__address__`) на адрес контейнера экспортера, сохраняя исходный URL цели в качестве метки `instance`.

---

#### Конфигурация Compose-файла стека мониторинга (`docker-compose.yml`)

Итоговая спецификация развёртывания — `src/monitoring/docker-compose.yml`:

```yaml
services:
  loki:
    image: grafana/loki:3.7.0
    ports:
      - "3100:3100"
    volumes:
      - ./loki:/mnt/config
    command: -config.file=/mnt/config/loki-config.yaml
    
  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro'
    deploy:
      mode: global

  cadvisor:
    image: ghcr.io/google/cadvisor:latest
    deploy:
      mode: global
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker/ro
      #- /dev/disk/:/dev/disk:ro
  
  blackbox_exporter:
    image: quay.io/prometheus/blackbox-exporter:latest

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - './prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro'
      - 'prometheus-data:/prometheus'
    ports:
      - "9090:9090"
    networks:
      - default
      - shared

networks:
  default:
    name: monitoring_default
  shared:
    external: true
    name: do9-shared

volumes:
  prometheus-data: {}
```

> ⚠ **Инженерный нюанс: Монтирование `/dev/disk` в cAdvisor на macOS / Docker Desktop** \
> При запуске cAdvisor в Docker Desktop на macOS прямое монтирование каталога блочных устройств `/dev/disk/:/dev/disk:ro` может вызывать ошибки инициализации: блочные устройства хоста не пробрасываются в виртуальную машину Linux напрямую. Поэтому том закомментирован — базовый сбор метрик cgroups и Docker Engine работает и без прямого доступа к блочным устройствам хоста.

---

#### Развёртывание стеков и проверка в веб-интерфейсе Prometheus

- Инициализируем Docker Swarm и последовательно разворачиваем стек приложения `hotel_app` и стек мониторинга `monitoring`:

```sh
docker swarm init
docker stack deploy -c ./services/docker-compose.yml hotel_app
docker stack deploy -c ./monitoring/docker-compose.yml monitoring
```

где:
- `docker swarm init` — инициализация текущего узла как менеджера Swarm-кластера (если кластер ещё не активен);
- `docker stack deploy` — развёртывание или обновление стека сервисов из указанного Compose-файла;
- `-c` (`--compose-file`) — путь к конфигурационному файлу Docker Compose;
- `hotel_app` и `monitoring` — имена разворачиваемых стеков.

- Проверяем состояние сервисов в обоих стеках:

```sh
docker stack services hotel_app
docker stack services monitoring
```

где:
- `docker stack services <имя_стека>` — статус всех сервисов стека: идентификаторы, количество реплик (`1/1`), режимы развёртывания (`replicated` / `global`), образы и порты.

> Проверка статуса сервисов стеков hotel_app и monitoring в Docker Swarm \
![Статус сервисов hotel_app и monitoring](<screenshot/Screenshot 2026-09-10 at 13.13.11.png>)

- Проверяем сбор метрик: открываем веб-интерфейс Prometheus по адресу `http://localhost:9090` и переходим на вкладку таргетов `http://localhost:9090/targets` (*Status* -> *Targets*):

> Веб-интерфейс Prometheus со всеми зарегистрированными таргетами в состоянии UP \
![Статус таргетов сбора метрик в Prometheus](<screenshot/Screenshot 2026-09-10 at 13.14.53.png>)

> **Вывод:** все 5 сконфигурированных пулов таргетов успешно зарегистрированы в Prometheus и находятся в состоянии **UP** (зелёный статус):
> - `blackbox_check` (`1/1 up`) — внешний синтетический мониторинг доступности `https://www.google.com`;
> - `cadvisor` (`1/1 up`) — сбор контейнерных метрик cgroups;
> - `hotel-services` (`4/4 up`) — опрос Actuator-эндпоинтов всех четырёх Java-микросервисов (`booking-service`, `gateway-service`, `session-service`, `report-service`);
> - `node_exporter` (`1/1 up`) — сбор низкоуровневых метрик операционной системы хоста;
> - `prometheus` (`1/1 up`) — внутренняя телеметрия сервера Prometheus.

---

## Part 2. Визуализация

В этой главе настраиваем веб-платформу **Grafana** для визуализации собранных метрик и логов. \
Сервис разворачивается в существующем стеке `monitoring`, подключается к источникам данных Prometheus и Loki, после чего собирается дашборд, охватывающий системную, контейнерную и прикладную телеметрию. \
Для воспроизводимости окружения используется автоматическая инициализация (*Grafana Provisioning*).

---

### 2.1. Развертывание сервиса Grafana в стеке мониторинга

Для визуализации метрик и логов в стек мониторинга `monitoring` добавляется официальный образ `grafana/grafana`. Сервис открывает веб-интерфейс на порту `3000` и использует постоянный том (*persistent volume*) для сохранения внутреннего состояния (пользователи, сессии, настройки). В контейнер также монтируется директория с конфигурацией автоматической инициализации (`provisioning`).

- Фрагмент файла `monitoring/docker-compose.yml`:

```yaml
  grafana:
    image: grafana/grafana
    ports:
      - '3000:3000'
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro

volumes:
  prometheus-data: {}
  grafana-storage: {}
```

> **Справка: Персистентность и декларативная конфигурация Grafana** \
> По умолчанию Grafana хранит сессии, учётные записи и метаданные во встроенной SQLite-базе по пути `/var/lib/grafana`. Именованный том `grafana-storage` гарантирует сохранность этих данных при перезапусках и обновлениях контейнера. Директория `provisioning` монтируется в режиме только для чтения (`:ro`), что реализует подход *Configuration as Code*.

- Разворачиваем обновлённый стек мониторинга в Docker Swarm:

```sh
docker stack deploy -c ./monitoring/docker-compose.yml monitoring
```

где:
- `docker stack deploy` — команда развёртывания или обновления сервисов стека в Swarm;
- `-c ./monitoring/docker-compose.yml` — путь к файлу конфигурации стека мониторинга;
- `monitoring` — имя целевого стека.

- Проверяем успешный запуск сервисов и готовность реплики `grafana` (`1/1`):

```sh
docker stack services monitoring
```

где:
- `docker stack services <имя_стека>` — вывод списка запущенных сервисов стека с указанием режима развёртывания, количества активных реплик, используемого образа и опубликованных портов.

> Развертывание обновленного стека мониторинга и проверка статуса сервиса grafana \
![Статус сервисов стека monitoring](<screenshot/Screenshot 2026-09-10 at 13.59.14.png>)

- Проверяем доступность веб-интерфейса Grafana: открываем браузер и переходим по адресу `http://localhost:3000`:

> Стартовая страница веб-интерфейса Grafana \
![Веб-интерфейс Grafana](<screenshot/Screenshot 2026-09-10 at 14.01.37.png>)

---

### 2.2. Подключение источников данных (Data Sources)

Для построения дашбордов Grafana нужен доступ к базам данных телеметрии. В контуре мониторинга используются два источника:
1. **Prometheus** — сбор и хранение числовых временных рядов (системные метрики хоста, метрики cAdvisor, бизнес-метрики Actuator).
2. **Loki** — агрегация структурированных логов контейнеров.

> **Справка: Межсервисная адресация в Docker Swarm** \
> Поскольку Grafana, Prometheus и Loki находятся в общей overlay-сети `monitoring_default` (с псевдонимом `default` в Compose), обращение к источникам данных выполняется напрямую по именам сервисов через встроенный Swarm DNS:
> - Prometheus: `http://prometheus:9090` (назначается источником по умолчанию — *Default*);
> - Loki: `http://loki:3100`.

- В веб-интерфейсе переходим в раздел **Connections** -> **Data Sources** и подключаем Prometheus и Loki:

> Настроенные и активные источники данных Prometheus и Loki \
![Источники данных Prometheus и Loki](<screenshot/Screenshot 2026-09-10 at 14.06.13.png>)

---

### 2.3. Создание и настройка дашборда мониторинга

Согласно техническому заданию собран единый дашборд, логически сгруппированный в три тематических раздела (*Rows*):
1. **Host & Network Infrastructure** — параметры физического/виртуального узла и сетевой связности;
2. **cAdvisor** — состояние контейнеров и стеков оркестратора;
3. **Actuator + Loki** — бизнес-показатели микросервисного приложения и агрегированные журналы.

---

#### 2.3.1. Метрики инфраструктуры хоста и сети (Host & Network Infrastructure)

Этот блок собирает низкоуровневые метрики ОС хоста через агент `node_exporter`, а также метрику внешней сетевой доступности через `blackbox_exporter`.

Сводная таблица параметров панелей:

| № | Название панели | Источник / Экспортёр | PromQL-запрос | Тип визуализации | Описание |
|---|-----------------|----------------------|---------------|------------------|----------|
| 1 | Количество нод | `node_exporter` | `count(up{job="node_exporter"})` | Stat | Количество активных узлов кластера, отдающих метрики |
| 2 | Количество CPU | `node_exporter` | `count(node_cpu_seconds_total{mode="idle"})` | Stat | Общее число доступных процессорных ядер хоста |
| 3 | Доступная и занятая память | `node_exporter` | Доступно: `node_memory_MemAvailable_bytes`<br>Занято: `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes` | Time series | Динамика распределения оперативной памяти хоста (байт) |
| 4 | Использование CPU по ядрам и узлам | `node_exporter` | `(1 - rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100` | Time series | Процентная утилизация процессорного времени в разрезе каждого ядра |
| 5 | Доступность google.com | `blackbox_exporter` | `probe_success{job="blackbox_check"}` | Stat | Статус сетевой доступности внешнего ресурса (`1` — доступен, `0` — сбой) |

> **Справка: Расчёт утилизации CPU в PromQL** \
> Метрика `node_cpu_seconds_total` — накопительный счётчик (*counter*) времени, проведённого ядром в определённом состоянии. Фильтр `{mode="idle"}` выделяет время простоя. Функция `rate(...[1m])` вычисляет долю простоя за последнюю минуту, а выражение `(1 - rate) * 100` переводит значение в процент активной загрузки ядра.

> Панели группы Host & Network Infrastructure \
![Host & Network Infrastructure](<screenshot/Screenshot 2026-09-10 at 14.52.34.png>)

---

#### 2.3.2. Метрики контейнеризации cAdvisor

Этот блок визуализирует состояние контейнерной среды Docker на основе метрик cgroups, экспортируемых демоном `cAdvisor`.

Сводная таблица параметров панелей:

| № | Название панели | Источник / Экспортёр | PromQL-запрос | Тип визуализации | Описание |
|---|-----------------|----------------------|---------------|------------------|----------|
| 6 | Количество контейнеров | `cAdvisor` | `count(container_last_seen{name=~".+"})` | Stat | Общее число активных контейнеров на узле |
| 7 | Количество стеков | `cAdvisor` | `count(count by (container_label_com_docker_stack_namespace)(container_last_seen{container_label_com_docker_stack_namespace=~".+"}))` | Stat | Количество уникальных пространств имён Swarm-стеков |
| 8 | Использование CPU по сервисам | `cAdvisor` | `sum by(container_label_com_docker_swarm_service_name) (rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name=~".+"}[1m]) * 100)` | Time series | Нагрузка на процессор в процентах с группировкой по сервисам Swarm |
| 9 | Затраченная RAM | `cAdvisor` | `sum by(container_label_com_docker_swarm_service_name) (container_memory_usage_bytes{container_label_com_docker_swarm_service_name=~".+"})` | Time series | Объём потребляемой оперативной памяти с группировкой по сервисам Swarm |

> ⚠ **Фильтрация псевдоконтейнеров cAdvisor** \
> Демон `cAdvisor` отслеживает не только сами контейнеры, но и корневые cgroups хоста (`/`, `/docker`, `/system.slice`). Чтобы исключить системные cgroups и считать только реальные контейнеры, в запросах применяется фильтрация по наличию имени (`name=~".+"`) или по метаданным стека (`container_label_com_docker_stack_namespace=~".+"`).

> Панели группы cAdvisor с метриками контейнеров и стеков \
![Метрики cAdvisor](<screenshot/Screenshot 2026-09-10 at 15.28.49.png>)

---

#### 2.3.3. Бизнес-метрики приложения и логи (Actuator + Loki)

Этот блок объединяет кастомные бизнес-метрики, реализованные в первой части через Spring Boot Actuator и Micrometer, а также панель просмотра журналов событий, поступающих в Loki через Docker Logging Driver.

Сводная таблица параметров панелей:

| № | Название панели | Источник данных | PromQL / LogQL запрос | Тип визуализации | Описание |
|---|-----------------|-----------------|-----------------------|------------------|----------|
| 10 | Количество полученных запросов на gateway | Prometheus | `sum(gateway_requests_total)` | Stat | Суммарное число входящих HTTP-запросов к API Gateway |
| 11 | Количество полученных запросов на авторизацию пользователей | Prometheus | `sum(auth_requests_total)` | Stat | Количество вызовов эндпоинта аутентификации `session-service` |
| 12 | Количество бронирований | Prometheus | `sum(bookings_total)` | Stat | Количество успешно зарегистрированных бронирований |
| 13 | Количество отправленных сообщений в rabbitmq | Prometheus | `sum(rabbitmq_messages_sent_total)` | Stat | Общий объём сообщений, отправленных `booking-service` в брокер RabbitMQ |
| 14 | Количество обработанных сообщений в rabbitmq | Prometheus | `sum(rabbitmq_messages_processed_total)` | Stat | Число сообщений очереди, обработанных сервисом `report-service` |
| 15 | Логи приложения (Loki) | Loki | `{swarm_stack="hotel_app"}` | Logs | Поток текстовых логов контейнеров целевого приложения `hotel_app` |

> Панели бизнес-метрик Spring Boot Actuator и потока логов Loki \
![Бизнес-метрики и логи](<screenshot/Screenshot 2026-09-10 at 15.45.04.png>)

---

### 2.4. Автоматизация конфигурации через Grafana Provisioning

Чтобы при повторном развёртывании кластера или переносе окружения на другой хост дашборды и подключения к источникам данных не приходилось настраивать вручную, используется декларативная инициализация Grafana — **Provisioning**.

Структура каталога автозагрузки `monitoring/grafana/provisioning/`:

```text
monitoring/grafana/provisioning/
├── datasources/
│   └── datasources.yaml       # Декларативное описание подключений к Prometheus и Loki
└── dashboards/ 
    ├── dashboards.yaml        # Инструкция провайдера: откуда и как загружать дашборды
    └── dashboard.json         # Экспортированная схема дашборда со всеми 15 панелями
```

- Конфигурация источников данных `monitoring/grafana/provisioning/datasources/datasources.yaml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    uid: ffxtsfk5g9mv4a

  - name: Loki
    type: loki
    url: http://loki:3100
    uid: bfxtshcmzwc1sa
```

где:
- `apiVersion: 1` — текущая версия схемы декларативной конфигурации источников данных;
- `isDefault: true` — назначение Prometheus источником данных по умолчанию для всех новых панелей;
- `uid` — фиксированный уникальный идентификатор источника, обеспечивающий корректную привязку панелей из файла `dashboard.json`.

- Конфигурация провайдера дашбордов `monitoring/grafana/provisioning/dashboards/dashboards.yaml`:

```yaml
apiVersion: 1

providers:
  - name: 'default'
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards
```

где:
- `type: file` — тип провайдера (файловая система);
- `path: /etc/grafana/provisioning/dashboards` — целевая директория внутри контейнера, из которой Grafana автоматически считывает JSON-описания дашбордов при инициализации сервиса.

> **Справка: Преимущества Provisioning в CI/CD и Swarm** \
> Декларативная конфигурация обеспечивает подход *Infrastructure as Code* (IaC): после выполнения команды `docker stack deploy` запускается полностью готовый к работе контур наблюдаемости. Разработчику или инженеру сопровождения не нужно выполнять ручные действия в интерфейсе (ClickOps), что исключает влияние человеческого фактора.

---

## Part 3. Отслеживание критических событий

В этой главе настраивается система оповещений о критических событиях с помощью **Alertmanager** из экосистемы Prometheus. \
Alertmanager разворачивается как отдельный сервис в стеке мониторинга `monitoring` в Docker Swarm, подключается к серверу Prometheus и отправляет уведомления по двум каналам: **Email** (SMTP) и мессенджер **Telegram**. Для непрерывного контроля состояния инфраструктуры и сервисов описываются и проверяются правила алертинга на PromQL.

---

### 3.1. Развертывание Alertmanager в стеке мониторинга

В экосистеме Prometheus сбор метрик, вычисление условий алертинга и отправка оповещений разделены между независимыми компонентами:

> **Справка: разделение ответственности Prometheus Server и Alertmanager** \
> • **Prometheus Server**: периодически вычисляет PromQL-выражения из заданных правил (Alerting Rules) с интервалом `evaluation_interval`. Если условие выполняется непрерывно в течение времени `for`, Prometheus переводит алерт в статус `FIRING`. Сам Prometheus не отправляет сообщения в каналы связи — он передаёт пачки JSON-событий в Alertmanager через HTTP API (`/api/v2/alerts`). \
> • **Alertmanager**: принимает входящие события от одного или нескольких экземпляров Prometheus, дедуплицирует их, группирует по меткам (`group_by`), применяет правила подавления (*Inhibition*) и временного заглушения (*Silences*), после чего доставляет уведомления в целевые каналы (Email, Telegram, Webhook, Slack и др.).

Для подключения Alertmanager к контуру наблюдаемости выполнены следующие шаги:

1. **Добавление сервиса в `monitoring/docker-compose.yml`**:
Сервис `alertmanager` запускается из официального образа `quay.io/prometheus/alertmanager`, публикует порт `9093` и монтирует конфигурационный файл через том.

Фрагмент файла `monitoring/docker-compose.yml`:

```yaml
  alertmanager:
    image: quay.io/prometheus/alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/config.yml:/etc/alertmanager/alertmanager.yml:ro
```

где:
- `image: quay.io/prometheus/alertmanager` — официальный лёгкий образ Alertmanager;
- `ports: "9093:9093"` — публикация порта для доступа к веб-интерфейсу и API управления алертами;
- `volumes` — монтирование локального конфигурационного файла `config.yml` в стандартный путь `/etc/alertmanager/alertmanager.yml` внутри контейнера в режиме только для чтения (`:ro`).

2. **Интеграция Alertmanager и подключение правил в `monitoring/prometheus/prometheus.yml`**:
Чтобы Prometheus знал адрес Alertmanager для передачи событий, в корневой конфиг добавлена секция `alerting`, а также подключён файл правил `rules.yml` в секции `rule_files`.

Обновлённая конфигурация `monitoring/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - alertmanager:9093 # Адрес сервиса Alertmanager во внутренней Swarm-сети

rule_files:
  - "rules.yml"           # Подключение файла правил алертинга

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'spring_boot'
    metrics_path: '/actuator/prometheus'
    scrape_interval: 5s
    static_configs:
      - targets:
        - 'booking-service:8080'
        - 'report-service:8080'
        - 'gateway-service:8080'
        - 'session-service:8080'
```

Чтобы передать файл правил внутрь контейнера Prometheus, в `monitoring/docker-compose.yml` в секцию `volumes` сервиса `prometheus` добавлена строка монтирования:
`- './prometheus/rules.yml:/etc/prometheus/rules.yml:ro'`

---

### 3.2. Настройка правил алертинга Prometheus (Alerting Rules)

По требованиям задания в файле правил описаны три критических события:
1. Доступная память хоста меньше 100 Мб;
2. Занятая RAM хоста больше 1 Гб;
3. Использование CPU по сервису превышает 10%.

Создан файл `monitoring/prometheus/rules.yml`:

```yaml
groups:
  - name: DO9
    rules:
      - alert: NodeMemoryAvailableLow
        expr: node_memory_MemAvailable_bytes / 1024 / 1024 < 100
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Доступная память меньше установленного порога"
          description: "Текущее значение: {{ $value }}, порог: 100Мб"

      - alert: NodeRAMUsageHigh
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024 > 1
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Затраченная память больше установленного порога"
          description: "Текущее значение: {{ $value }}, порог: 1Гб"

      - alert: ServiceCPUUsageHigh
        expr: sum by(container_label_com_docker_swarm_service_name) (rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name=~".+"}[1m]) * 100) > 10
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Использование CPU по сервису превышает 10%"
          description: "Сервис {{ $labels.container_label_com_docker_swarm_service_name }} использует {{ $value }}% CPU"
```

Разбор PromQL-выражений и структуры правил:
- **`NodeMemoryAvailableLow`**:
  - `expr: node_memory_MemAvailable_bytes / 1024 / 1024 < 100` — метрика `node_memory_MemAvailable_bytes` отдаётся `node_exporter` в байтах. Делением на $1024^2$ значение переводится в мегабайты и сравнивается с порогом `100 Мб`;
- **`NodeRAMUsageHigh`**:
  - `expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024 > 1` — занятая оперативная память вычисляется как разность между полным объёмом (`node_memory_MemTotal_bytes`) и доступным (`node_memory_MemAvailable_bytes`). Делением на $1024^3$ байты переводятся в гигабайты и сравниваются с порогом `1 Гб`;
- **`ServiceCPUUsageHigh`**:
  - `expr: sum by(container_label_com_docker_swarm_service_name) (rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name=~".+"}[1m]) * 100) > 10` — счётчик времени использования процессора контейнерами `container_cpu_usage_seconds_total` дифференцируется функцией `rate` на интервале в 1 минуту, умножается на 100% и суммируется по метке имени сервиса Swarm (`container_label_com_docker_swarm_service_name`). Если суммарная загрузка CPU контейнерами одного сервиса превышает 10% — условие выполняется;
- `for: 30s` — период гистерезиса: выражение должно выполняться непрерывно в течение 30 секунд (стадия `PENDING`), прежде чем алерт перейдёт в активную фазу `FIRING`. Это защищает от дребезга (*alert flapping*) при кратковременных пиках нагрузки;
- `labels: severity: critical` — метка критичности события для маршрутизации в Alertmanager;
- `annotations` — текстовые шаблоны для оповещений с динамической подстановкой значения метрики через `{{ $value }}` и меток через `{{ $labels... }}`.

> ⚠ **Особенности учёта метрик контейнеров в Docker Swarm** \
> В кластере Docker Swarm контейнеры каждого сервиса помечаются метаданными движка. Фильтр `{container_label_com_docker_swarm_service_name=~".+"}` отсекает вспомогательные и системные контейнеры без swarm-меток, а агрегация `sum by(container_label_com_docker_swarm_service_name)` корректно суммирует потребление ресурсов всеми запущенными репликами каждого сервиса.

---

### 3.3. Конфигурация роутинга и каналов оповещения (Email и Telegram)

Для приёма событий от Prometheus и их доставки адресатам создан конфигурационный файл `monitoring/alertmanager/config.yml`.

#### Подготовка каналов доставки

1. **Мессенджер Telegram**:
   - Через официального сервисного бота `@BotFather` создан новый бот командой `/newbot`, получен уникальный токен API: `8796556674:AAEqldTKnMio5b0c-rdZwtFBqqPz087GYN8`;
   - В диалоге с созданным ботом отправлена стартовая команда `/start`;
   - Получен постоянный числовой идентификатор личного чата (`chat_id: 282195596`) через вызов метода `getUpdates` Telegram Bot API:
     `https://api.telegram.org/bot8796556674:AAEqldTKnMio5b0c-rdZwtFBqqPz087GYN8/getUpdates`.

2. **Электронная почта (SMTP)**:
   - В качестве SMTP-сервера используется почтовый сервис Mail.ru:
     - Сервер исходящей почты: `smtp.mail.ru:465` (защищённое SSL/TLS-соединение);
     - Учётная запись отправителя: `roma_mishenko@mail.ru`;
     - Адрес получателя уведомлений: `roma_mishenko@mail.ru`.

> ⚠ **Аутентификация в современных почтовых сервисах (пароли для внешних приложений)** \
> Почтовые провайдеры (Mail.ru, Яндекс, Google) в целях безопасности запрещают прямую SMTP-аутентификацию по основному паролю учётной записи. Для работы Alertmanager в панели безопасности почтового ящика сгенерирован специальный **«Пароль для внешних приложений»** (типа «Почта/SMTP»), действующий только для почтовых протоколов.

#### Конфигурация Alertmanager (`monitoring/alertmanager/config.yml`)

```yaml
global:
  # Глобальные параметры аутентификации SMTP-клиента
  smtp_smarthost: 'smtp.mail.ru:465'
  smtp_from: 'roma_mishenko@mail.ru'
  smtp_auth_username: 'roma_mishenko@mail.ru'
  smtp_auth_password: '1RG1NPNIz20RkUVzmCNW'

route:
  # Основной маршрут: имя целевого ресивера по умолчанию
  receiver: 'DO9_alert'

  # Критерии группировки уведомлений (по названию алерта и уровню критичности)
  group_by: ['alertname', 'severity']

  # Временные интервалы группировки и отправки
  group_wait: 10s       # Пауза перед отправкой первого сообщения для сбора группы
  group_interval: 30s   # Интервал досылки новых алертов в уже активную группу
  repeat_interval: 3h   # Интервал повторной отправки неотпущенных алертов

receivers:
  - name: 'DO9_alert'
    # Канал отправки на Email
    email_configs:
      - to: 'roma_mishenko@mail.ru'
        send_resolved: true  # Отправка письма при устранении критической ситуации

    # Канал отправки в Telegram
    telegram_configs:
      - bot_token: '8796556674:AAEqldTKnMio5b0c-rdZwtFBqqPz087GYN8'
        chat_id: 282195596
        send_resolved: true  # Отправка уведомления при устранении аварии
        parse_mode: 'HTML'   # Режим разметки текста сообщения
```

где:
- `global` — секция с параметрами SMTP-сервера по умолчанию;
- `route` — дерево маршрутизации алертов. Параметр `group_by: ['alertname', 'severity']` группирует события в компактные блоки вместо отправки отдельного сообщения на каждый чих;
- `group_wait: 10s` — первичная буферизация: Alertmanager ждёт 10 секунд перед первой отправкой, чтобы собрать сопутствующие алерты;
- `group_interval: 30s` — периодичность отправки новых оповещений при расширении группы;
- `repeat_interval: 3h` — частота напоминаний о неразрешённом инциденте;
- `send_resolved: true` — включает отправку подтверждения восстановления сервиса (`RESOLVED`), когда значение метрики возвращается в норму;
- `parse_mode: 'HTML'` — использование HTML-разметки для удобного чтения сообщений в Telegram.

---

### 3.4. Тестирование и верификация доставки алертов

Проверим, что собранная цепочка мониторинга и оповещения работает корректно.

#### 1. Фиксация штатного срабатывания алерта `NodeRAMUsageHigh`

Поскольку на хосте одновременно запущены сервисы бронирования отелей и весь контур наблюдаемости (Prometheus, Grafana, Loki, cAdvisor, Node Exporter, Alertmanager), занятый объём оперативной памяти узла составляет ~3.9 Гб, что стабильно превышает установленный порог в `1 Гб`.

Через 30 секунд непрерывного превышения лимита правило переходит в статус `FIRING`.

- **Веб-интерфейс Prometheus (`http://localhost:9090/alerts`)**:
  В интерфейсе Prometheus видна активная группа `DO9` с правилом `NodeRAMUsageHigh` в статусе `FIRING (1)`. Два других правила (`NodeMemoryAvailableLow` и `ServiceCPUUsageHigh`) находятся в статусе `INACTIVE (2)`.

> Статус правил алертинга в веб-интерфейсе Prometheus \
![Статус алертов в Prometheus](<screenshot/Screenshot 2026-09-14 at 09.47.45.png>)

- **Веб-интерфейс Alertmanager (`http://localhost:9093`)**:
  В Alertmanager зарегистрирована активная группа `DO9_alert` с алертом `alertname="NodeRAMUsageHigh"`, метками `instance="node_exporter:9100"` и уровнем важности `critical`.

> Список активных алертов в интерфейсе Alertmanager \
![Алерты в Alertmanager](<screenshot/Screenshot 2026-09-14 at 09.48.41.png>)

- **Доставка почтового оповещения (Email)**:
  На адрес `roma_mishenko@mail.ru` пришло письмо с темой `[FIRING:1] NodeRAMUsageHigh critical (node_exporter:9100 node_exporter)`. В теле сообщения — детализация: `Текущее значение: 3.9154815673828125, порог: 1Гб`.

> Почтовое уведомление о превышении использования оперативной памяти \
![Email-уведомление NodeRAMUsageHigh](<screenshot/Screenshot 2026-09-14 at 09.46.18.png>)

- **Доставка сообщения в Telegram**:
  В диалог с ботом в Telegram пришло сообщение с блоком `Alerts Firing`, метками хоста и ссылкой на график в Prometheus.

> Уведомление о срабатывании алерта NodeRAMUsageHigh в Telegram-боте \
![Telegram-уведомление NodeRAMUsageHigh](<screenshot/Screenshot 2026-09-14 at 09.46.49.png>)

---

#### 2. Комплексная проверка алертов `NodeMemoryAvailableLow` и `ServiceCPUUsageHigh`

В обычном режиме работы:
- Доступный объём памяти узла составляет ~3.9 Гб (значительно выше критического порога в 100 Мб);
- Загрузка процессора сервисами в среднем — 1–4% (ниже критического порога в 10%).

> **Справка: методология безопасного тестирования пороговых правил алертинга** \
> Для проверки правил с высокими порогами срабатывания есть два подхода:
> 1. *Искусственная генерация нагрузки* — запуск утилит стресс-тестирования (`stress-ng`, `sysbench`) для исчерпания памяти и загрузки CPU. Минус метода: риск нестабильности хоста и непреднамеренного завершения процессов из-за OOM-killer;
> 2. *Временная адаптация пороговых значений* — временная корректировка лимитов в конфигурационном файле под текущие параметры системы для проверки цепочки доставки сообщений с последующим возвратом штатных значений.

Выбран безопасный метод временной адаптации порогов. В файле `monitoring/prometheus/rules.yml` временно изменены значения:
- `NodeMemoryAvailableLow`: порог поднят до `< 5000` Мб (при текущих ~3914 Мб свободной памяти правило гарантированно сработает);
- `ServiceCPUUsageHigh`: порог снижен до `> 1%` (сервисы `cadvisor` и `grafana` потребляют 1.4–3.8% CPU).

Применяем обновлённые правила, принудительно перезапустив контейнер Prometheus:

```sh
docker service update --force monitoring_prometheus
```

где:
- `docker service update` — команда оркестратора Docker Swarm для обновления параметров сервиса;
- `--force` — флаг принудительного перезапуска контейнеров сервиса для повторного считывания примонтированных файлов конфигурации;
- `monitoring_prometheus` — имя сервиса Prometheus в стеке.

> Принудительный перезапуск сервиса Prometheus для перечитывания правил \
![Обновление сервиса Prometheus](<screenshot/Screenshot 2026-09-14 at 09.53.07.png>)

##### Верификация срабатывания полного набора алертов:

1. **Веб-интерфейс Prometheus (`http://localhost:9090/alerts`)**:
   Все три правила перешли в статус `FIRING (3)`:
   - `NodeMemoryAvailableLow`: FIRING (1)
   - `NodeRAMUsageHigh`: FIRING (1)
   - `ServiceCPUUsageHigh`: FIRING (2) — превышение порога в 1% зафиксировано для сервисов `monitoring_cadvisor` и `monitoring_grafana`.

> Все три правила в активном статусе FIRING в интерфейсе Prometheus \
![Все три правила в Prometheus](<screenshot/Screenshot 2026-09-14 at 09.55.22.png>)

2. **Веб-интерфейс Alertmanager (`http://localhost:9093`)**:
   В интерфейсе Alertmanager сформированы три активные группы оповещений.

> Активные группы алертов в Alertmanager \
![Все группы в Alertmanager](<screenshot/Screenshot 2026-09-14 at 09.55.29.png>)

3. **Оповещения в Telegram**:
   Telegram-бот прислал сообщения по обоим новым событиям:
   - Превышение загрузки процессора сервисами `monitoring_cadvisor` (3.85% CPU) и `monitoring_grafana` (1.42% CPU);
   - Снижение доступной памяти: `Текущее значение: 3914.421875, порог: 5000Мб`.

> Доставка оповещений о загрузке CPU и нехватке памяти в Telegram \
![Оповещения в Telegram](<screenshot/Screenshot 2026-09-14 at 09.55.40.png>)

4. **Оповещения по Email**:
   На почту пришло два письма по сработавшим инцидентам:
   - Письмо `2 alerts for alertname=ServiceCPUUsageHigh severity=critical` с подробной информацией о нагрузке от `cadvisor` и `grafana`;
   - Письмо `1 alert for alertname=NodeMemoryAvailableLow severity=critical`.

> Email-уведомление о превышении нагрузки CPU сервисами \
![Email ServiceCPUUsageHigh](<screenshot/Screenshot 2026-09-14 at 09.55.54.png>)

> Email-уведомление о падении объёма доступной памяти \
![Email NodeMemoryAvailableLow](<screenshot/Screenshot 2026-09-14 at 09.55.59.png>)

---

#### 3. Возврат штатной конфигурации правил

После завершения тестирования и подтверждения доставки всех типов уведомлений параметры в `monitoring/prometheus/rules.yml` возвращены к исходным проектным значениям:
- `NodeMemoryAvailableLow`: порог `< 100` Мб;
- `ServiceCPUUsageHigh`: порог `> 10` %.

Применяем штатную конфигурацию:

```sh
docker service update --force monitoring_prometheus
```
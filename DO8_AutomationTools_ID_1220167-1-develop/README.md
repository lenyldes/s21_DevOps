```markdown
# Автоматизация конфигурации инфраструктуры и Service Discovery: Ansible и HashiCorp Consul (Infrastructure Automation, Configuration Management with Ansible & Service Discovery with HashiCorp Consul)

[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![HashiCorp Consul](https://img.shields.io/badge/HashiCorp%20Consul-F24C53?style=for-the-badge&logo=consul&logoColor=white)](https://www.consul.io/)
[![Envoy Proxy](https://img.shields.io/badge/Envoy%20Proxy-E14D43?style=for-the-badge&logo=envoyproxy&logoColor=white)](https://www.envoyproxy.io/)
[![Vagrant](https://img.shields.io/badge/Vagrant-1563FF?style=for-the-badge&logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Apache HTTP Server](https://img.shields.io/badge/Apache%20HTTP%20Server-D22128?style=for-the-badge&logo=apache&logoColor=white)](https://httpd.apache.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Postman](https://img.shields.io/badge/Postman-FF6C37?style=for-the-badge&logo=postman&logoColor=white)](https://www.postman.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu%2024.04%20LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)](#)

Проект — про проектирование, развёртывание и автоматизацию распределённой гетерогенной серверной инфраструктуры с помощью **Ansible**, а также реализацию отказоустойчивого Service Discovery с динамическим управлением сетевой связностью (Service Mesh) на базе **HashiCorp Consul** и **Envoy Proxy**. В рамках работы собраны два многоузловых изолированных стенда на **HashiCorp Vagrant** и гипервизоре **Oracle VirtualBox** под управлением **Ubuntu 24.04 LTS**.

В первом сценарии реализован безагентный декларативный провижининг целевых серверов по SSH, декомпозиция монолитных плейбуков на модульные идемпотентные роли Ansible (`application`, `apache`, `postgres`), автоматическая установка Docker Engine, оркестрация девятикомпонентного микросервисного стека через Docker Compose, а также развёртывание веб-сервера Apache HTTP Server и СУБД PostgreSQL с настройкой сетевого доступа. Во втором сценарии развёрнут распределённый кластер HashiCorp Consul (Server + Clients) на алгоритме консенсуса Raft и протоколе Serf LAN Gossip. Поверх кластера настроен Service Mesh с sidecar-прокси Envoy, mTLS-шифрованием трафика, регистрацией сервиса бронирования отелей (Spring Boot, Java 21) и СУБД PostgreSQL, health checks и подтверждённой устойчивостью к динамической миграции IP-адресов серверов в режиме Zero-Downtime. Корректность работы всей инфраструктуры подтверждена сквозным тестированием через Postman и Newman.

---

## О проекте

Современные распределённые системы требуют воспроизводимых окружений, быстрого развёртывания и надёжного межсервисного взаимодействия. Этот проект решает ключевые задачи системного администрирования и эксплуатации:

### 1. Проблематика ручной настройки и «дрейфа конфигураций» (Configuration Drift)
При ручной настройке серверов через терминал неизбежно накапливаются расхождения между test-, staging- и production-окружениями: разные версии утилит, неучтённые переменные окружения, рассинхронизированные правила файрвола, несовпадающие версии системных библиотек. Такой «дрейф конфигураций» приводит к ошибкам, которые невозможно воспроизвести локально, увеличивает время восстановления после сбоев (MTTR) и усложняет масштабирование инфраструктуры.

### 2. Принципы Infrastructure as Code (IaC) и идемпотентность в Ansible
Парадигма Infrastructure as Code переводит управление вычислительными ресурсами в плоскость версионируемых текстовых манифестов. В основе Ansible — **декларативность** и **идемпотентность**: администратор описывает желаемое состояние системы (какие пакеты установлены, какие службы запущены, какие права выставлены на файлы), а Ansible сам определяет необходимые действия. Повторный запуск плейбука на уже настроенной системе завершается со статусом `ok=... changed=0` — без побочных эффектов.

### 3. Безагентная архитектура (Agentless via SSH)
В отличие от Chef, Puppet или SaltStack, где на каждом узле нужно ставить, обновлять и мониторить специализированных агентов, Ansible использует стандартный OpenSSH и системный Python. Это экономит оперативную память, не требует открытия дополнительных служебных портов и снижает поверхность атаки на хосты.

### 4. Необходимость Service Discovery в микросервисных архитектурах
В монолите межмодульные вызовы происходят локально в памяти, а подключение к БД настраивается через статический IP или DNS. В микросервисах с десятками независимых контейнеров, динамическим автомасштабированием, перезапусками при сбоях и миграцией между гипервизорами жёстко зафиксированные IP-адреса приводят к мгновенной деградации при любом изменении топологии. **Service Discovery** решает это через централизованный динамический реестр сервисов (Service Registry), автоматическую регистрацию экземпляров при старте, непрерывный контроль жизнеспособности (Health Checking) и выдачу актуальных эндпоинтов через DNS или HTTP API.

### 5. Консенсус Raft и gossip-протокол Serf в HashiCorp Consul
HashiCorp Consul реализует двухуровневую сетевую модель высокой доступности:
- **Serf Gossip (протокол SWIM):** децентрализованный обмен сообщениями по UDP/TCP (порт `8301`). Каждый узел периодически зондирует случайных соседей, что обеспечивает быстрое (субсекундное) обнаружение отказов без квадратичной нагрузки на центральные серверы.
- **Алгоритм консенсуса Raft:** обеспечивает строгую согласованность (strong consistency) для сервис-каталога и хранилища Key-Value (порт `8300`). Серверный кластер проводит автоматические выборы лидера (Leader Election) и реплицирует журнал между узлами-участниками.

### 6. Концепция Service Mesh на базе Envoy Proxy
Технология **Consul Connect** превращает Consul в Control Plane для распределённого Service Mesh. Роль Data Plane берёт на себя **Envoy Proxy**, запускаемый как sidecar-процесс рядом с каждым сервисом. Приложения обращаются только к локальному loopback-интерфейсу (`127.0.0.1`), а Envoy перехватывает трафик, запрашивает актуальные маршруты у локального Consul Client через постоянный gRPC-канал (порт `8502`, протокол xDS) и передаёт данные целевому сервису через защищённый туннель с взаимной аутентификацией (mTLS). Перенос базы данных на другой IP становится прозрачным для клиентского микросервиса: маршрут обновляется на лету — без изменения кода и без перезапуска приложений.

---

## Ключевые навыки и освоенные концепции

### Part 1. Управление конфигурацией через Ansible

- **Декларативное управление инфраструктурой:** проектирование инвентаря `inventory.ini` с логическим разделением хостов на группы (`[managers]`, `[nodes]`), фиксацией системного интерпретатора `ansible_python_interpreter=/usr/bin/python3` — чтобы убрать недетерминированное автоопределение и предупреждения Ansible.
- **Организация безагентного транспорта:** генерация SSH-ключей на управляющем узле `manager`, автоматизированный экспорт публичных ключей через `ssh-copy-id` на целевые узлы `node01` и `node02`, проверка сетевой доступности модулем `ansible.builtin.ping`.
- **Практическое владение библиотекой модулей Ansible:**
  - `ansible.builtin.apt` и `ansible.builtin.deb822_repository` — управление репозиториями нового формата Debian 822 и установка пакетов;
  - `ansible.builtin.get_url` — безопасная загрузка официальных GPG-ключей для подписи пакетов;
  - `ansible.builtin.file` — создание каталогов, управление правами доступа и владельцами;
  - `ansible.builtin.copy` и `ansible.builtin.unarchive` — оптимизированная доставка файлов и распаковка исходников;
  - `ansible.builtin.user` — добавление системных пользователей в служебные группы (включение в группу `docker`);
  - `ansible.builtin.service` / `ansible.builtin.systemd` — запуск, перезапуск и включение демонов в автозагрузку;
  - `ansible.builtin.lineinfile` — потоковое редактирование конфигурационных файлов ОС и сервисов с помощью регулярных выражений.
- **Оптимизация передачи файлов по сети:** выявлена проблема деградации скорости модуля `ansible.builtin.copy` при обработке тысяч мелких файлов исходников Java/Maven (посегментный расчёт контрольных сумм MD5/SHA256 по SSH) — решена переходом на предварительную архивацию (`tar.gz`) с потоковой распаковкой модулем `ansible.builtin.unarchive` прямо на целевом хосте.
- **Архитектурная декомпозиция на Ansible Roles:** линейный монолитный плейбук разбит на повторно используемые роли:
  - `application`: подготовка среды Docker Engine, сборка образов, запуск 9 микросервисов стека через Docker Compose;
  - `apache`: развёртывание и контроль состояния веб-сервера Apache HTTP Server;
  - `postgres`: установка СУБД PostgreSQL, настройка прослушивания внешних интерфейсов `listen_addresses = '*'` в `postgresql.conf`, разрешение клиентских подсетей в `pg_hba.conf`, автоматическое создание тестовой базы `testbd` и наполнение таблицы `Person`.
- **Автоматизация сквозного тестирования:** запуск консольного раннера **Newman** внутри эфемерного Docker-контейнера в режиме сети `--network host` для прогона интеграционных тестов Postman по API Gateway и Session Service.

### Part 2. Service Discovery и Service Mesh на базе HashiCorp Consul

- **Проектирование топологии Service Discovery:** физическое и логическое разделение узлов на управляющий сервер Consul (`consulServer`) и целевые клиенты (`api`, `db`).
- **Конфигурирование в нотации HCL (HashiCorp Configuration Language):**
  - Серверный режим (`consul_server.hcl`): директивы `server = true`, `bootstrap_expect = 1` для инициализации кворума Raft, включение встроенного веб-интерфейса `ui_config { enabled = true }`, привязка к адаптерам через сетевые макросы шаблонизатора Go `{{ GetInterfaceIP "eth1" }}`;
  - Клиентский режим (`consul_client.hcl`): отключение серверных функций `server = false`, автоматическое присоединение к кластеру через `retry_join = ["192.168.56.10"]`, активация gRPC-интерфейса на порту `8502` для передачи xDS-конфигураций прокси.
- **Регистрация сервисов и интеграция Service Mesh (Consul Connect):**
  - Декларативное описание сервисов через манифесты `/etc/consul.d/*.hcl`;
  - Настройка блока `connect { sidecar_service {} }` для СУБД `db` (порт `5432`);
  - Настройка входящих и исходящих зависимостей (`upstreams`) для сервиса `hotel-service` с пробросом виртуального локального порта `local_bind_port = 5432` к удалённой БД через mTLS.
- **Оркестрация sidecar-прокси Envoy:**
  - Разработка systemd-юнитов `consul-envoy.service` с командой автоматической инициализации `consul connect envoy -sidecar-for=<service>`;
  - Диагностика и устранение версионных несовместимостей: анализ журналов `journalctl`, выявление несовместимости Consul 2.0 CE с Envoy 1.39.x, интеграция загрузки бинарного релиза **Envoy v1.38.4** в плейбук Ansible.
- **Декларативное управление PostgreSQL через коллекцию `community.postgresql`:**
  - Отказ от нестабильных вызовов командной оболочки `shell`/`psql` в пользу модулей `community.postgresql.postgresql_db` и `community.postgresql.postgresql_user`;
  - Разрешение зависимостей Python: установка драйвера `python3-psycopg2` и пакета `acl` для безопасного переключения контекста на непривилегированного системного пользователя `postgres` (`become_user: postgres`).
- **Сборка и оркестрация Java Spring Boot микросервиса:**
  - Автоматизация установки OpenJDK 21 и Apache Maven;
  - Сборка исполняемого jar-архива через Maven Wrapper с параметром `creates` для предотвращения лишних пересборок;
  - Проектирование systemd-сервиса `hotels.service` с зависимостями `After=consul-envoy.service` и `Requires=consul-envoy.service`, чтобы приложение не запускалось до готовности сетевого прокси;
  - Изоляция конфигурации БД в `/etc/environment` (`POSTGRES_HOST="127.0.0.1"`).
- **Экспериментальное подтверждение динамического Service Discovery:**
  - Имитация сетевой аварии и перемещения узла БД: ручная смена IP-адреса хоста `db` на `192.168.56.99`;
  - Фиксация моментального автообновления сервис-каталога Consul через Serf Gossip;
  - Демонстрация безошибочной обработки пользовательских CRUD-запросов клиентом `hotel-service` — без перезапуска приложения и без правок в конфигурационных файлах.

---

## Архитектура и стек технологий

### 1. Топология стенда Part 1 (Ansible Automation Stack)

Стенд Part 1 заточен под отработку методологии централизованного безагентного конфигурирования серверов. Хост `manager` — единый центр управления (Control Node), взаимодействующий с целевыми серверами через закрытую виртуальную сеть `192.168.56.0/24`.

```text
+--------------------------------------------------------------------------------------------------------+
|                                        ХОСТОВАЯ СИСТЕМА (HOST)                                         |
|                                                                                                        |
|   +----------------------------------------------------+   +---------------------------------------+   |
|   |         Newman / Postman Тестирование API          |   |          Web Browser / cURL           |   |
|   |      (GET/POST на 127.0.0.1:8081 и 8087)           |   |         (HTTP на 192.168.56.12)        |   |
|   +-------------------------+--------------------------+   +-------------------+-------------------+   |
|                             | Проброс портов (NAT)                             |                       |
|                             | (8081->8081, 8087->8087)                         |                       |
+-----------------------------|--------------------------------------------------|-----------------------+
                              |                                                  |
==============================|====== ПРИВАТНАЯ СЕТЬ VAGRANT (192.168.56.0/24) ==|=======================
                              |                                                  |
+-----------------------------v------+   SSH (ansible-playbook)    +-------------v-----------------------+
|  manager (192.168.56.10)           |---------------------------->|  node02 (192.168.56.12)             |
|  Ansible Control Node              |                             |  Web Server & Database              |
|  - Ubuntu 24.04 LTS                |----+                        |  - Apache HTTP Server (Port 80)     |
|  - Python 3.12 + Ansible Core      |    |                        |  - PostgreSQL 16 (Port 5432)        |
|  - SSH Keypair (id_ed25519)        |    |                        |    * База данных: testbd            |
|  - Inventory & Roles Repository    |    |                        |    * Таблица: Person                |
+------------------------------------+    |                        +-------------------------------------+
                                          |
                                          | SSH (ansible-playbook)
                                          v
                              +--------------------------------------------------+
                              |  node01 (192.168.56.11)                          |
                              |  Docker Microservices Host                       |
                              |  - Ubuntu 24.04 LTS, Docker CE Engine            |
                              |  - Docker Compose Stack (9 сервисов):            |
                              |    * nginx-proxy (Ports 8081, 8087)              |
                              |    * session-service, gateway-service            |
                              |    * booking-service, hotel-service              |
                              |    * payment-service, loyalty-service            |
                              |    * report-service                              |
                              |    * rabbitmq (Message Broker)                   |
                              |    * postgres (users_db, reservations_db)        |
                              +--------------------------------------------------+
```

#### Спецификация виртуальных машин Part 1

| Имя ВМ | Hostname | Приватный IP | vCPU | RAM | Проброс портов (Host -> Guest) | Назначение и запускаемые компоненты |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **manager** | `manager` | `192.168.56.10` | 2 | 2048 MB | — | Станция управления Ansible, OpenSSH Client, репозиторий плейбуков и ролей |
| **node01** | `node01` | `192.168.56.11` | 1 | 1024 MB | `8081:8081`<br>`8087:8087` | Хост микросервисов: Docker Engine, Docker Compose, 9 контейнеров приложения |
| **node02** | `node02` | `192.168.56.12` | 1 | 1024 MB | — | Хост инфраструктурных сервисов: Apache HTTP Server (80), PostgreSQL 16 (5432) |

---

### 2. Топология стенда Part 2 (Consul Service Discovery & Mesh Stack)

Стенд Part 2 реализует архитектуру Service Mesh с динамическим обнаружением сервисов. Приложение `hotel-service` абстрагировано от реального расположения базы данных `hotels_db`. Весь межсервисный трафик проксируется через пару локальных процессов Envoy, синхронизируемых сервером Consul.

```text
+--------------------------------------------------------------------------------------------------------+
|                                        ХОСТОВАЯ СИСТЕМА (HOST)                                         |
|                                                                                                        |
|       +------------------------------------+           +---------------------------------------+       |
|       |     Consul Web UI / HTTP API       |           |          Postman / Newman / cURL      |       |
|       |       http://localhost:8500        |           |          http://localhost:8082        |       |
|       +-----------------+------------------+           +-------------------+-------------------+       |
+-------------------------|--------------------------------------------------|---------------------------+
                          | Порт 8500 (NAT)                                  | Порт 8082 (NAT)
==========================|====== ПРИВАТНАЯ СЕТЬ VAGRANT (192.168.56.0/24) ==|==========================
                          |                                                  |
+-------------------------v----------+                                       |
|  consulServer (192.168.56.10)      |                                       |
|  - Consul Server Agent (Raft Lead) |                                       |
|  - Web UI & HTTP Catalog API: 8500 |                                       |
|  - Raft Consensus RPC: 8300        |                                       |
|  - Serf LAN Gossip: 8301           |                                       |
+-----------------+------------------+                                       |
                  ^                                                          |
                  | Serf Gossip LAN / Raft RPC Sync                          |
                  v                                                          |
+-----------------+------------------+                   +-------------------v-------------------+
|  api (192.168.56.11)               |                   |  db (192.168.56.13)                   |
|  - Consul Client Agent             |                   |  - Consul Client Agent                |
|    * Serf LAN Gossip (8301)        |                   |    * Serf LAN Gossip (8301)           |
|    * xDS gRPC Server (Port 8502)   |                   |    * xDS gRPC Server (Port 8502)      |
|                                    |                   |                                       |
|  +------------------------------+  |                   |  +---------------------------------+  |
|  | Hotels Service (Spring Boot) |  |                   |  | PostgreSQL Server (Port 5432)   |  |
|  | - Port: 8082 (REST API)      |  |                   |  | - База данных: hotels_db        |  |
|  | - POSTGRES_HOST: 127.0.0.1   |  |                   |  | - Пользователь: postgres        |  |
|  +--------------+---------------+  |                   |  +----------------^----------------+  |
|                 |                  |                   |                   |                   |
|                 | SQL Запросы      |                   |                   | Локальная         |
|                 | (порт 5432)      |                   |                   | доставка          |
|                 v                  |                   |                   |                   |
|  +------------------------------+  |  Зашифрованный    |  +----------------+----------------+  |
|  | Envoy Sidecar Proxy          |==|== mTLS-туннель ===|=>| Envoy Sidecar Proxy             |  |
|  | - Upstream: db -> 5432       |  |  (порт Envoy)     |  | - Ingress для сервиса db        |  |
|  | - Dynamic xDS via Consul     |  |                   |  | - Dynamic xDS via Consul        |  |
|  +------------------------------+  |                   |  +---------------------------------+  |
+------------------------------------+                   +---------------------------------------+
                  ^                                                          ^
                  |                                                          |
                  +---------------------[ manager ]--------------------------+
                                     (192.168.56.12)
                                   Ansible Control Node
```

#### Спецификация виртуальных машин Part 2

| Имя ВМ | Hostname | Приватный IP | vCPU | RAM | Проброс портов (Host -> Guest) | Назначение и запускаемые компоненты |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **consulServer** | `consulServer` | `192.168.56.10` | 1 | 1024 MB | `8500:8500` | Серверный узел Consul: лидер консенсуса Raft, каталог сервисов, Consul Web UI |
| **api** | `api` | `192.168.56.11` | 1 | 1024 MB | `8082:8082` | Микросервис отелей (Spring Boot 3, Java 21), Consul Client, Envoy Sidecar Proxy |
| **manager** | `manager` | `192.168.56.12` | 1 | 1024 MB | — | Станция управления Ansible, OpenSSH Client, репозиторий плейбуков `ansible02` |
| **db** | `db` | `192.168.56.13` *(миграция на `.99`)* | 1 | 1024 MB | — | СУБД PostgreSQL (`hotels_db`), Consul Client, Envoy Sidecar Ingress Proxy |

#### Поток трафика и жизненный цикл запроса в Service Mesh

1. **Инициализация соединения:** Java-приложение `hotel-service` на узле `api` подключается к СУБД по стандартному адресу `127.0.0.1:5432`, считанному из `/etc/environment`.
2. **Перехват локальным прокси:** Локальный Envoy Sidecar на узле `api` слушает порт `5432` и перехватывает исходящее TCP-соединение.
3. **Динамический резолвинг адреса (Control Plane xDS):** Envoy запрашивает актуальный адрес апстрима `db` у локального агента Consul Client по gRPC-каналу (порт `8502`).
4. **Репликация каталога:** Consul Client непрерывно синхронизирует состояние сервисов с лидером кластера `consulServer` по gossip-протоколу Serf LAN.
5. **Защищённая передача данных:** Локальный Envoy устанавливает зашифрованный туннель с взаимной аутентификацией (mTLS) к удалённому Envoy на узле `db`.
6. **Локальная доставка в СУБД:** Envoy на узле `db` валидирует сертификат клиента, расшифровывает поток данных и транслирует SQL-запросы на локальный сокет PostgreSQL `127.0.0.1:5432`.
7. **Поведение при смене IP базы данных:** При смене IP-адреса ноды `db` с `192.168.56.13` на `192.168.56.99` Serf LAN моментально оповещает кластер. Сервер Consul обновляет каталог, а агент Consul Client на ноде `api` через xDS на лету перестраивает маршрут в памяти Envoy. Приложение продолжает работать без сбоев (Zero-Downtime).

---

### Сводная таблица стека технологий

| Категория | Инструмент / Технология | Версия | Назначение в проекте |
| :--- | :--- | :--- | :--- |
| **Оркестрация виртуализации** | HashiCorp Vagrant | 2.x | Декларативное описание стендов, виртуальных сетей и проброса портов |
| **Гипервизор** | Oracle VirtualBox | 7.x | Аппаратная виртуализация вычислительных узлов |
| **Базовая ОС узлов** | Ubuntu Server LTS | 24.04 (Noble) | Официальный базовый образ `bento/ubuntu-24.04` (v202510.26.0) |
| **Управление конфигурациями** | Ansible Core | 2.16+ / Python 3.12 | Безагентный провижининг узлов, плейбуки, идемпотентные роли |
| **Контейнеризация** | Docker Engine & Compose | 26.x / Compose v2 | Контейнеризация и запуск девятикомпонентного микросервисного стека |
| **Service Discovery & Mesh** | HashiCorp Consul | 2.0.x CE | Распределённый сервис-каталог, Serf LAN Gossip, Raft консенсус, Web UI |
| **Data Plane Proxy** | Envoy Proxy | 1.38.4 | Sidecar-прокси для Consul Connect, организация mTLS-туннелей |
| **Реляционная СУБД** | PostgreSQL | 16.x | Хранилище данных микросервисов (`testbd`, `hotels_db`) |
| **Веб-сервер** | Apache HTTP Server | 2.4.x | Тестовый веб-сервер общего назначения на узле `node02` |
| **Стек микросервисов** | Spring Boot / Java | JDK 21 / Maven 3 | REST API сервисы (Hotels, Gateway, Session и др.) |
| **Брокер сообщений** | RabbitMQ | 3-management | Асинхронное взаимодействие микросервисов в Docker Compose |
| **Тестирование и валидация** | Postman / Newman | CLI Docker Runner | Автоматизированный прогон интеграционных коллекций тестов |

---

## Структура проекта и реализованные модули

Исходники, конфиги и скрипты развёртывания лежат в `src/`:

```
.
├── README.md                                             # Документация проекта
├── README_RUS.md                                         # Исходное учебное задание
└── src/
    ├── Vagrantfile                                       # Vagrant-конфиг многоузлового стенда
    ├── REPORT.MD                                         # Технический отчёт с иллюстрациями
    ├── docker-compose.yml                                # Docker Compose-стек микросервисов Part 1
    ├── application_tests.postman_collection.json         # Коллекция тестов Postman
    ├── ansible01/                                        # Автоматизация Part 1 (Ansible)
    │   ├── inventory.ini                                 # Инвентори (manager, node01, node02)
    │   ├── playbook.yml                                  # Главный плейбук развёртывания ролей
    │   └── roles/                                        # Роли Ansible
    │       ├── application/                              # Установка Docker и запуск микросервисов
    │       │   ├── defaults/main.yml                     # Переменные по умолчанию (docker_user)
    │       │   └── tasks/main.yml                        # Установка Docker CE и сборка Compose
    │       ├── apache/                                   # Развёртывание Apache HTTP Server
    │       │   └── tasks/main.yml                        # Установка и запуск apache2
    │       └── postgres/                                 # СУБД PostgreSQL
    │           └── tasks/main.yml                        # Настройка сетевого доступа и инициализация БД
    ├── consul01/                                         # Конфиги HashiCorp Consul (HCL)
    │   ├── consul_server.hcl                             # Конфиг сервера Consul (Raft, Web UI, bootstrap)
    │   └── consul_client.hcl                             # Конфиг клиента Consul (gRPC 8502, retry_join)
    ├── ansible02/                                        # Service Discovery Part 2 (Consul & Envoy)
    │   ├── inventory.ini                                 # Инвентори (consulServer, api, manager, db)
    │   ├── playbook.yml                                  # Главный плейбук Service Discovery
    │   └── roles/                                        # Роли Ansible
    │       ├── install_consul_server/                    # Развёртывание и запуск сервера Consul
    │       │   ├── tasks/main.yml                        # Установка пакета, репозитория и systemd-службы
    │       │   └── handlers/main.yml                     # Хэндлер перезапуска consul
    │       ├── install_consul_client/                    # Развёртывание агентов Consul и Envoy Sidecar
    │       │   ├── files/                                # Манифесты сервисов и systemd-юниты
    │       │   │   ├── api_service.hcl                   # Регистрация hotel-service с upstream к db
    │       │   │   ├── db_service.hcl                    # Регистрация сервиса db с sidecar_service
    │       │   │   ├── consul-envoy-db.service           # systemd-юнит sidecar-прокси БД
    │       │   │   └── consul-envoy-holel.service        # systemd-юнит sidecar-прокси микросервиса отелей
    │       │   ├── tasks/main.yml                        # Установка Consul, бинарника Envoy 1.38.4, systemd
    │       │   └── handlers/main.yml                     # Хэндлер перезапуска consul
    │       ├── install_db/                               # Идемпотентное развёртывание PostgreSQL
    │       │   └── tasks/main.yml                        # community.postgresql (hotels_db, пароли, acl)
    │       └── install_hotels_service/                   # Сборка и запуск Spring Boot-микросервиса
    │           ├── files/hotels.service                  # systemd-юнит с зависимостью от consul-envoy
    │           └── tasks/main.yml                        # JDK 21, Maven, сборка jar, экспорт переменных
    └── services/                                         # Исходники микросервисов (Java Spring Boot)
        ├── booking-service/
        ├── database/
        ├── gateway-service/
        ├── hotel-service/
        ├── loyalty-service/
        ├── nginx/
        ├── payment-service/
        ├── report-service/
        └── session-service/
```

### Сводная таблица конфигурационных файлов

| Относительный путь к файлу | Назначение файла | Применяемые модули / Директивы / Технологии |
| :--- | :--- | :--- |
| [./src/Vagrantfile](./src/Vagrantfile) | Конфигурация виртуальных машин кластера | Ruby DSL, `config.vm.define`, `private_network`, `forwarded_port`, VirtualBox provider |
| [./src/docker-compose.yml](./src/docker-compose.yml) | Контейнерный стек Part 1 | Docker Compose v2, 9 сервисов, healthcheck, volume mounts, ports mapping |
| [./src/application_tests.postman_collection.json](./src/application_tests.postman_collection.json) | Сквозные тесты API | Postman Schema v2.1.0, Newman CLI, Basic Auth, JWT Bearer Token, Assertions |
| [./src/REPORT.MD](./src/REPORT.MD) | Технический отчёт по этапам работ | Markdown, документирование инцидентов, анализ журналов, снимки экрана |
| [./src/ansible01/inventory.ini](./src/ansible01/inventory.ini) | Инвентори стенда Part 1 | INI формат, группы `[managers]`, `[nodes]`, переменная `ansible_python_interpreter` |
| [./src/ansible01/playbook.yml](./src/ansible01/playbook.yml) | Плейбук развёртывания Part 1 | YAML, `hosts`, `become: yes`, подключение ролей `application`, `apache`, `postgres` |
| [./src/ansible01/roles/application/defaults/main.yml](./src/ansible01/roles/application/defaults/main.yml) | Переменные по умолчанию роли приложения | `docker_user: "{{ ansible_user }}"` |
| [./src/ansible01/roles/application/tasks/main.yml](./src/ansible01/roles/application/tasks/main.yml) | Установка Docker и развёртывание Compose | `deb822_repository`, `apt`, `user`, `file`, `copy`, `unarchive`, `command` |
| [./src/ansible01/roles/apache/tasks/main.yml](./src/ansible01/roles/apache/tasks/main.yml) | Установка веб-сервера Apache | `ansible.builtin.apt`, `ansible.builtin.service` (apache2) |
| [./src/ansible01/roles/postgres/tasks/main.yml](./src/ansible01/roles/postgres/tasks/main.yml) | Настройка PostgreSQL и сетевого доступа | `apt`, `service`, `shell` (psql), `lineinfile` (`postgresql.conf`, `pg_hba.conf`) |
| [./src/consul01/consul_server.hcl](./src/consul01/consul_server.hcl) | Конфиг сервера HashiCorp Consul | HCL, `server = true`, `bootstrap_expect = 1`, `ui_config`, `{{ GetInterfaceIP "eth1" }}` |
| [./src/consul01/consul_client.hcl](./src/consul01/consul_client.hcl) | Конфиг клиента HashiCorp Consul | HCL, `server = false`, `retry_join`, `ports { grpc = 8502 }`, dynamic advertise IP |
| [./src/ansible02/inventory.ini](./src/ansible02/inventory.ini) | Инвентори стенда Part 2 | Группы `[api_servers]`, `[db_servers]`, `[consul_servers]`, `[consul_clients]` |
| [./src/ansible02/playbook.yml](./src/ansible02/playbook.yml) | Плейбук развёртывания Part 2 | Таргетинг ролей по группам: Consul Server, Consul Client, DB, Hotels Service |
| [./src/ansible02/roles/install_consul_server/tasks/main.yml](./src/ansible02/roles/install_consul_server/tasks/main.yml) | Установка и запуск сервера Consul | `get_url` (HashiCorp GPG), `deb822_repository`, `apt`, `copy`, `systemd` |
| [./src/ansible02/roles/install_consul_server/handlers/main.yml](./src/ansible02/roles/install_consul_server/handlers/main.yml) | Хэндлер перезапуска сервера | `ansible.builtin.systemd` (перезапуск службы `consul`) |
| [./src/ansible02/roles/install_consul_client/files/api_service.hcl](./src/ansible02/roles/install_consul_client/files/api_service.hcl) | Регистрация API отелей в каталоге сервисов | HCL, `service`, `connect { sidecar_service { proxy { upstreams } } }` |
| [./src/ansible02/roles/install_consul_client/files/db_service.hcl](./src/ansible02/roles/install_consul_client/files/db_service.hcl) | Регистрация БД в каталоге сервисов | HCL, `service { name = "db", port = 5432, connect { sidecar_service {} } }` |
| [./src/ansible02/roles/install_consul_client/files/consul-envoy-holel.service](./src/ansible02/roles/install_consul_client/files/consul-envoy-holel.service) | systemd-сервис прокси микросервиса отелей | `ExecStart=/usr/bin/consul connect envoy -sidecar-for=hotel-service` |
| [./src/ansible02/roles/install_consul_client/files/consul-envoy-db.service](./src/ansible02/roles/install_consul_client/files/consul-envoy-db.service) | systemd-сервис прокси БД | `ExecStart=/usr/bin/consul connect envoy -sidecar-for=db` |
| [./src/ansible02/roles/install_consul_client/tasks/main.yml](./src/ansible02/roles/install_consul_client/tasks/main.yml) | Развёртывание клиентов и Envoy | `apt`, `copy`, `get_url` (Envoy v1.38.4 binary), `systemd` (`consul`, `consul-envoy`) |
| [./src/ansible02/roles/install_consul_client/handlers/main.yml](./src/ansible02/roles/install_consul_client/handlers/main.yml) | Хэндлер перезапуска клиента | `ansible.builtin.systemd` (перезапуск службы `consul`) |
| [./src/ansible02/roles/install_db/tasks/main.yml](./src/ansible02/roles/install_db/tasks/main.yml) | Настройка PostgreSQL | `apt` (`python3-psycopg2`, `acl`), `community.postgresql.postgresql_db/user` |
| [./src/ansible02/roles/install_hotels_service/files/hotels.service](./src/ansible02/roles/install_hotels_service/files/hotels.service) | systemd-юнит запуска Java-приложения | `After/Requires=consul-envoy.service`, `EnvironmentFile=/etc/environment`, `java -jar` |
| [./src/ansible02/roles/install_hotels_service/tasks/main.yml](./src/ansible02/roles/install_hotels_service/tasks/main.yml) | Сборка и деплой Spring Boot-сервиса | `apt` (JDK 21, Maven), `copy`, `lineinfile`, `command` (mvnw package), `systemd` |

---

## Инструкция по сборке, тестированию и запуску

### 1. Требования к хост-системе
Для запуска стендов на хосте должны быть установлены:
- **HashiCorp Vagrant** (версия `>= 2.3.0`);
- **Oracle VirtualBox** (версия `>= 7.0`);
- **Git**, **curl**, **jq**, **OpenSSH Client**;
- **Docker Engine** (для запуска автотестов Newman).

Склонируйте репозиторий и перейдите в каталог проекта:
```bash
git clone <URL_РЕПОЗИТОРИЯ>
cd DO8_AutomationTools_ID_1220167-1-develop/src
```

---

### 2. Развёртывание и тестирование стенда Part 1 (Ansible Automation)

#### Шаг 2.1. Инициализация и запуск виртуальных машин
Проверьте, что в `Vagrantfile` активна конфигурация Part 1 (`manager`, `node01`, `node02`), и запустите стенд:
```bash
vagrant up
vagrant status
```
Все три ноды должны быть в статусе `running`.

#### Шаг 2.2. Подготовка ноды manager
Подключитесь к управляющей ноде по SSH:
```bash
vagrant ssh manager
```
Проверьте сетевую связность:
```bash
ping -c 3 192.168.56.11
ping -c 3 192.168.56.12
```
Сгенерируйте SSH-ключи без пароля и скопируйте публичный ключ на управляемые ноды (пароль пользователя `vagrant` по умолчанию: `vagrant`):
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id vagrant@192.168.56.11
ssh-copy-id vagrant@192.168.56.12
```
Проверьте беспарольный вход:
```bash
ssh vagrant@192.168.56.11 "hostname"
ssh vagrant@192.168.56.12 "hostname"
```

#### Шаг 2.3. Установка Ansible и проверка инвентаря
Установите Ansible на `manager`:
```bash
sudo apt update && sudo apt install -y python3-pip python3-venv tar
pip install ansible --break-system-packages
ansible --version
```
Запакуйте исходники сервисов в архив для быстрой передачи (выполняется из общей папки `/vagrant`):
```bash
tar -czf /vagrant/services.tar.gz -C /vagrant services
```
Перейдите в `ansible01` и выполните пинг-тест инвентаря:
```bash
cd /vagrant/ansible01
ansible nodes -i inventory.ini -m ansible.builtin.ping
```
Ожидаемый ответ: статус `SUCCESS` и `"ping": "pong"` для `node01` и `node02`.

#### Шаг 2.4. Запуск плейбука с ролями
Проверьте синтаксис и запустите плейбук:
```bash
ansible-playbook -i inventory.ini playbook.yml --syntax-check
ansible-playbook -i inventory.ini playbook.yml
```
После выполнения плейбука проверьте состояние компонентов:
- **На `node01`:**
  ```bash
  ssh vagrant@192.168.56.11 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
  ```
  Все 9 контейнеров (`nginx-proxy`, `session-service`, `gateway-service`, `booking-service`, `hotel-service`, `payment-service`, `loyalty-service`, `report-service`, `postgres`, `rabbitmq`) должны быть в статусе `Up`.
- **На `node02`:**
  ```bash
  curl -sI http://192.168.56.12 | head -n 1
  # Ожидается: HTTP/1.1 200 OK
  
  ssh vagrant@192.168.56.12 "sudo -u postgres psql -d testbd -c 'SELECT * FROM Person;'"
  # Ожидается вывод 3 записей: Ivan, Petya, Masha
  ```

#### Шаг 2.5. Сквозное тестирование микросервисов через Postman / Newman
С хоста запустите Newman в Docker для проверки API через проброшенные порты:
```bash
docker run --rm \
  -v "$(pwd)":/etc/newman \
  --network host \
  postman/newman run /etc/newman/application_tests.postman_collection.json \
  --env-var API_HOST=127.0.0.1
```
Все 5 сценариев (авторизация пользователя, получение каталога отелей, просмотр конкретного отеля, бронирование номера, просмотр баланса программы лояльности) должны пройти со статусом `failed: 0`.

---

### 3. Развёртывание и тестирование стенда Part 2 (Consul Service Discovery)

#### Шаг 3.1. Пересоздание окружения
Чтобы очистить ресурсы Part 1 и создать новую топологию, удалите старые машины на хосте:
```bash
vagrant destroy -f
```
Проверьте, что в `Vagrantfile` активна четырёхузловая конфигурация (`consulServer`, `api`, `manager`, `db`), и запустите стенд:
```bash
vagrant up
vagrant status
```
Проверьте проброшенные порты через `ss`:
```bash
ss -tulpn | grep -E '8500|8082'
```
Порты `8500` (Consul Web UI) и `8082` (Hotels API) должны быть в `LISTEN`.

#### Шаг 3.2. Настройка SSH-ключей на ноде manager
Подключитесь к `manager`:
```bash
vagrant ssh manager
```
Сгенерируйте ключи и скопируйте на все узлы кластера:
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id vagrant@192.168.56.10
ssh-copy-id vagrant@192.168.56.11
ssh-copy-id vagrant@192.168.56.13
```
Проверьте связность через Ansible:
```bash
cd /vagrant/ansible02
ansible all -i inventory.ini -m ping
```

#### Шаг 3.3. Развёртывание кластера Consul, Service Mesh и сервисов
Запустите плейбук:
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Плейбук по очереди выполнит:
1. Установку и запуск сервера Consul на `consulServer` (`192.168.56.10`);
2. Установку агентов Consul Client и бинарника Envoy v1.38.4 на нодах `api` (`192.168.56.11`) и `db` (`192.168.56.13`);
3. Создание базы данных `hotels_db` и пользователя в PostgreSQL на `db`;
4. Сборку jar-пакета, экспорт переменных подключения к loopback `127.0.0.1:5432` и запуск сервиса `hotels.service` на `api`.

#### Шаг 3.4. Проверка состояния кластера Consul и каталога сервисов
Подключитесь к `consulServer`:
```bash
vagrant ssh consulServer
```
Проверьте список участников кластера:
```bash
consul members
```
Ожидаемый вывод:
```text
Node          Address            Status  Type    Build   Protocol  DC   Partition  Segment
consulServer  192.168.56.10:8301  alive   server  2.0.x   2         dc1  default    <all>
api           192.168.56.11:8301  alive   client  2.0.x   2         dc1  default    <all>
db            192.168.56.13:8301  alive   client  2.0.x   2         dc1  default    <all>
```
Проверьте зарегистрированные сервисы:
```bash
consul catalog services
```
В каталоге должны быть: `consul`, `db`, `db-sidecar-proxy`, `hotel-service`, `hotel-service-sidecar-proxy`.

#### Шаг 3.5. Проверка Consul Web UI, HTTP API и DNS
- **Consul Web UI:** откройте в браузере на хосте `http://localhost:8500` (или `http://192.168.56.10:8500`). Во вкладке **Nodes** — 3 активных узла (узел `consulServer` помечен флагом `Leader`), во вкладке **Services** — зарегистрированные сервисы с зелёными индикаторами проверок здоровья.
- **HTTP Catalog API:** запросите реестр сервисов с хоста:
  ```bash
  curl -s http://localhost:8500/v1/catalog/service/db | jq .
  curl -s http://localhost:8500/v1/catalog/service/hotel-service | jq .
  ```
- **DNS-интерфейс Consul:** резолвните DNS через порт `8600` на `consulServer`:
  ```bash
  dig @127.0.0.1 -p 8600 hotel-service.service.consul +short
  # Возвращает: 192.168.56.11
  
  dig @127.0.0.1 -p 8600 db.service.consul +short
  # Возвращает: 192.168.56.13
  ```

---

### 4. Тестирование CRUD-операций сервиса отелей (REST API)

Тестирование проходит с хоста через проброшенный порт `8082`.

#### Шаг 4.1. Авторизация и получение токена доступа
Выполните запрос с Basic Auth (`User:qwerty` в Base64):
```bash
TOKEN=$(curl -s -i -X GET http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic VXNlcjpxd2VydHk=" | grep -i "Authorization:" | awk '{print $2}' | tr -d '\r')
echo "Получен JWT токен: $TOKEN"
```

#### Шаг 4.2. Чтение списка отелей (Read)
Выполните GET-запрос к списку отелей:
```bash
curl -s -X GET http://localhost:8082/api/v1/hotels \
  -H "Authorization: $TOKEN" | jq .
```
Сервер вернёт `200 OK` и список предустановленных отелей. Это подтверждает, что Spring Boot-сервис подключается к PostgreSQL через локальный sidecar Envoy на порту `5432`.

#### Шаг 4.3. Создание нового отеля (Create)
Отправьте POST-запрос с JSON-телом нового отеля:
```bash
curl -s -i -X POST http://localhost:8082/api/v1/hotels \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "DevOps Grand Hotel",
    "location": {
      "country": "Россия",
      "city": "Москва",
      "address": "ул. Архитекторов, д. 42"
    }
  }'
```
Сервер вернёт `201 Created` и заголовок `Location` со ссылкой на созданный ресурс.

#### Шаг 4.4. Проверка обновлённого каталога
Повторите запрос списка отелей:
```bash
curl -s -X GET http://localhost:8082/api/v1/hotels \
  -H "Authorization: $TOKEN" | jq .
```
В ответе появится созданный `DevOps Grand Hotel`.

---

### 5. Эксперимент: проверка динамического Service Discovery при миграции IP базы данных (Chaos / Resilience Testing)

Цель эксперимента — показать, что в архитектуре Service Mesh клиентский микросервис не зависит от физической топологии сети, а миграция зависимостей проходит бесшовно, без простоя.

#### Шаг 5.1. Фиксация исходного состояния
С хоста проверьте текущий IP-адрес сервиса `db` в каталоге:
```bash
curl -s http://localhost:8500/v1/catalog/service/db | jq '.[0].ServiceAddress'
# Возвращает: "192.168.56.13"
```

#### Шаг 5.2. Смена сетевого адреса на ноде db
Подключитесь к `db` по SSH, смените статический IP на интерфейсе `eth1` с `192.168.56.13` на `192.168.56.99` и перезапустите агентов:
```bash
vagrant ssh db
```
Внутри терминала `db`:
```bash
# Очищаем старый адрес и назначаем новый IP на eth1
sudo ip addr flush dev eth1
sudo ip addr add 192.168.56.99/24 dev eth1
sudo ip link set eth1 up

# Перезапускаем агент Consul и sidecar-прокси Envoy
sudo systemctl restart consul consul-envoy
exit
```

#### Шаг 5.3. Проверка автоматического обновления в Consul
С хоста опросите каталог Consul:
```bash
curl -s http://localhost:8500/v1/catalog/service/db | jq '.[0].ServiceAddress'
# Возвращает: "192.168.56.99"
```
Gossip-протокол Serf зафиксировал новый адрес узла, Consul обновил каталог, а агент на `api` через xDS gRPC-канал мгновенно передал новый IP в Envoy.

#### Шаг 5.4. Проверка доступности API без перезапуска клиентского микросервиса
С хоста отправьте запрос на чтение списка отелей:
```bash
curl -s -X GET http://localhost:8082/api/v1/hotels \
  -H "Authorization: $TOKEN" | jq .
```
Запрос вернёт `200 OK` и полный список записей из БД. Процесс Java на `api` не перезапускался, переменные окружения не менялись, соединение не прерывалось. Эксперимент подтверждает отказоустойчивость и независимость сервисов в архитектуре Service Mesh.

---

### 6. Остановка и очистка окружения

После завершения работы освободите ресурсы хоста:
- Остановка виртуальных машин с сохранением состояния:
  ```bash
  vagrant halt
  ```
- Полное удаление виртуальных машин и дисков VirtualBox:
  ```bash
  vagrant destroy -f
  ```
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

# Этап сборки

FROM eclipse-temurin:21-jdk-alpine AS app_builder

WORKDIR /app_build

COPY .mvn .mvn
COPY mvnw mvnw
COPY pom.xml pom.xml

RUN chmod +x ./mvnw

RUN ./mvnw dependency:go-offline

COPY ./src /app_build/src

RUN ./mvnw package -DskipTests 

# Этап запуска

FROM eclipse-temurin:21-jre-alpine AS app_runner

WORKDIR /app

RUN apk add --no-cache bash

COPY --from=app_builder /app_build/target/*.jar /app/app.jar
COPY ./wait-for-it.sh /app/

RUN chmod +x /app/wait-for-it.sh

ENTRYPOINT ["sh", "-c", "./wait-for-it.sh $SESSION_SERVICE_HOST:$SESSION_SERVICE_PORT -- java -jar app.jar"]
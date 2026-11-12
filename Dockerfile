# Imagen única con el servidor y la web (app web, panel del ayuntamiento y tablón del bar).

# 1) Web en Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS web
WORKDIR /app
COPY app/pubspec.* ./
RUN flutter pub get
COPY app/ ./
RUN flutter build web --release --no-web-resources-cdn

# 2) Servidor Spring Boot
FROM maven:3.9-eclipse-temurin-21 AS api
WORKDIR /backend
COPY backend/pom.xml ./
RUN mvn -q dependency:go-offline
COPY backend/src ./src
COPY --from=web /app/build/web ./src/main/resources/static
RUN mvn -q package -DskipTests

# 3) Ejecución
FROM eclipse-temurin:21-jre
WORKDIR /claxon
COPY --from=api /backend/target/claxon-backend-*.jar claxon.jar
ENV TZ=Europe/Madrid
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "claxon.jar"]

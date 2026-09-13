# Build Stage
FROM eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /workspace/app

# Cache dependencies
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn
COPY src src

# Package application (skipping tests in Docker build, tested in CI/CD)
RUN chmod +x mvnw && ./mvnw clean package -DskipTests || mvn clean package -DskipTests

# Runtime Stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Run as non-root user for security hardening
RUN groupadd -r propzen && useradd -r -g propzen propzen

COPY --from=builder /workspace/app/target/*.jar app.jar
RUN chown -R propzen:propzen /app

USER propzen

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/api/v1/health || exit 1

ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]

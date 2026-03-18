# =============================================================
# GWANG MEU — Dockerfile multi-stage
# Build : docker build -t gwangmeu-backend .
# Run   : docker run -p 8080:8080 --env-file .env gwangmeu-backend
# =============================================================

# -------- Stage 1 : Build --------
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Copier d'abord pom.xml seul pour profiter du cache des dependances Maven
COPY pom.xml .
COPY .mvn/ .mvn/
RUN --mount=type=cache,id=gwangmeu-m2,target=/root/.m2 \
    mvn dependency:go-offline -B 2>/dev/null || true

# Copier les sources et compiler
COPY src/ src/
RUN --mount=type=cache,id=gwangmeu-m2,target=/root/.m2 \
    mvn clean package -DskipTests -B && \
    mv target/*.jar target/app.jar

# -------- Stage 2 : Runtime --------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Securite : utilisateur non-root
RUN addgroup -S gwangmeu && adduser -S gwangmeu -G gwangmeu
WORKDIR /app
USER gwangmeu

COPY --from=builder --chown=gwangmeu:gwangmeu /build/target/app.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]

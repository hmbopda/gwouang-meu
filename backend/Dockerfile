# =============================================================
# GWANG MEU — Dockerfile multi-stage
# Build : docker build -t gwangmeu-backend .
# Run   : docker run -p 8080:8080 --env-file .env gwangmeu-backend
#
# SECRETS : aucun secret n'est copié dans l'image.
# FIREBASE_SERVICE_ACCOUNT_JSON, mots de passe DB, clés API, etc.
# sont fournis à l'exécution via les variables d'environnement
# (Railway > Service > Variables). Voir docs/DEPLOIEMENT.md.
# =============================================================

# -------- Stage 1 : Build --------
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

# Copier pom.xml en premier pour mettre en cache la couche des dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -B -q || true

# Copier les sources et compiler
COPY src/ src/

# Défense en profondeur : ne jamais embarquer une clé de service locale
# dans le jar (le fichier est aussi exclu du contexte par .dockerignore).
RUN rm -f src/main/resources/firebase/serviceAccountKey.json && \
    mvn clean package -DskipTests -B && \
    mv target/*.jar target/app.jar

# -------- Stage 2 : Runtime --------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Lien GHCR <-> repo GitHub (héritage des permissions du repo privé)
LABEL org.opencontainers.image.source="https://github.com/hmbopda/gwouang-meu" \
      org.opencontainers.image.title="gwangmeu-backend" \
      org.opencontainers.image.description="Backend Spring Boot 3 / Java 21 — GWANG MEU"

# Sécurité : utilisateur non-root
RUN addgroup -S gwangmeu && adduser -S gwangmeu -G gwangmeu
WORKDIR /app
USER gwangmeu

COPY --from=builder --chown=gwangmeu:gwangmeu /build/target/app.jar app.jar

# Railway injecte PORT ; application.yml écoute sur ${PORT:8080}
EXPOSE 8080

# Le healthcheck suit le port réellement écouté (PORT injecté par la plateforme)
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=5 \
    CMD wget -qO- "http://localhost:${PORT:-8080}/actuator/health" || exit 1

# `sh -c` obligatoire : en forme exec pure, ${SPRING_PROFILES_ACTIVE:-prod}
# ne serait PAS expansé par un shell et arriverait littéralement à la JVM
# (profil Spring invalide). `exec` préserve la propagation des signaux (SIGTERM).
ENTRYPOINT ["sh", "-c", "exec java \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:-prod} \
    -Djava.security.egd=file:/dev/./urandom \
    -jar app.jar"]

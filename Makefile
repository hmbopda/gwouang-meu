# =============================================================
# GWANG MEU — Makefile
# =============================================================

.PHONY: dev stop logs run build test swagger health reset-db

# Lance tous les services Docker en arriere-plan
dev:
	docker-compose -f docker-compose.dev.yml up -d
	@echo "Services demarres. Attente readiness PostgreSQL..."
	@sleep 3
	@echo "Pret ! Lancer 'make run' dans un autre terminal."

# Stoppe les services Docker
stop:
	docker-compose -f docker-compose.dev.yml down

# Affiche les logs en temps reel
logs:
	docker-compose -f docker-compose.dev.yml logs -f

# Lance le backend Spring Boot en mode dev
run:
	cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Compile le backend sans les tests
build:
	cd backend && mvn clean package -DskipTests

# Lance tous les tests (Testcontainers)
test:
	cd backend && mvn verify

# Ouvre Swagger UI dans le navigateur
swagger:
	@echo "Swagger UI : http://localhost:8080/swagger-ui.html"
	@if command -v xdg-open &> /dev/null; then \
		xdg-open http://localhost:8080/swagger-ui.html; \
	elif command -v open &> /dev/null; then \
		open http://localhost:8080/swagger-ui.html; \
	else \
		echo "Ouvre manuellement : http://localhost:8080/swagger-ui.html"; \
	fi

# Verifie la sante du backend
health:
	curl -s http://localhost:8080/actuator/health | python3 -m json.tool

# Remet a zero la base de donnees
reset-db:
	docker-compose -f docker-compose.dev.yml down -v
	$(MAKE) dev

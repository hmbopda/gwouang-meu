package com.gwangmeu.shared.config;

import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityManagerFactory;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.neo4j.driver.Driver;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.neo4j.core.DatabaseSelectionProvider;
import org.springframework.data.neo4j.core.transaction.Neo4jTransactionManager;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class Neo4jConfig {

    private final Driver driver;

    @Primary
    @Bean("transactionManager")
    public PlatformTransactionManager transactionManager(EntityManagerFactory emf) {
        return new JpaTransactionManager(emf);
    }

    @Bean("neo4jTransactionManager")
    public Neo4jTransactionManager neo4jTransactionManager(
            Driver driver,
            DatabaseSelectionProvider databaseSelectionProvider) {
        return new Neo4jTransactionManager(driver, databaseSelectionProvider);
    }

    @PostConstruct
    public void createNeo4jConstraints() {
        try (var session = driver.session()) {
            session.run("""
                CREATE CONSTRAINT person_postgres_id_unique IF NOT EXISTS
                FOR (p:Person) REQUIRE p.postgresId IS UNIQUE
            """);
            log.info("Neo4j constraint person_postgres_id_unique ensured");
        } catch (Exception e) {
            log.warn("Could not create Neo4j constraints (may already exist): {}", e.getMessage());
        }
    }
}

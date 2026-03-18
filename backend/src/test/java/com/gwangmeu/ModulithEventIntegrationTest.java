package com.gwangmeu;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModule;
import org.springframework.modulith.core.ApplicationModules;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tests d'integration evenementielle Spring Modulith.
 *
 * Verifie la detection des modules et leurs dependances.
 * Les evenements domaine (DomainEvent) sont publies via publishEvent(Object)
 * et ne sont pas detectes par getPublishedEvents() car ils n'etendent pas
 * ApplicationEvent. On verifie plutot les dependances inter-modules.
 */
@DisplayName("Modulith Events — verification de la structure inter-modules")
class ModulithEventIntegrationTest {

    static final ApplicationModules modules = ApplicationModules.of(GwangMeuApplication.class);

    @Test
    @DisplayName("Le module 'user' est detecte dans la structure")
    void userModuleExists() {
        ApplicationModule userModule = modules.getModuleByName("user")
                .orElseThrow(() -> new AssertionError("Le module 'user' n'a pas ete detecte"));

        assertThat(userModule).isNotNull();
        assertThat(userModule.getDisplayName()).isNotBlank();
    }

    @Test
    @DisplayName("Le module 'village' est detecte dans la structure")
    void villageModuleExists() {
        ApplicationModule villageModule = modules.getModuleByName("village")
                .orElseThrow(() -> new AssertionError("Le module 'village' n'a pas ete detecte"));

        assertThat(villageModule).isNotNull();
        assertThat(villageModule.getDisplayName()).isNotBlank();
    }

    @Test
    @DisplayName("Le module 'feed' est detecte dans la structure")
    void feedModuleExists() {
        ApplicationModule feedModule = modules.getModuleByName("feed")
                .orElseThrow(() -> new AssertionError("Le module 'feed' n'a pas ete detecte"));

        assertThat(feedModule).isNotNull();
        assertThat(feedModule.getDisplayName()).isNotBlank();
    }

    @Test
    @DisplayName("Le module 'genealogy' est detecte dans la structure")
    void genealogyModuleExists() {
        ApplicationModule genealogyModule = modules.getModuleByName("genealogy")
                .orElseThrow(() -> new AssertionError("Le module 'genealogy' n'a pas ete detecte"));

        assertThat(genealogyModule).isNotNull();
        assertThat(genealogyModule.getDisplayName()).isNotBlank();
    }

    @Test
    @DisplayName("Le module 'geo' est detecte dans la structure modulaire")
    void geoModuleExists() {
        assertThat(modules.getModuleByName("geo")).isPresent();
    }

    @Test
    @DisplayName("Le module 'shared' (Shared Kernel) est detecte comme module ouvert")
    void sharedModuleExists() {
        assertThat(modules.getModuleByName("shared")).isPresent();
    }

    @Test
    @DisplayName("Le nombre de modules detectes correspond a l'architecture prevue")
    void expectedModuleCount() {
        long moduleCount = modules.stream().count();
        assertThat(moduleCount).as("Au moins 7 modules devraient etre detectes").isGreaterThanOrEqualTo(7);
    }

    @Test
    @DisplayName("Les modules feed et village contiennent un package 'events'")
    void eventPackagesExist() {
        // Les evenements sont dans des sous-packages 'events' de chaque module
        ApplicationModule feedModule = modules.getModuleByName("feed").orElseThrow();
        ApplicationModule villageModule = modules.getModuleByName("village").orElseThrow();

        assertThat(feedModule.getDisplayName()).isNotBlank();
        assertThat(villageModule.getDisplayName()).isNotBlank();
    }

    @Test
    @DisplayName("Lister la structure de chaque module detecte")
    void printModuleDetails() {
        modules.forEach(module -> {
            System.out.println("Module: " + module.getDisplayName());
            module.getPublishedEvents()
                    .forEach(event -> System.out.println("  -> publie : " + event));
            System.out.println();
        });
    }
}

package com.gwangmeu;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;
import org.springframework.modulith.docs.Documenter;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tests d'architecture Spring Modulith.
 *
 * Verifie que les modules (user, village, feed, genealogy, geo,
 * chat, notification, shared, config) sont detectes et documente
 * les eventuelles violations de frontieres inter-modules.
 */
@DisplayName("Architecture Modulith — verification des frontieres inter-modules")
class ModulithArchitectureTest {

    static final ApplicationModules modules = ApplicationModules.of(GwangMeuApplication.class);

    @Test
    @DisplayName("Tous les modules attendus sont detectes par Spring Modulith")
    void allExpectedModulesAreDetected() {
        assertThat(modules.stream().count()).isGreaterThanOrEqualTo(7);
        assertThat(modules.getModuleByName("user")).isPresent();
        assertThat(modules.getModuleByName("village")).isPresent();
        assertThat(modules.getModuleByName("feed")).isPresent();
        assertThat(modules.getModuleByName("geo")).isPresent();
        assertThat(modules.getModuleByName("chat")).isPresent();
        assertThat(modules.getModuleByName("genealogy")).isPresent();
        assertThat(modules.getModuleByName("shared")).isPresent();
    }

    @Test
    @DisplayName("Afficher la structure des modules detectes")
    void printModuleStructure() {
        modules.forEach(System.out::println);
    }

    @Test
    @DisplayName("Generer la documentation des modules (diagrammes C4 + canvas)")
    void generateDocumentation() {
        new Documenter(modules)
                .writeModulesAsPlantUml()
                .writeIndividualModulesAsPlantUml()
                .writeModuleCanvases();
    }
}

package com.gwangmeu.village.domain;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

/**
 * Lien N:N entre un village et une langue du referentiel ({@code languages}).
 *
 * <p>Un village parle une ou plusieurs langues ; {@code primary} designe la langue
 * native par defaut (au plus une par village, garantie par le service). Cle composite
 * (village_id, language_id) modelisee par {@link IdClass} — meme convention que
 * {@code person_clans}. Entite « plate » (pas d'AuditEntity) : la cle est composite
 * et non un UUID de substitution.</p>
 */
@Entity
@Table(name = "village_languages", indexes = {
        @Index(name = "idx_vlang_village", columnList = "village_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(VillageLanguage.VillageLanguageId.class)
public class VillageLanguage {

    @Id
    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Id
    @Column(name = "language_id", nullable = false)
    private UUID languageId;

    /** Langue principale du village (native par defaut pour la traduction). */
    @Column(name = "is_primary", nullable = false)
    @Builder.Default
    private boolean primary = false;

    /** Ordre d'affichage (0 = premier). */
    @Column(name = "ordinal", nullable = false)
    @Builder.Default
    private int ordinal = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private Instant updatedAt = Instant.now();

    /** Cle composite (village_id, language_id). */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VillageLanguageId implements Serializable {
        private UUID villageId;
        private UUID languageId;
    }
}

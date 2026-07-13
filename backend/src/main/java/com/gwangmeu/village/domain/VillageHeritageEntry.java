package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Entree patrimoniale generique d'un village : tradition, lieu sacre ou repere du
 * calendrier traditionnel. Le type est porte par {@link HeritageKind}.
 *
 * <p>Donnee patrimoniale editee par le chef, un delegue {@link VillagePermission#EDIT_VILLAGE}
 * ou le super-admin. {@code title}/{@code subtitle} pour l'entete, {@code description} pour le
 * recit court et {@code detail} pour le contenu long facultatif.</p>
 */
@Entity
@Table(name = "village_heritage_entries", indexes = {
        @Index(name = "idx_heritage_entries_village_kind", columnList = "village_id, kind")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageHeritageEntry extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    /** Rubrique de l'entree (tradition, lieu sacre, calendrier). */
    @Enumerated(EnumType.STRING)
    @Column(name = "kind", nullable = false)
    private HeritageKind kind;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "subtitle")
    private String subtitle;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String detail;

    /** Ordre d'affichage dans la rubrique (0 = premier). */
    @Column(name = "ordinal")
    @Builder.Default
    private int ordinal = 0;
}

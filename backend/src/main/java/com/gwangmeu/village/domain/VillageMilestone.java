package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Temps fort (jalon historique) d'un village : fondation, migration, intronisation,
 * evenement marquant.
 *
 * <p>Donnee patrimoniale editee par le chef, un delegue {@link VillagePermission#EDIT_VILLAGE}
 * ou le super-admin. La date peut etre une annee ({@code year}) et/ou un libelle libre
 * ({@code dateLabel}, ex. « XVIIIe siecle », « vers 1850 »).</p>
 */
@Entity
@Table(name = "village_milestones", indexes = {
        @Index(name = "idx_vmilestone_village", columnList = "village_id, ordinal")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageMilestone extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    /** Annee de l'evenement (facultative). */
    @Column(name = "event_year")
    private Integer year;

    /** Libelle de date libre lorsque l'annee exacte est inconnue (facultatif). */
    @Column(name = "date_label")
    private String dateLabel;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    /** Ordre d'affichage dans la frise (0 = premier). */
    @Column(name = "ordinal")
    @Builder.Default
    private int ordinal = 0;
}

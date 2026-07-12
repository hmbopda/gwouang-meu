package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Chef d'un village dans la dynastie : chef actuel ({@code current = true}) ou ancien chef.
 *
 * <p>Donnee patrimoniale saisie par le super-admin, le chef (createur) ou un delegue
 * portant {@link VillagePermission#EDIT_VILLAGE}. Un enregistrement n'est pas forcement
 * un compte utilisateur ({@code userId} facultatif) : les chefs historiques sont saisis
 * au nom libre, avec dates de regne facultatives.</p>
 */
@Entity
@Table(name = "village_chiefs", indexes = {
        @Index(name = "idx_vchief_village", columnList = "village_id, ordinal")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageChief extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Column(name = "display_name", nullable = false)
    private String displayName;

    /** Annee de debut de regne (facultative). */
    @Column(name = "reign_start")
    private Integer reignStart;

    /** Annee de fin de regne ; {@code null} = en fonction ou inconnue. */
    @Column(name = "reign_end")
    private Integer reignEnd;

    /** Chef actuellement en fonction (au plus un par village). */
    @Column(name = "is_current")
    @Builder.Default
    private boolean current = false;

    /** Ordre d'affichage dans la dynastie (0 = premier). */
    @Column(name = "ordinal")
    @Builder.Default
    private int ordinal = 0;

    /** Recit / note de regne (facultatif). */
    @Column(name = "note", columnDefinition = "TEXT")
    private String note;

    @Column(name = "avatar_url")
    private String avatarUrl;

    /** Lien facultatif vers un compte utilisateur (chef actuel membre de la plateforme). */
    @Column(name = "user_id")
    private UUID userId;
}

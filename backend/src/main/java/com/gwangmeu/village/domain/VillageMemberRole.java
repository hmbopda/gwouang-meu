package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Role delegue attribue a un membre au sein d'un village (« Notable », « Moderateur »...).
 * Les permissions sont stockees en CSV dans la colonne {@code permissions}.
 * Un seul role par (village, utilisateur) : contrainte unique.
 */
@Entity
@Table(name = "village_member_roles",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_vmr_village_user", columnNames = {"village_id", "user_id"}),
        indexes = @Index(name = "idx_vmr_village_id", columnList = "village_id"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageMemberRole extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** Libelle lisible du role : « Notable », « Moderateur »... */
    @Column(nullable = false, length = 80)
    private String title;

    /** Permissions serialisees en CSV (ex. « VALIDATE_MEMBERS,MODERATE_POSTS »). */
    @Column(nullable = false, length = 300)
    private String permissions;

    @Column(name = "granted_by", nullable = false)
    private UUID grantedBy;

    /** Typage optionnel du rôle délégué vers un titre de gouvernance (V61). */
    @Column(name = "title_id")
    private UUID titleId;

    /** Deserialise le CSV {@code permissions} en un ensemble type. */
    @Transient
    public Set<VillagePermission> getPermissionSet() {
        if (permissions == null || permissions.isBlank()) {
            return EnumSet.noneOf(VillagePermission.class);
        }
        return Arrays.stream(permissions.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(VillagePermission::valueOf)
                .collect(Collectors.toCollection(() -> EnumSet.noneOf(VillagePermission.class)));
    }

    /** Serialise un ensemble de permissions en CSV dans {@code permissions}. */
    @Transient
    public void setPermissionSet(Set<VillagePermission> perms) {
        if (perms == null || perms.isEmpty()) {
            this.permissions = "";
            return;
        }
        this.permissions = perms.stream()
                .map(Enum::name)
                .collect(Collectors.joining(","));
    }
}

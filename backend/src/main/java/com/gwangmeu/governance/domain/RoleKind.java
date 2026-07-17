package com.gwangmeu.governance.domain;

import jakarta.persistence.*;
import lombok.*;

/**
 * Vocabulaire extensible des FONCTIONS de gouvernance (HEAD, NOTABLE, QUEEN_MOTHER,
 * REGULATORY, COUNCIL_ELDER…). Ajouter une fonction = un INSERT, jamais du code.
 * Le Java branche sur les flags de comportement, pas sur des noms de culture.
 */
@Entity
@Table(name = "role_kinds")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoleKind {

    @Id
    @Column(length = 40)
    private String code;

    @Column(name = "is_executive", nullable = false)
    private boolean executive;

    @Column(name = "is_ceremonial", nullable = false)
    private boolean ceremonial;

    @Column(name = "is_apex_capable", nullable = false)
    private boolean apexCapable;

    @Column(name = "is_regulatory", nullable = false)
    private boolean regulatory;
}

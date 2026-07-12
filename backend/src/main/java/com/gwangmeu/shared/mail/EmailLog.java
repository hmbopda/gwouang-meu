package com.gwangmeu.shared.mail;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Trace d'un email transactionnel envoye (audit + observabilite du moteur email).
 * Ecrit en best-effort par {@link EmailService} apres chaque tentative d'envoi.
 */
@Entity
@Table(name = "email_logs", indexes = {
        @Index(name = "idx_email_logs_recipient", columnList = "recipient"),
        @Index(name = "idx_email_logs_created", columnList = "created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailLog extends AuditEntity {

    @Column(nullable = false)
    private String recipient;

    /** Type fonctionnel : INVITATION, WELCOME, VILLAGE_INVITATION, DISSOLUTION, UNION, CHILD_ASSOCIATION. */
    @Column(name = "email_type", nullable = false)
    private String emailType;

    @Column
    private String subject;

    /** Provider ayant traite l'envoi (smtp | resend-api). */
    @Column
    private String provider;

    @Column
    @Builder.Default
    private boolean success = false;

    @Column(columnDefinition = "TEXT")
    private String error;
}

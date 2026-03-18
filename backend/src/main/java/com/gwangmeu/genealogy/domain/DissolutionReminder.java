package com.gwangmeu.genealogy.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "dissolution_reminders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DissolutionReminder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "union_id", nullable = false)
    private UUID unionId;

    @Column(name = "reminder_type", nullable = false, length = 20)
    private String reminderType; // INITIAL_EMAIL, SMS_REMINDER, AUTO_VALIDATE, MANUAL_REVIEW

    @Column(nullable = false, length = 20)
    private String channel; // EMAIL, SMS, IN_APP, SYSTEM

    @Column(name = "sent_at", nullable = false)
    @Builder.Default
    private Instant sentAt = Instant.now();

    @Column(columnDefinition = "TEXT")
    private String notes;
}

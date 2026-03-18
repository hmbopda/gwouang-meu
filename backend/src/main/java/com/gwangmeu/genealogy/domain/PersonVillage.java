package com.gwangmeu.genealogy.domain;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "person_villages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(PersonVillage.PersonVillageId.class)
public class PersonVillage {

    @Id
    @Column(name = "person_id", nullable = false)
    private UUID personId;

    @Id
    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonVillageId implements Serializable {
        private UUID personId;
        private UUID villageId;
    }
}
